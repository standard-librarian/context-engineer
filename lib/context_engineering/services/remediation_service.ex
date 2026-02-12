defmodule ContextEngineering.Services.RemediationService do
  @moduledoc """
  Auto-remediation service that finds similar resolved incidents for given errors.
  Uses semantic search with pgvector to find matching resolved failures.
  """

  import Ecto.Query

  alias ContextEngineering.Repo
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Services.EmbeddingService
  alias ContextEngineering.Repo

  @pattern_actions %{
    "database_error" => [
      "Check database connection settings",
      "Verify database is running and accessible",
      "Check for connection pool exhaustion",
      "Review recent schema migrations"
    ],
    "connection_error" => [
      "Check connection pool settings",
      "Verify network connectivity",
      "Check firewall rules and security groups",
      "Review timeout configurations"
    ],
    "resource_exhaustion" => [
      "Check memory usage and limits",
      "Review resource quotas",
      "Scale up resources if needed",
      "Check for memory leaks"
    ],
    "authentication_error" => [
      "Verify credentials are correct",
      "Check token expiration",
      "Review permission settings",
      "Verify authentication service is running"
    ],
    "not_found" => [
      "Verify the resource exists",
      "Check for typos in identifiers",
      "Review routing configuration",
      "Check if resource was deleted"
    ],
    "server_error" => [
      "Check application logs for details",
      "Review recent deployments",
      "Check upstream service health",
      "Verify configuration settings"
    ],
    "runtime_panic" => [
      "Review stack trace for nil pointer access",
      "Check for unsafe type assertions",
      "Add defensive nil checks",
      "Review error handling patterns"
    ],
    "performance" => [
      "Check for N+1 queries",
      "Review database indexes",
      "Check for resource bottlenecks",
      "Consider caching strategies"
    ],
    "unknown" => [
      "Review full error message and context",
      "Check recent changes to the system",
      "Consult documentation",
      "Escalate to on-call engineer"
    ]
  }

  @doc """
  Find similar resolved incidents for a given error.

  ## Parameters
    * `params` - Map with:
      * `"error_message"` - Required error message
      * `"stack_trace"` - Optional stack trace
      * `"pattern"` - Optional pattern override
      * `"app_name"` - Optional application name
      * `"top_k"` - Number of results (default: 5)

  ## Returns
    Map with pattern, severity, similar incidents, and suggested actions.
  """
  def remediate(params) do
    error_message = Map.get(params, "error_message") || Map.get(params, "message", "")
    stack_trace = Map.get(params, "stack_trace", "")
    pattern_override = Map.get(params, "pattern")
    top_k = Map.get(params, "top_k", 5)

    classification_params = %{
      "title" => error_message,
      "stack_trace" => stack_trace
    }

    pattern = pattern_override || classify_error_pattern(classification_params)
    severity = classify_severity_from_pattern(pattern)

    context_text = build_context_text(error_message, stack_trace)

    case EmbeddingService.generate_embedding(context_text) do
      {:ok, embedding} ->
        similar_incidents = search_resolved_failures(embedding, pattern, top_k)
        suggested_actions = get_suggested_actions(pattern)

        {:ok,
         %{
           pattern: pattern,
           severity: severity,
           similar_incidents: similar_incidents,
           suggested_actions: suggested_actions
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_context_text(error_message, stack_trace) do
    [error_message, stack_trace]
    |> Enum.reject(&(&1 == "" or is_nil(&1)))
    |> Enum.join(" ")
  end

  defp classify_error_pattern(params) do
    text = "#{params["stack_trace"]} #{params["title"]}"

    cond do
      String.contains?(text, ["connection", "timeout", "ECONNREFUSED", "dial tcp"]) ->
        "connection_error"

      String.contains?(text, ["memory", "OOM", "OutOfMemory", "out of memory"]) ->
        "resource_exhaustion"

      String.contains?(text, ["database", "SQL", "query", "pgx", "gorm"]) ->
        "database_error"

      String.contains?(text, ["401", "403", "Unauthorized", "Forbidden"]) ->
        "authentication_error"

      String.contains?(text, ["404", "NotFound", "not found"]) ->
        "not_found"

      String.contains?(text, ["500", "502", "503", "Internal Server Error"]) ->
        "server_error"

      String.contains?(text, ["panic", "runtime error", "nil pointer"]) ->
        "runtime_panic"

      true ->
        "unknown"
    end
  end

  defp classify_severity_from_pattern(pattern) do
    case pattern do
      "resource_exhaustion" -> "critical"
      "runtime_panic" -> "critical"
      "database_error" -> "high"
      "connection_error" -> "high"
      "server_error" -> "high"
      "authentication_error" -> "medium"
      "not_found" -> "low"
      "performance" -> "medium"
      _ -> "medium"
    end
  end

  defp search_resolved_failures(embedding, pattern, limit) do
    pgvector_embedding = Pgvector.new(embedding)

    query =
      from(f in Failure,
        where: f.status == "resolved" and not is_nil(f.embedding),
        order_by: fragment("embedding <=> ?", ^pgvector_embedding),
        limit: ^limit,
        select: %{
          id: f.id,
          title: f.title,
          root_cause: f.root_cause,
          resolution: f.resolution,
          prevention: f.prevention,
          similarity: fragment("1 - (embedding <=> ?)", ^pgvector_embedding),
          incident_date: f.incident_date
        }
      )

    query =
      if pattern != "unknown" do
        from(f in query, where: f.pattern == ^pattern)
      else
        query
      end

    Repo.all(query)
    |> Enum.map(fn incident ->
      %{
        id: incident.id,
        title: incident.title,
        root_cause: incident.root_cause,
        resolution: incident.resolution,
        prevention: incident.prevention || [],
        similarity: Float.round(incident.similarity, 2),
        incident_date: Date.to_iso8601(incident.incident_date)
      }
    end)
  end

  defp get_suggested_actions(pattern) do
    Map.get(@pattern_actions, pattern, Map.get(@pattern_actions, "unknown"))
  end
end

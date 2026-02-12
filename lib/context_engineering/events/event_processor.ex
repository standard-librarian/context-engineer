defmodule ContextEngineering.Events.EventProcessor do
  @moduledoc """
  Processes events from external applications written in any language.
  Converts error/deploy/metric events into Knowledge records (failures, snapshots).
  """

  alias ContextEngineering.Knowledge

  # --- Error Events ---

  @doc """
  Process an error event from any application.

  Expects:
    - "title" (required) — error message or summary
    - "app_name" — source application name
    - "stack_trace" — full stack trace string
    - "severity" — "low" | "medium" | "high" | "critical"
    - "timestamp" — ISO 8601 datetime
    - "environment" — e.g. "production", "staging"
    - "metadata" — arbitrary map of extra context
  """
  def process_error_event(params) do
    id = Knowledge.next_id("failure")

    failure_params = %{
      "id" => id,
      "title" => build_error_title(params),
      "incident_date" => parse_date(params["timestamp"]),
      "severity" => params["severity"] || classify_severity(params),
      "root_cause" => extract_root_cause(params),
      "symptoms" => params["stack_trace"] || params["message"] || params["title"],
      "impact" => build_impact(params),
      "status" => "investigating",
      "pattern" => classify_error_pattern(params),
      "tags" => build_error_tags(params),
      "author" => "system"
    }

    Knowledge.create_failure(failure_params)
  end

  # --- Deploy Events ---

  @doc """
  Process a deployment event from any application.

  Expects:
    - "app_name" (required) — deployed application
    - "version" — version string
    - "commit_hash" — git commit hash
    - "deployer" — who deployed
    - "environment" — target environment
    - "changes" — list of change descriptions
  """
  def process_deploy_event(params) do
    message =
      case params["changes"] do
        changes when is_list(changes) and changes != [] ->
          "Deploy #{params["app_name"]} #{params["version"]}: #{Enum.join(changes, "; ")}"

        _ ->
          "Deploy #{params["app_name"]} #{params["version"]}"
      end

    snapshot_params = %{
      "commit_hash" => params["commit_hash"] || "deploy-#{System.unique_integer([:positive])}",
      "author" => params["deployer"] || "system",
      "message" => message,
      "date" => parse_date(params["timestamp"])
    }

    Knowledge.create_snapshot(snapshot_params)
  end

  # --- Metric Events ---

  @doc """
  Process a performance metric event.
  Only creates a failure if the value exceeds the threshold.

  Expects:
    - "metric_name" (required) — e.g. "api_latency_p99"
    - "value" (required) — current metric value
    - "threshold" (required) — the threshold being violated
    - "app_name" — source application
    - "severity" — override severity
  """
  def process_metric_event(params) do
    value = params["value"]
    threshold = params["threshold"]

    cond do
      is_nil(value) or is_nil(threshold) ->
        {:error, "value and threshold are required"}

      value > threshold ->
        id = Knowledge.next_id("failure")

        failure_params = %{
          "id" => id,
          "title" => "Performance threshold exceeded: #{params["metric_name"]}",
          "incident_date" => parse_date(params["timestamp"]),
          "severity" => params["severity"] || "medium",
          "root_cause" => "Metric #{params["metric_name"]} = #{value} (threshold: #{threshold})",
          "symptoms" => "#{params["metric_name"]} at #{value}, threshold is #{threshold}",
          "impact" => build_impact(params),
          "status" => "investigating",
          "pattern" => "performance",
          "tags" => ["performance", "auto-captured"] ++ list_if(params["app_name"]) ++ list_if(params["metric_name"]),
          "author" => "system"
        }

        Knowledge.create_failure(failure_params)

      true ->
        {:ok, :below_threshold}
    end
  end

  # --- Helpers ---

  defp build_error_title(params) do
    app = params["app_name"]
    title = params["title"] || "Unknown error"

    if app, do: "#{title} in #{app}", else: title
  end

  defp extract_root_cause(params) do
    cond do
      params["root_cause"] ->
        params["root_cause"]

      params["stack_trace"] ->
        extract_error_line(params["stack_trace"])

      params["message"] ->
        params["message"]

      true ->
        params["title"] || "Unknown — needs investigation"
    end
  end

  defp extract_error_line(stack) when is_binary(stack) do
    stack
    |> String.split("\n")
    |> Enum.find(fn line ->
      String.contains?(line, "Error") or
        String.contains?(line, "Exception") or
        String.contains?(line, "panic")
    end)
    |> case do
      nil -> String.slice(stack, 0..200)
      line -> String.trim(line)
    end
  end

  defp classify_error_pattern(params) do
    text = "#{params["stack_trace"]} #{params["message"]} #{params["title"]}"

    cond do
      String.contains?(text, ["database", "SQL", "query", "pgx", "gorm"]) ->
        "database_error"

      String.contains?(text, ["connection", "timeout", "ECONNREFUSED", "dial tcp"]) ->
        "connection_error"

      String.contains?(text, ["memory", "OOM", "OutOfMemory", "out of memory"]) ->
        "resource_exhaustion"

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

  defp classify_severity(params) do
    case classify_error_pattern(params) do
      "resource_exhaustion" -> "critical"
      "runtime_panic" -> "critical"
      "database_error" -> "high"
      "connection_error" -> "high"
      "server_error" -> "high"
      "authentication_error" -> "medium"
      "not_found" -> "low"
      _ -> "medium"
    end
  end

  defp build_impact(params) do
    app = params["app_name"]
    env = params["environment"]

    case {app, env} do
      {nil, nil} -> "Impact unknown"
      {app, nil} -> "Affected application: #{app}"
      {nil, env} -> "Environment: #{env}"
      {app, env} -> "#{app} in #{env}"
    end
  end

  defp build_error_tags(params) do
    base = ["auto-captured"]

    base
    |> list_append(params["app_name"])
    |> list_append(params["environment"])
    |> list_append(classify_error_pattern(params))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp list_append(list, nil), do: list
  defp list_append(list, val), do: list ++ [val]

  defp list_if(nil), do: []
  defp list_if(val), do: [val]

  defp parse_date(nil), do: Date.to_iso8601(Date.utc_today())

  defp parse_date(timestamp) when is_binary(timestamp) do
    # Try ISO 8601 datetime first, then plain date
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> Date.to_iso8601(DateTime.to_date(dt))
      _ ->
        case Date.from_iso8601(timestamp) do
          {:ok, _} -> timestamp
          _ -> Date.to_iso8601(Date.utc_today())
        end
    end
  end

  defp parse_date(_), do: Date.to_iso8601(Date.utc_today())
end

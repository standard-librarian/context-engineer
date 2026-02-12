defmodule ContextEngineering.Services.BundlerService do
  @moduledoc """
  Bundles relevant context for AI agents with ranking and token limiting.
  Orchestrates: semantic search -> graph expansion -> ranking -> token-limited bundling.
  """

  alias ContextEngineering.Repo
  alias ContextEngineering.Services.SearchService
  alias ContextEngineering.Contexts.Relationships.Graph
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Contexts.Meetings.Meeting
  alias ContextEngineering.Contexts.Snapshots.Snapshot

  @doc """
  Main bundler function - returns curated context for agents.
  """
  def bundle_context(query, opts \\ []) do
    max_tokens = Keyword.get(opts, :max_tokens, 4000)
    domains = Keyword.get(opts, :domains, [])

    query_id = Ecto.UUID.generate()

    {:ok, semantic_results} = SearchService.semantic_search(query, top_k: 20)

    graph_results = expand_with_graph(semantic_results)

    filtered = maybe_filter_domains(graph_results, domains)

    ranked = rank_items(filtered)

    bundle = build_token_limited_bundle(ranked, max_tokens)

    bundle_with_query_id = Map.put(bundle, :query_id, query_id)

    {:ok, bundle_with_query_id}
  end

  defp expand_with_graph(items) do
    # Collect IDs already present from semantic search
    existing_ids = MapSet.new(items, & &1.id)

    items
    |> Enum.flat_map(fn item ->
      related = Graph.find_related(item.id, item.type, depth: 1)

      graph_items =
        related
        |> Enum.reject(fn rel -> MapSet.member?(existing_ids, rel.id) end)
        |> Enum.map(fn rel -> hydrate_item(rel.id, rel.type) end)
        |> Enum.reject(&is_nil/1)

      [item | graph_items]
    end)
    |> Enum.uniq_by(& &1.id)
  end

  defp hydrate_item(id, "adr") do
    case Repo.get(ADR, id) do
      nil ->
        nil

      adr ->
        %{
          id: adr.id,
          type: "adr",
          title: adr.title,
          content: adr.decision,
          tags: adr.tags,
          created_date: adr.created_date,
          similarity: 0.5
        }
    end
  end

  defp hydrate_item(id, "failure") do
    case Repo.get(Failure, id) do
      nil ->
        nil

      f ->
        %{
          id: f.id,
          type: "failure",
          title: f.title,
          content: f.root_cause,
          tags: f.tags,
          created_date: f.incident_date,
          similarity: 0.5
        }
    end
  end

  defp hydrate_item(id, "meeting") do
    case Repo.get(Meeting, id) do
      nil ->
        nil

      m ->
        %{
          id: m.id,
          type: "meeting",
          title: m.meeting_title,
          content: Jason.encode!(m.decisions),
          tags: m.tags,
          created_date: m.date,
          similarity: 0.5
        }
    end
  end

  defp hydrate_item(id, "snapshot") do
    case Repo.get(Snapshot, id) do
      nil ->
        nil

      s ->
        %{
          id: s.id,
          type: "snapshot",
          title: s.message,
          content: s.message,
          tags: s.tags,
          created_date: s.date,
          similarity: 0.5
        }
    end
  end

  defp hydrate_item(_id, _type), do: nil

  defp maybe_filter_domains(items, []), do: items

  defp maybe_filter_domains(items, domains) do
    Enum.filter(items, fn item ->
      Enum.any?(item.tags || [], &(&1 in domains))
    end)
  end

  defp rank_items(items) do
    now = Date.utc_today()

    items
    |> Enum.map(fn item ->
      recency_score = calculate_recency_score(item[:created_date], now)
      relevance_score = item[:similarity] || 0.5
      importance_score = calculate_importance_score(item)

      composite_score =
        0.3 * recency_score +
          0.5 * relevance_score +
          0.2 * importance_score

      Map.put(item, :score, composite_score)
    end)
    |> Enum.sort_by(& &1.score, :desc)
  end

  defp calculate_recency_score(nil, _now), do: 0.5

  defp calculate_recency_score(item_date, now) do
    days_old = Date.diff(now, item_date)

    cond do
      days_old <= 30 -> 1.0
      days_old <= 90 -> 0.8
      days_old <= 180 -> 0.6
      days_old <= 365 -> 0.4
      true -> 0.2
    end
  end

  defp calculate_importance_score(item) do
    base =
      case item.type do
        "adr" -> 0.9
        "failure" -> 0.8
        "meeting" -> 0.6
        "snapshot" -> 0.5
        _ -> 0.5
      end

    if "critical" in (item[:tags] || []) || "high-priority" in (item[:tags] || []) do
      min(base + 0.1, 1.0)
    else
      base
    end
  end

  defp build_token_limited_bundle(ranked_items, max_tokens) do
    chars_per_token = 4
    max_chars = max_tokens * chars_per_token

    {key_decisions, remaining} = take_items_by_type(ranked_items, "adr", max_chars * 0.4)
    {known_issues, remaining} = take_items_by_type(remaining, "failure", max_chars * 0.3)
    {meetings, remaining} = take_items_by_type(remaining, "meeting", max_chars * 0.2)
    {snapshots, _} = take_items_by_type(remaining, "snapshot", max_chars * 0.2)
    recent_changes = meetings ++ snapshots

    %{
      key_decisions: key_decisions,
      known_issues: known_issues,
      recent_changes: recent_changes,
      total_items: length(key_decisions) + length(known_issues) + length(recent_changes)
    }
  end

  defp take_items_by_type(items, type, max_chars) do
    {matching, rest} = Enum.split_with(items, &(&1.type == type))

    {taken, _remaining_chars} =
      Enum.reduce_while(matching, {[], max_chars}, fn item, {acc, remaining_chars} ->
        item_size = String.length(item[:content] || "")

        if item_size <= remaining_chars do
          {:cont, {[item | acc], remaining_chars - item_size}}
        else
          {:halt, {acc, remaining_chars}}
        end
      end)

    {Enum.reverse(taken), rest}
  end
end

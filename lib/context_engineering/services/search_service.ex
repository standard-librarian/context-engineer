defmodule ContextEngineering.Services.SearchService do
  @moduledoc """
  Semantic search using pgvector cosine similarity.
  """

  import Ecto.Query
  alias ContextEngineering.Repo
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Contexts.Meetings.Meeting
  alias ContextEngineering.Contexts.Snapshots.Snapshot
  alias ContextEngineering.Services.EmbeddingService

  @doc """
  Search across all content types using semantic similarity.
  """
  def semantic_search(query_text, opts \\ []) do
    top_k = Keyword.get(opts, :top_k, 20)
    types = Keyword.get(opts, :types, [:adr, :failure, :meeting, :snapshot])

    {:ok, query_embedding} = EmbeddingService.generate_embedding(query_text)

    results =
      types
      |> Enum.flat_map(fn type -> search_by_type(type, query_embedding, top_k) end)
      |> Enum.sort_by(& &1.similarity, :desc)
      |> Enum.take(top_k)

    {:ok, results}
  end

  defp search_by_type(:adr, query_embedding, limit) do
    embedding = Pgvector.new(query_embedding)

    from(a in ADR,
      where: a.status != "archived" and not is_nil(a.embedding),
      order_by: fragment("embedding <=> ?", ^embedding),
      limit: ^limit,
      select: %{
        id: a.id,
        type: "adr",
        title: a.title,
        content: a.decision,
        tags: a.tags,
        created_date: a.created_date,
        similarity: fragment("1 - (embedding <=> ?)", ^embedding)
      }
    )
    |> Repo.all()
  end

  defp search_by_type(:failure, query_embedding, limit) do
    embedding = Pgvector.new(query_embedding)

    from(f in Failure,
      where: f.status != "archived" and not is_nil(f.embedding),
      order_by: fragment("embedding <=> ?", ^embedding),
      limit: ^limit,
      select: %{
        id: f.id,
        type: "failure",
        title: f.title,
        content: f.root_cause,
        tags: f.tags,
        created_date: f.incident_date,
        similarity: fragment("1 - (embedding <=> ?)", ^embedding)
      }
    )
    |> Repo.all()
  end

  defp search_by_type(:meeting, query_embedding, limit) do
    embedding = Pgvector.new(query_embedding)

    from(m in Meeting,
      where: m.status == "active" and not is_nil(m.embedding),
      order_by: fragment("embedding <=> ?", ^embedding),
      limit: ^limit,
      select: %{
        id: m.id,
        type: "meeting",
        title: m.meeting_title,
        content: fragment("?::text", m.decisions),
        tags: m.tags,
        created_date: m.date,
        similarity: fragment("1 - (embedding <=> ?)", ^embedding)
      }
    )
    |> Repo.all()
  end

  defp search_by_type(:snapshot, query_embedding, limit) do
    embedding = Pgvector.new(query_embedding)

    from(s in Snapshot,
      where: s.status != "archived" and not is_nil(s.embedding),
      order_by: fragment("embedding <=> ?", ^embedding),
      limit: ^limit,
      select: %{
        id: s.id,
        type: "snapshot",
        title: s.message,
        content: s.message,
        tags: s.tags,
        created_date: s.date,
        similarity: fragment("1 - (embedding <=> ?)", ^embedding)
      }
    )
    |> Repo.all()
  end

  @doc """
  Search with tag, date, type, and result limit filters.

  ## Parameters
    * `query_text` - The search query string
    * `filters` - Map with atom keys:
      * `:tags` - List of tag strings to filter by (default: [])
      * `:date_from` - Start date (Date struct or nil)
      * `:date_to` - End date (Date struct or nil)
      * `:types` - List of atoms [:adr, :failure, :meeting, :snapshot] (default: all types)
      * `:top_k` - Maximum number of results to return (default: 20)

  ## Examples

      # Search with tag filter
      SearchService.filtered_search("database", %{tags: ["performance"]})

      # Search with date range
      SearchService.filtered_search("database", %{
        date_from: ~D[2024-01-01],
        date_to: ~D[2024-12-31]
      })

      # Search specific types with limit
      SearchService.filtered_search("architecture", %{
        types: [:adr, :failure],
        top_k: 10
      })

  ## Returns
    List of result maps with keys: id, type, title, content, tags, created_date, similarity
  """
  def filtered_search(query_text, filters \\ %{}) do
    tags = Map.get(filters, :tags, [])
    date_from = Map.get(filters, :date_from)
    date_to = Map.get(filters, :date_to)
    types = Map.get(filters, :types, [:adr, :failure, :meeting, :snapshot])
    top_k = Map.get(filters, :top_k, 20)

    {:ok, results} = semantic_search(query_text, types: types, top_k: top_k)

    results
    |> maybe_filter_by_tags(tags)
    |> maybe_filter_by_date(date_from, date_to)
  end

  defp maybe_filter_by_tags(results, []), do: results

  defp maybe_filter_by_tags(results, tags) do
    Enum.filter(results, fn result ->
      Enum.any?(result.tags, &(&1 in tags))
    end)
  end

  defp maybe_filter_by_date(results, nil, nil), do: results

  defp maybe_filter_by_date(results, date_from, date_to) do
    Enum.filter(results, fn result ->
      date = result.created_date

      (is_nil(date_from) || Date.compare(date, date_from) in [:gt, :eq]) &&
        (is_nil(date_to) || Date.compare(date, date_to) in [:lt, :eq])
    end)
  end
end

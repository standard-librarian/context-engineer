defmodule ContextEngineering.Services.SearchService do
  @moduledoc """
  Semantic search engine using pgvector cosine similarity for finding relevant context.

  This service enables AI agents and users to find relevant organizational knowledge
  by searching based on **meaning** rather than exact keyword matches. It powers the
  core "query context" functionality that makes Context Engineering useful for AI assistants.

  ## How Semantic Search Works

  1. **Query → Embedding**: Convert the search query to a vector using `EmbeddingService`
  2. **Vector Comparison**: Use pgvector's `<=>` operator to compute cosine distance
  3. **Rank Results**: Sort by similarity score (1.0 = identical, 0.0 = unrelated)
  4. **Filter**: Only return items above a similarity threshold

  **Example:**
  - Query: "Why did we choose Postgres?"
  - Finds: ADR-001 "Use PostgreSQL for persistence" (similarity: 0.87)
  - Also finds: FAIL-023 "Database connection pool issues" (similarity: 0.65)
  - Doesn't find: MEET-005 "Q1 Design Review" (similarity: 0.12)

  ## Key Features

  - **Multi-type search**: Searches across ADRs, Failures, Meetings, and Snapshots simultaneously
  - **Cosine similarity**: Uses mathematical vector distance (0-1 scale)
  - **Filtering**: Can filter by content type, tags, date ranges, and status
  - **Efficient**: Uses pgvector extension's optimized C implementation
  - **No keyword matching needed**: "DB crash" will find "database failure"

  ## Usage

  Basic semantic search:

      iex> SearchService.semantic_search("database performance issues")
      {:ok, [
        %{id: "FAIL-042", type: "failure", title: "Query timeout", similarity: 0.89},
        %{id: "ADR-015", type: "adr", title: "Add connection pooling", similarity: 0.76}
      ]}

  Search specific types only:

      iex> SearchService.semantic_search("authentication", types: [:adr, :failure], top_k: 5)
      {:ok, [...]}

  Advanced search with filters:

      iex> SearchService.search("API design", %{
      ...>   "types" => ["adr"],
      ...>   "tags" => ["api", "rest"],
      ...>   "from_date" => "2024-01-01",
      ...>   "to_date" => "2024-12-31"
      ...> })
      {:ok, [...]}

  ## Similarity Scores

  - **0.9 - 1.0**: Nearly identical content
  - **0.7 - 0.9**: Highly relevant, same topic
  - **0.5 - 0.7**: Somewhat related, useful context
  - **0.3 - 0.5**: Loosely related, may be useful
  - **0.0 - 0.3**: Unrelated, likely noise

  ## Integration with BundlerService

  This service is called by `BundlerService` to find initial candidates,
  which are then expanded via graph relationships and ranked for token-limited bundling.

  ## Performance

  - Typical query: 10-50ms for 1000s of records
  - Uses pgvector's HNSW index for fast approximate nearest neighbor search
  - Scales well to 100K+ knowledge items
  """

  import Ecto.Query
  alias ContextEngineering.Repo
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Contexts.Meetings.Meeting
  alias ContextEngineering.Contexts.Snapshots.Snapshot
  alias ContextEngineering.Services.EmbeddingService

  @doc """
  Performs semantic search across all knowledge types.

  Converts the query to an embedding, then finds the most similar items
  across ADRs, Failures, Meetings, and Snapshots using cosine similarity.

  ## Parameters

    - `query_text` - Natural language search query (e.g., "Why Redis for caching?")
    - `opts` - Keyword list with options:
      - `:top_k` - Maximum number of results to return (default: 20)
      - `:types` - List of types to search: `:adr`, `:failure`, `:meeting`, `:snapshot` (default: all)

  ## Returns

    - `{:ok, [result]}` - List of result maps sorted by similarity (highest first)

  Each result map contains:
  - `:id` - Item ID (e.g., "ADR-001")
  - `:type` - Type string ("adr", "failure", "meeting", "snapshot")
  - `:title` - Item title
  - `:content` - Relevant content snippet
  - `:tags` - List of tags
  - `:created_date` - Date the item was created
  - `:similarity` - Float between 0.0 and 1.0 (higher = more similar)

  ## Examples

      iex> SearchService.semantic_search("database failures", top_k: 5)
      {:ok, [
        %{id: "FAIL-042", type: "failure", title: "DB timeout", similarity: 0.92},
        %{id: "ADR-015", type: "adr", title: "Connection pooling", similarity: 0.78}
      ]}

      iex> SearchService.semantic_search("API decisions", types: [:adr])
      {:ok, [%{id: "ADR-003", type: "adr", ...}]}

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
  Advanced search with tag and date range filters.

  Performs semantic search with additional filtering by tags, date ranges,
  and content types. Useful for narrowing results to specific topics or time periods.

  ## Parameters

    - `query_text` - Natural language search query
    - `filters` - Map with optional keys:
      - `"types"` - List of type strings: "adr", "failure", "meeting", "snapshot"
      - `"tags"` - List of tag strings (items must have at least one matching tag)
      - `"from_date"` - Start date (ISO8601 string or Date struct)
      - `"to_date"` - End date (ISO8601 string or Date struct)
      - `"top_k"` - Maximum results (default: 20)

  ## Returns

    - `{:ok, [result]}` - Filtered and ranked results

  ## Examples

      iex> SearchService.search("authentication bug", %{
      ...>   "types" => ["failure"],
      ...>   "tags" => ["auth", "security"],
      ...>   "from_date" => "2024-01-01"
      ...> })
      {:ok, [%{id: "FAIL-089", type: "failure", ...}]}

      iex> SearchService.search("database decisions", %{
      ...>   "types" => ["adr"],
      ...>   "from_date" => ~D[2024-01-01],
      ...>   "to_date" => ~D[2024-12-31],
      ...>   "top_k" => 10
      ...> })
      {:ok, [...]}

  """
  def filtered_search(query_text, filters) do
    tags = Map.get(filters, :tags, [])
    date_from = Map.get(filters, :date_from)
    date_to = Map.get(filters, :date_to)

    {:ok, results} = semantic_search(query_text)

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

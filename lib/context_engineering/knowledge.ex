defmodule ContextEngineering.Knowledge do
  @moduledoc """
  The main context for managing organizational knowledge and context records.

  This module provides the public API for creating, updating, and querying all types
  of organizational knowledge including:

  - **ADRs** (Architecture Decision Records): Why technical decisions were made
  - **Failures**: What went wrong and how it was resolved
  - **Meetings**: What was discussed and decided in meetings
  - **Snapshots**: Point-in-time captures of the codebase state

  ## Key Features

  - **Automatic embedding generation**: All text content is converted to vector embeddings
    using local ML models (via `EmbeddingService`) for semantic search

  - **Automatic relationship linking**: Cross-references between items (like "see ADR-001")
    are automatically detected and stored as graph relationships

  - **Tag extraction**: Keywords are automatically extracted from content and stored as tags

  - **Sequential IDs**: Each type gets unique sequential identifiers (ADR-001, FAIL-042, etc.)

  ## Usage

  Create an ADR:

      iex> params = %{
      ...>   "title" => "Use PostgreSQL for persistence",
      ...>   "decision" => "We will use PostgreSQL as our primary database",
      ...>   "context" => "We need ACID guarantees and relational data",
      ...>   "status" => "accepted"
      ...> }
      iex> {:ok, adr} = Knowledge.create_adr(params)

  Query across all knowledge types:

      iex> Knowledge.list_all_items(limit: 10)
      [%{type: "adr", item: %ADR{...}}, %{type: "failure", item: %Failure{...}}]

  Get the next available ID:

      iex> Knowledge.next_id("adr")
      "ADR-005"

  ## Architecture

  This module serves as a **facade** over the individual context modules:
  - `ContextEngineering.Contexts.ADRs.ADR`
  - `ContextEngineering.Contexts.Failures.Failure`
  - `ContextEngineering.Contexts.Meetings.Meeting`
  - `ContextEngineering.Contexts.Snapshots.Snapshot`

  It coordinates with supporting services:
  - `EmbeddingService` - generates ML embeddings for semantic search
  - `Graph` - manages relationships between knowledge items

  This design allows:
  - Controllers and API endpoints to use a single, consistent interface
  - Mix tasks (CLI commands) to reuse the same business logic
  - Background workers to access knowledge without HTTP overhead
  """

  import Ecto.Query

  alias ContextEngineering.Repo
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Contexts.Meetings.Meeting
  alias ContextEngineering.Contexts.Snapshots.Snapshot
  alias ContextEngineering.Contexts.Feedbacks.Feedback
  alias ContextEngineering.Services.EmbeddingService
  alias ContextEngineering.Contexts.Relationships.Graph

  # --- ADR ---

  @doc """
  Creates a new Architecture Decision Record (ADR).

  Automatically:
  - Generates vector embeddings for semantic search
  - Extracts and assigns tags from the content
  - Creates graph relationships to referenced items (e.g., "see ADR-001")

  ## Parameters

    - `params` - Map with the following keys:
      - `"title"` (required) - Short title of the decision
      - `"decision"` (required) - The decision that was made
      - `"context"` (required) - Background and reasoning
      - `"consequences"` - Expected outcomes (optional)
      - `"status"` - One of "proposed", "accepted", "deprecated", "superseded" (default: "proposed")
      - `"tags"` - List of tag strings (optional, auto-extracted if not provided)
      - `"created_date"` - Date string (optional, defaults to today)

  ## Returns

    - `{:ok, %ADR{}}` on success
    - `{:error, %Ecto.Changeset{}}` on validation failure

  ## Examples

      iex> params = %{
      ...>   "title" => "Use PostgreSQL for persistence",
      ...>   "decision" => "We will use PostgreSQL as our primary database",
      ...>   "context" => "We need ACID guarantees and relational data modeling"
      ...> }
      iex> {:ok, adr} = Knowledge.create_adr(params)
      iex> adr.id
      "ADR-001"

  """
  def create_adr(params) do
    params = maybe_add_tags(params)

    text_for_embedding =
      "#{params["title"]} #{params["decision"]} #{params["context"]}"

    {:ok, embedding} = EmbeddingService.generate_embedding(text_for_embedding)

    changeset =
      %ADR{}
      |> ADR.changeset(params)
      |> ADR.with_embedding(embedding)

    case Repo.insert(changeset) do
      {:ok, adr} ->
        Graph.auto_link_item(adr.id, "adr", text_for_embedding)
        {:ok, adr}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates an existing ADR.

  ## Parameters

    - `id` - The ADR ID (e.g., "ADR-001")
    - `params` - Map of fields to update (same keys as `create_adr/1`)

  ## Returns

    - `{:ok, %ADR{}}` on success
    - `{:error, :not_found}` if ADR doesn't exist
    - `{:error, %Ecto.Changeset{}}` on validation failure

  ## Examples

      iex> Knowledge.update_adr("ADR-001", %{"status" => "accepted"})
      {:ok, %ADR{id: "ADR-001", status: "accepted"}}

  """
  def update_adr(id, params) do
    case Repo.get(ADR, id) do
      nil ->
        {:error, :not_found}

      adr ->
        changeset = ADR.changeset(adr, params)

        case Repo.update(changeset) do
          {:ok, updated} -> {:ok, updated}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  Fetches a single ADR by ID.

  ## Parameters

    - `id` - The ADR ID (e.g., "ADR-001")

  ## Returns

    - `{:ok, %ADR{}}` if found
    - `{:error, :not_found}` if not found

  ## Examples

      iex> Knowledge.get_adr("ADR-001")
      {:ok, %ADR{id: "ADR-001", title: "Use PostgreSQL"}}

      iex> Knowledge.get_adr("ADR-999")
      {:error, :not_found}

  """
  def get_adr(id) do
    case Repo.get(ADR, id) do
      nil -> {:error, :not_found}
      adr -> {:ok, adr}
    end
  end

  @doc """
  Lists all ADRs, optionally filtered by status.

  ## Parameters

    - `params` - Map with optional keys:
      - `"status"` - Filter by status: "active", "proposed", "accepted", "deprecated", "superseded" (default: "active")

  ## Returns

    - List of `%ADR{}` structs, ordered by creation date (newest first)

  ## Examples

      iex> Knowledge.list_adrs()
      [%ADR{id: "ADR-003"}, %ADR{id: "ADR-002"}, %ADR{id: "ADR-001"}]

      iex> Knowledge.list_adrs(%{"status" => "accepted"})
      [%ADR{status: "accepted", ...}]

  """
  def list_adrs(params \\ %{}) do
    status = Map.get(params, "status", "active")

    from(a in ADR, where: a.status == ^status, order_by: [desc: a.created_date])
    |> Repo.all()
  end

  # --- Failure ---

  @doc """
  Creates a new Failure record (incident/outage/bug report).

  Automatically:
  - Generates vector embeddings for semantic search
  - Extracts and assigns tags from the content
  - Creates graph relationships to referenced items

  ## Parameters

    - `params` - Map with the following keys:
      - `"title"` (required) - Short description of the failure
      - `"symptoms"` (required) - What users experienced
      - `"root_cause"` (required) - Why it happened
      - `"resolution"` (required) - How it was fixed
      - `"severity"` - One of "low", "medium", "high", "critical" (default: "medium")
      - `"status"` - One of "investigating", "resolved", "monitoring" (default: "investigating")
      - `"tags"` - List of tag strings (optional, auto-extracted if not provided)
      - `"occurred_at"` - DateTime string (optional, defaults to now)

  ## Returns

    - `{:ok, %Failure{}}` on success
    - `{:error, %Ecto.Changeset{}}` on validation failure

  ## Examples

      iex> params = %{
      ...>   "title" => "Database connection pool exhausted",
      ...>   "symptoms" => "API returning 504 timeouts",
      ...>   "root_cause" => "Pool size too small for traffic spike",
      ...>   "resolution" => "Increased pool size from 10 to 50",
      ...>   "severity" => "high"
      ...> }
      iex> {:ok, failure} = Knowledge.create_failure(params)
      iex> failure.id
      "FAIL-001"

  """
  def create_failure(params) do
    params = maybe_add_tags(params)

    text_for_embedding =
      "#{params["title"]} #{params["root_cause"]} #{params["symptoms"]} #{params["resolution"]}"

    {:ok, embedding} = EmbeddingService.generate_embedding(text_for_embedding)

    changeset =
      %Failure{}
      |> Failure.changeset(params)
      |> Failure.with_embedding(embedding)

    case Repo.insert(changeset) do
      {:ok, failure} ->
        Graph.auto_link_item(failure.id, "failure", text_for_embedding)
        {:ok, failure}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates an existing Failure record.

  ## Parameters

    - `id` - The Failure ID (e.g., "FAIL-001")
    - `params` - Map of fields to update (same keys as `create_failure/1`)

  ## Returns

    - `{:ok, %Failure{}}` on success
    - `{:error, :not_found}` if Failure doesn't exist
    - `{:error, %Ecto.Changeset{}}` on validation failure

  ## Examples

      iex> Knowledge.update_failure("FAIL-001", %{"status" => "resolved"})
      {:ok, %Failure{id: "FAIL-001", status: "resolved"}}

  """
  def update_failure(id, params) do
    case Repo.get(Failure, id) do
      nil ->
        {:error, :not_found}

      failure ->
        changeset = Failure.changeset(failure, params)

        case Repo.update(changeset) do
          {:ok, updated} -> {:ok, updated}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  Fetches a single Failure by ID.

  ## Parameters

    - `id` - The Failure ID (e.g., "FAIL-001")

  ## Returns

    - `{:ok, %Failure{}}` if found
    - `{:error, :not_found}` if not found

  ## Examples

      iex> Knowledge.get_failure("FAIL-001")
      {:ok, %Failure{id: "FAIL-001", title: "Database timeout"}}

  """
  def get_failure(id) do
    case Repo.get(Failure, id) do
      nil -> {:error, :not_found}
      failure -> {:ok, failure}
    end
  end

  @doc """
  Lists all Failures, optionally filtered by status.

  ## Parameters

    - `params` - Map with optional keys:
      - `"status"` - Filter by status: "investigating", "resolved", "monitoring" (default: "resolved")

  ## Returns

    - List of `%Failure{}` structs, ordered by incident date (newest first)

  ## Examples

      iex> Knowledge.list_failures()
      [%Failure{id: "FAIL-003"}, %Failure{id: "FAIL-002"}]

      iex> Knowledge.list_failures(%{"status" => "investigating"})
      [%Failure{status: "investigating", ...}]

  """
  def list_failures(params \\ %{}) do
    status = Map.get(params, "status", "resolved")

    from(f in Failure, where: f.status == ^status, order_by: [desc: f.incident_date])
    |> Repo.all()
  end

  # --- Meeting ---

  @doc """
  Creates a new Meeting record.

  Automatically:
  - Generates vector embeddings for semantic search
  - Extracts and assigns tags from the content
  - Stores decisions as structured data (JSON)

  ## Parameters

    - `params` - Map with the following keys:
      - `"meeting_title"` (required) - Title of the meeting
      - `"decisions"` (required) - Map or JSON string of decisions made
      - `"attendees"` - List of attendee names (optional)
      - `"meeting_date"` - Date string (optional, defaults to today)
      - `"tags"` - List of tag strings (optional, auto-extracted if not provided)

  ## Returns

    - `{:ok, %Meeting{}}` on success
    - `{:error, %Ecto.Changeset{}}` on validation failure

  ## Examples

      iex> params = %{
      ...>   "meeting_title" => "Q1 Architecture Review",
      ...>   "decisions" => %{
      ...>     "database" => "Stick with PostgreSQL",
      ...>     "caching" => "Add Redis for sessions"
      ...>   },
      ...>   "attendees" => ["Alice", "Bob", "Charlie"]
      ...> }
      iex> {:ok, meeting} = Knowledge.create_meeting(params)
      iex> meeting.id
      "MEET-001"

  """
  def create_meeting(params) do
    params = maybe_add_tags(params)

    decisions_text =
      case params["decisions"] do
        decisions when is_map(decisions) -> Jason.encode!(decisions)
        decisions when is_binary(decisions) -> decisions
        _ -> ""
      end

    text_for_embedding = "#{params["meeting_title"]} #{decisions_text}"

    {:ok, embedding} = EmbeddingService.generate_embedding(text_for_embedding)

    changeset =
      %Meeting{}
      |> Meeting.changeset(params)
      |> Meeting.with_embedding(embedding)

    case Repo.insert(changeset) do
      {:ok, meeting} -> {:ok, meeting}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Updates an existing Meeting record.

  ## Parameters

    - `id` - The Meeting ID (e.g., "MEET-001")
    - `params` - Map of fields to update (same keys as `create_meeting/1`)

  ## Returns

    - `{:ok, %Meeting{}}` on success
    - `{:error, :not_found}` if Meeting doesn't exist
    - `{:error, %Ecto.Changeset{}}` on validation failure

  """
  def update_meeting(id, params) do
    case Repo.get(Meeting, id) do
      nil ->
        {:error, :not_found}

      meeting ->
        changeset = Meeting.changeset(meeting, params)

        case Repo.update(changeset) do
          {:ok, updated} -> {:ok, updated}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  Fetches a single Meeting by ID.

  ## Parameters

    - `id` - The Meeting ID (e.g., "MEET-001")

  ## Returns

    - `{:ok, %Meeting{}}` if found
    - `{:error, :not_found}` if not found

  """
  def get_meeting(id) do
    case Repo.get(Meeting, id) do
      nil -> {:error, :not_found}
      meeting -> {:ok, meeting}
    end
  end

  @doc """
  Lists all Meetings, ordered by meeting date.

  ## Parameters

    - `params` - Map (reserved for future filtering options)

  ## Returns

    - List of `%Meeting{}` structs, ordered by meeting date (newest first)

  ## Examples

      iex> Knowledge.list_meetings()
      [%Meeting{id: "MEET-003"}, %Meeting{id: "MEET-002"}]

  """
  def list_meetings(params \\ %{}) do
    status = Map.get(params, "status", "active")

    from(m in Meeting, where: m.status == ^status, order_by: [desc: m.date])
    |> Repo.all()
  end

  # --- Next ID ---

  @doc """
  Generates the next sequential ID for a given type.
  E.g. next_id("adr") might return "ADR-004" if ADR-003 exists.
  """
  def next_id(type) do
    {schema, prefix} =
      case String.downcase(type) do
        "adr" -> {ADR, "ADR"}
        "failure" -> {Failure, "FAIL"}
        "meeting" -> {Meeting, "MEET"}
        "snapshot" -> {Snapshot, "SNAP"}
      end

    last_id =
      from(s in schema, select: s.id, order_by: [desc: s.id], limit: 1)
      |> Repo.one()

    next_num =
      case last_id do
        nil ->
          1

        id ->
          case Regex.run(~r/(\d+)$/, id) do
            [_, num_str] -> String.to_integer(num_str) + 1
            _ -> 1
          end
      end

    "#{prefix}-#{String.pad_leading(Integer.to_string(next_num), 3, "0")}"
  end

  # --- Auto Tags ---

  @tag_keywords %{
    "database" =>
      ~w(database db postgresql postgres mysql sql query migration schema table index),
    "performance" => ~w(performance slow latency throughput bottleneck optimization cache load),
    "infrastructure" =>
      ~w(infrastructure deploy deployment server container docker kubernetes k8s aws cloud),
    "security" => ~w(security auth authentication authorization vulnerability xss csrf injection),
    "frontend" => ~w(frontend ui ux component react liveview template css javascript browser),
    "api" => ~w(api endpoint rest graphql http request response json),
    "testing" => ~w(test testing spec unit integration e2e coverage),
    "monitoring" => ~w(monitoring alert logging metric observability tracing),
    "caching" => ~w(cache caching redis memcached ttl invalidation stampede),
    "incident" => ~w(incident outage downtime failure crash error exception)
  }

  @doc """
  Extracts tags from text based on keyword matching.
  Returns a list of tag strings.
  """
  def auto_tags(text) when is_binary(text) do
    lower = String.downcase(text)

    @tag_keywords
    |> Enum.filter(fn {_tag, keywords} ->
      Enum.any?(keywords, fn kw -> String.contains?(lower, kw) end)
    end)
    |> Enum.map(fn {tag, _} -> tag end)
    |> Enum.sort()
  end

  def auto_tags(_), do: []

  # --- Timeline ---

  @doc """
  Returns all knowledge items within a date range, sorted chronologically.

  Useful for generating reports, viewing activity history, or analyzing decision patterns over time.

  ## Parameters

    - `from_date` - Start date (Date struct or parseable date string)
    - `to_date` - End date (Date struct or parseable date string)

  ## Returns

    - List of maps with keys:
      - `:type` - String: "adr", "failure", "meeting", or "snapshot"
      - `:item` - The struct
      - `:date` - The relevant date for this item (created_date, incident_date, meeting_date, or commit_date)

  ## Examples

      iex> Knowledge.timeline(~D[2024-01-01], ~D[2024-01-31])
      [
        %{type: "adr", item: %ADR{}, date: ~D[2024-01-15]},
        %{type: "failure", item: %Failure{}, date: ~D[2024-01-10]}
      ]

  """
  def timeline(from_date, to_date) do
    adrs =
      from(a in ADR,
        where: a.created_date >= ^from_date and a.created_date <= ^to_date,
        order_by: [asc: a.created_date]
      )
      |> Repo.all()
      |> Enum.map(fn a ->
        %{
          id: a.id,
          type: "adr",
          title: a.title,
          date: a.created_date,
          tags: a.tags,
          status: a.status
        }
      end)

    failures =
      from(f in Failure,
        where: f.incident_date >= ^from_date and f.incident_date <= ^to_date,
        order_by: [asc: f.incident_date]
      )
      |> Repo.all()
      |> Enum.map(fn f ->
        %{
          id: f.id,
          type: "failure",
          title: f.title,
          date: f.incident_date,
          tags: f.tags,
          status: f.status
        }
      end)

    meetings =
      from(m in Meeting,
        where: m.date >= ^from_date and m.date <= ^to_date,
        order_by: [asc: m.date]
      )
      |> Repo.all()
      |> Enum.map(fn m ->
        %{
          id: m.id,
          type: "meeting",
          title: m.meeting_title,
          date: m.date,
          tags: m.tags,
          status: m.status
        }
      end)

    snapshots =
      from(s in Snapshot,
        where: s.date >= ^from_date and s.date <= ^to_date,
        order_by: [asc: s.date]
      )
      |> Repo.all()
      |> Enum.map(fn s ->
        %{
          id: s.id,
          type: "snapshot",
          title: s.message,
          date: s.date,
          tags: s.tags,
          status: s.status
        }
      end)

    (adrs ++ failures ++ meetings ++ snapshots)
    |> Enum.sort_by(& &1.date, {:asc, Date})
  end

  # --- Snapshot ---

  @doc """
  Creates a Snapshot record from git commit data.

  Captures the state of the codebase at a specific commit for historical reference.
  Automatically generates embeddings for the commit message.

  ## Parameters

    - `params` - Map with the following keys:
      - `"commit_hash"` (required) - Git commit SHA
      - `"author"` (required) - Commit author name
      - `"message"` (required) - Commit message
      - `"date"` - Commit date (optional, defaults to now)
      - `"branch"` - Git branch name (optional)
      - `"tags"` - List of tag strings (optional)

  ## Returns

    - `{:ok, %Snapshot{}}` on success
    - `{:error, %Ecto.Changeset{}}` on validation failure

  ## Examples

      iex> params = %{
      ...>   "commit_hash" => "a1b2c3d4",
      ...>   "author" => "Alice",
      ...>   "message" => "Add user authentication system",
      ...>   "branch" => "main"
      ...> }
      iex> {:ok, snapshot} = Knowledge.create_snapshot(params)
      iex> snapshot.id
      "SNAP-001"

  """
  def create_snapshot(params) do
    id = next_id("snapshot")
    date = Map.get(params, "date", Date.to_iso8601(Date.utc_today()))

    snapshot_params = %{
      "id" => id,
      "commit_hash" => params["commit_hash"],
      "author" => params["author"],
      "message" => params["message"],
      "date" => date,
      "tags" => ["git-snapshot" | auto_tags(params["message"])],
      "status" => "active"
    }

    text_for_embedding = "#{params["message"]} #{params["commit_hash"]}"
    {:ok, embedding} = EmbeddingService.generate_embedding(text_for_embedding)

    changeset =
      %Snapshot{}
      |> Snapshot.changeset(snapshot_params)
      |> Snapshot.with_embedding(embedding)

    case Repo.insert(changeset) do
      {:ok, snapshot} ->
        Graph.auto_link_item(snapshot.id, "snapshot", text_for_embedding)
        {:ok, snapshot}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def get_snapshot(id) do
    case Repo.get(Snapshot, id) do
      nil -> {:error, :not_found}
      snapshot -> {:ok, snapshot}
    end
  end

  def list_snapshots(params \\ %{}) do
    status = Map.get(params, "status", "active")

    from(s in Snapshot, where: s.status == ^status, order_by: [desc: s.date])
    |> Repo.all()
  end

  def update_snapshot(id, params) do
    case Repo.get(Snapshot, id) do
      nil ->
        {:error, :not_found}

      snapshot ->
        changeset = Snapshot.changeset(snapshot, params)

        case Repo.update(changeset) do
          {:ok, updated} -> {:ok, updated}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  # --- Feedback ---

  def create_feedback(params) do
    changeset = Feedback.changeset(%Feedback{}, params)

    case Repo.insert(changeset) do
      {:ok, feedback} -> {:ok, feedback}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def get_feedback(id) do
    case Repo.get(Feedback, id) do
      nil -> {:error, :not_found}
      feedback -> {:ok, feedback}
    end
  end

  def list_feedback(params \\ %{}) do
    limit = Map.get(params, "limit", 50)
    agent_id = Map.get(params, "agent_id")

    query =
      from(f in Feedback,
        order_by: [desc: f.inserted_at],
        limit: ^limit
      )

    query =
      if agent_id do
        from(f in query, where: f.agent_id == ^agent_id)
      else
        query
      end

    Repo.all(query)
  end

  def feedback_stats(opts \\ []) do
    days_back = Keyword.get(opts, :days_back, 30)

    since =
      Date.add(Date.utc_today(), -days_back) |> DateTime.new!(~T[00:00:00]) |> DateTime.to_naive()

    total =
      from(f in Feedback, where: f.inserted_at >= ^since)
      |> Repo.aggregate(:count, :id)

    avg_rating =
      from(f in Feedback,
        where: f.inserted_at >= ^since and not is_nil(f.overall_rating),
        select: avg(f.overall_rating)
      )
      |> Repo.one()

    most_helpful = most_helpful_items(since)
    common_missing = common_missing_context(since)

    %{
      total_feedback: total,
      avg_rating: avg_rating,
      most_helpful_items: most_helpful,
      common_missing_context: common_missing,
      days_back: days_back
    }
  end

  defp most_helpful_items(since) do
    from(f in Feedback,
      where: f.inserted_at >= ^since,
      select: f.items_helpful
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_id, count} -> count end, :desc)
    |> Enum.take(10)
    |> Enum.map(fn {id, count} -> %{id: id, helpful_count: count} end)
  end

  defp common_missing_context(since) do
    from(f in Feedback,
      where: f.inserted_at >= ^since and not is_nil(f.missing_context),
      select: f.missing_context
    )
    |> Repo.all()
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_text, count} -> count end, :desc)
    |> Enum.take(10)
    |> Enum.map(fn {text, count} -> %{text: text, count: count} end)
  end

  # --- Error Formatting ---

  def format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  # --- Private helpers ---

  @doc false
  defp maybe_add_tags(params) do
    case Map.get(params, "tags") do
      nil ->
        text = extract_text(params)
        tags = auto_tags(text)

        if tags != [] do
          Map.put(params, "tags", tags)
        else
          params
        end

      _existing ->
        params
    end
  end

  defp extract_text(params) do
    [
      params["title"],
      params["decision"],
      params["context"],
      params["root_cause"],
      params["symptoms"],
      params["resolution"],
      params["meeting_title"],
      case params["decisions"] do
        d when is_map(d) -> Jason.encode!(d)
        d when is_binary(d) -> d
        _ -> nil
      end
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end
end

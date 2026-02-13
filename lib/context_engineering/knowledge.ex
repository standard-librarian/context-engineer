defmodule ContextEngineering.Knowledge do
  @moduledoc """
  Shared context module for managing organizational knowledge.
  Extracts business logic from controllers so it can be reused by Mix tasks and other callers.
  """

  import Ecto.Query

  alias ContextEngineering.Repo
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Contexts.Meetings.Meeting
  alias ContextEngineering.Contexts.Snapshots.Snapshot
  alias ContextEngineering.Contexts.Feedbacks.Feedback
  alias ContextEngineering.Contexts.Debates.Debate
  alias ContextEngineering.Contexts.Debates.DebateMessage
  alias ContextEngineering.Contexts.Debates.DebateJudgment
  alias ContextEngineering.Services.EmbeddingService
  alias ContextEngineering.Contexts.Relationships.Graph

  # --- ADR ---

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

  def get_adr(id) do
    case Repo.get(ADR, id) do
      nil -> {:error, :not_found}
      adr -> {:ok, adr}
    end
  end

  @doc """
  Lists ADRs with optional filtering.

  ## Parameters
    * `params` - Optional map with filters:
      * `"status"` - Filter by status (default: "active")

  ## Returns
    List of ADR structs ordered by created_date descending.
  """
  def list_adrs(params \\ %{}) do
    status = Map.get(params, "status", "active")

    from(a in ADR, where: a.status == ^status, order_by: [desc: a.created_date])
    |> Repo.all()
  end

  # --- Failure ---

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

  def get_failure(id) do
    case Repo.get(Failure, id) do
      nil -> {:error, :not_found}
      failure -> {:ok, failure}
    end
  end

  @doc """
  Lists Failures with optional filtering.

  ## Parameters
    * `params` - Optional map with filters:
      * `"status"` - Filter by status (default: "resolved")

  ## Available Fields
    * `"title"` - Failure title
    * `"symptoms"` - Observed symptoms
    * `"root_cause"` - Root cause analysis
    * `"resolution"` - How it was resolved
    * `"severity"` - Severity level
    * `"status"` - Current status
    * `"tags"` - Associated tags
    * `"incident_date"` - Date of incident

  ## Returns
    List of Failure structs ordered by incident_date descending.
  """
  def list_failures(params \\ %{}) do
    status = Map.get(params, "status", "resolved")

    from(f in Failure, where: f.status == ^status, order_by: [desc: f.incident_date])
    |> Repo.all()
  end

  # --- Meeting ---

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

  def get_meeting(id) do
    case Repo.get(Meeting, id) do
      nil -> {:error, :not_found}
      meeting -> {:ok, meeting}
    end
  end

  @doc """
  Lists Meetings with optional filtering.

  ## Parameters
    * `params` - Optional map with filters:
      * `"status"` - Filter by status (default: "active")

  ## Available Fields
    * `"meeting_title"` - Title of the meeting
    * `"decisions"` - Decisions made during the meeting
    * `"status"` - Current status
    * `"tags"` - Associated tags
    * `"date"` - Date of meeting

  ## Returns
    List of Meeting structs ordered by date descending.
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
  Returns all items in a date range, sorted chronologically.
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
  Expects a map with "commit_hash", "author", "message", and optionally "date".
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

  # --- Debate ---

  def get_or_create_debate(resource_id, resource_type) do
    case get_debate_by_resource(resource_id, resource_type) do
      {:ok, debate} -> {:ok, debate}
      {:error, :not_found} -> create_debate(resource_id, resource_type)
    end
  end

  def get_debate_by_resource(resource_id, resource_type) do
    case Repo.one(
           from(d in Debate,
             where: d.resource_id == ^resource_id and d.resource_type == ^resource_type,
             preload: [:messages, :judgment]
           )
         ) do
      nil -> {:error, :not_found}
      debate -> {:ok, debate}
    end
  end

  def get_debate(id) do
    case Repo.get(Debate, id) |> Repo.preload([:messages, :judgment]) do
      nil -> {:error, :not_found}
      debate -> {:ok, debate}
    end
  end

  def create_debate(resource_id, resource_type) do
    changeset =
      %Debate{}
      |> Debate.changeset(%{
        resource_id: resource_id,
        resource_type: resource_type,
        status: "open"
      })

    case Repo.insert(changeset) do
      {:ok, debate} -> {:ok, debate}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def add_debate_message(debate_id, attrs) do
    {:ok, _} =
      %DebateMessage{}
      |> DebateMessage.changeset(Map.put(attrs, "debate_id", debate_id))
      |> Repo.insert()

    debate = Repo.get!(Debate, debate_id)

    new_count = debate.message_count + 1

    debate
    |> Debate.changeset(%{message_count: new_count})
    |> Repo.update()

    {:ok, Repo.get!(Debate, debate_id) |> Repo.preload([:messages, :judgment])}
  end

  def create_judgment(debate_id, attrs) do
    changeset =
      %DebateJudgment{}
      |> DebateJudgment.changeset(Map.put(attrs, "debate_id", debate_id))

    case Repo.insert(changeset) do
      {:ok, _judgment} ->
        {:ok, debate} =
          get_debate(debate_id)
          |> then(fn {:ok, d} ->
            d
            |> Debate.changeset(%{status: "judged", judge_triggered_at: NaiveDateTime.utc_now()})
            |> Repo.update()
          end)

        {:ok, Repo.preload(debate, [:messages, :judgment])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def list_pending_judgments do
    from(d in Debate,
      where: d.message_count >= 3 and d.status == "open",
      preload: [:messages, :judgment]
    )
    |> Repo.all()
  end

  def list_debates(params \\ %{}) do
    limit = Map.get(params, "limit", 50)
    status = Map.get(params, "status")

    query =
      from(d in Debate,
        order_by: [desc: d.inserted_at],
        limit: ^limit,
        preload: [:messages, :judgment]
      )

    query =
      if status do
        from(d in query, where: d.status == ^status)
      else
        query
      end

    Repo.all(query)
  end

  def get_debate_with_resource(debate_id) do
    case get_debate(debate_id) do
      {:ok, debate} ->
        resource = get_resource(debate.resource_id, debate.resource_type)
        {:ok, Map.put(debate, :resource, resource)}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  defp get_resource(id, "adr"), do: Repo.get(ADR, id)
  defp get_resource(id, "failure"), do: Repo.get(Failure, id)
  defp get_resource(id, "meeting"), do: Repo.get(Meeting, id)
  defp get_resource(id, "snapshot"), do: Repo.get(Snapshot, id)
  defp get_resource(_id, _type), do: nil

  # --- Error Formatting ---

  def format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  # --- Private helpers ---

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

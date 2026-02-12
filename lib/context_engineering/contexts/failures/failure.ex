defmodule ContextEngineering.Contexts.Failures.Failure do
  @moduledoc """
  Schema for Failure records (incidents, outages, bugs, and post-mortems).

  A Failure documents what went wrong, why it happened, how it was fixed,
  and what was learned. This creates organizational memory that helps prevent
  recurring issues and informs future architectural decisions.

  ## Fields

  - `:id` - Unique identifier (e.g., "FAIL-001", "FAIL-042")
  - `:title` - Short description of the failure
  - `:incident_date` - When the failure occurred
  - `:severity` - Impact level: "low", "medium", "high", or "critical"
  - `:root_cause` - Why the failure happened (the underlying technical cause)
  - `:symptoms` - What users/systems experienced (observable effects)
  - `:impact` - Business/user impact description (optional)
  - `:resolution` - How the issue was fixed
  - `:prevention` - List of steps taken to prevent recurrence
  - `:status` - Current state: "investigating", "resolved", or "recurring"
  - `:pattern` - Identified pattern or category (e.g., "connection-pool", "rate-limit")
  - `:tags` - List of keywords for categorization (e.g., ["database", "performance"])
  - `:lessons_learned` - Key takeaways and insights (optional)
  - `:author` - Person or team who documented the failure
  - `:embedding` - Vector embedding for semantic search (generated automatically)
  - `:access_count_30d` - Number of times accessed in last 30 days
  - `:reference_count` - Number of other items that reference this failure

  ## Relationships

  - `has_many :relationships_from` - Outgoing relationships to other knowledge items
  - `has_many :relationships_to` - Incoming relationships from other knowledge items

  ## Usage

  Failures are typically created through the `ContextEngineering.Knowledge` context:

      iex> Knowledge.create_failure(%{
      ...>   "title" => "Database connection pool exhausted",
      ...>   "symptoms" => "API returning 504 timeouts",
      ...>   "root_cause" => "Pool size too small for traffic spike",
      ...>   "resolution" => "Increased pool size from 10 to 50",
      ...>   "severity" => "high"
      ...> })

  Or via the Mix task:

      $ mix context.failure --title "API timeout" --root-cause "..." --symptoms "..."

  Or automatically from error events:

      POST /api/events/error
      {"error_message": "Connection timeout", "stack_trace": "...", ...}

  ## Severity Levels

  - **low** - Minor issue, no user impact
  - **medium** - Some users affected, workaround available
  - **high** - Significant user impact, urgent fix needed
  - **critical** - System down, all users affected

  ## Status Lifecycle

  1. **investigating** - Issue just discovered, diagnosis in progress
  2. **resolved** - Fixed and verified (most common state)
  3. **recurring** - Same issue happened multiple times (pattern detected)
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias ContextEngineering.Contexts.Relationships.Relationship

  @derive {Jason.Encoder,
           only: [
             :id,
             :title,
             :incident_date,
             :severity,
             :root_cause,
             :symptoms,
             :impact,
             :resolution,
             :prevention,
             :status,
             :pattern,
             :tags,
             :lessons_learned,
             :author,
             :access_count_30d,
             :reference_count,
             :inserted_at,
             :updated_at
           ]}

  @primary_key {:id, :string, autogenerate: false}
  schema "failures" do
    field :title, :string
    field :incident_date, :date
    field :severity, :string
    field :root_cause, :string
    field :symptoms, :string
    field :impact, :string
    field :resolution, :string
    field :prevention, {:array, :string}, default: []
    field :status, :string, default: "resolved"
    field :pattern, :string
    field :tags, {:array, :string}, default: []
    field :lessons_learned, :string
    field :author, :string
    field :embedding, Pgvector.Ecto.Vector
    field :access_count_30d, :integer, default: 0
    field :reference_count, :integer, default: 0

    has_many :relationships_from, Relationship, foreign_key: :from_id
    has_many :relationships_to, Relationship, foreign_key: :to_id

    timestamps()
  end

  @doc """
  Changeset for creating or updating a Failure record.

  ## Required fields
  - `:id` - Must be set (usually via `Knowledge.next_id("failure")`)
  - `:title`
  - `:incident_date`
  - `:root_cause`

  ## Valid severity values
  - "low"
  - "medium"
  - "high"
  - "critical"

  ## Valid status values
  - "investigating"
  - "resolved" (default)
  - "recurring"
  """
  def changeset(failure, attrs) do
    failure
    |> cast(attrs, [
      :id,
      :title,
      :incident_date,
      :severity,
      :root_cause,
      :symptoms,
      :impact,
      :resolution,
      :prevention,
      :status,
      :pattern,
      :tags,
      :lessons_learned,
      :author
    ])
    |> validate_required([:id, :title, :incident_date, :root_cause])
    |> validate_inclusion(:severity, ["low", "medium", "high", "critical"])
    |> validate_inclusion(:status, ["investigating", "resolved", "recurring"])
    |> unique_constraint(:id)
  end

  @doc """
  Adds a vector embedding to the changeset.

  Called automatically by `Knowledge.create_failure/1` after generating
  embeddings via `EmbeddingService`.
  """
  def with_embedding(changeset, embedding) do
    put_change(changeset, :embedding, embedding)
  end
end

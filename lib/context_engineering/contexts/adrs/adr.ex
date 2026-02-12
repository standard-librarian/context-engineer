defmodule ContextEngineering.Contexts.ADRs.ADR do
  @moduledoc """
  Schema for Architecture Decision Records (ADRs).

  An ADR documents an architectural decision made during software development,
  including the context, decision, consequences, and status. ADRs are immutable
  historical records that help teams understand why systems are built the way they are.

  ## Fields

  - `:id` - Unique identifier (e.g., "ADR-001", "ADR-042")
  - `:title` - Short, descriptive title of the decision
  - `:decision` - The actual decision that was made
  - `:context` - Background, problem statement, and constraints that led to the decision
  - `:options_considered` - Map of alternatives that were evaluated (optional)
  - `:outcome` - Expected or observed consequences of the decision (optional)
  - `:status` - Current status: "active", "superseded", or "archived"
  - `:created_date` - When the decision was originally made
  - `:supersedes` - List of ADR IDs that this decision replaces
  - `:superseded_by` - ADR ID that replaces this decision (if status is "superseded")
  - `:tags` - List of keywords for categorization (e.g., ["database", "performance"])
  - `:author` - Person or team who authored the ADR
  - `:stakeholders` - List of people/teams affected by or involved in the decision
  - `:embedding` - Vector embedding for semantic search (generated automatically)
  - `:access_count_30d` - Number of times accessed in last 30 days (for relevance decay)
  - `:reference_count` - Number of other items that reference this ADR

  ## Relationships

  - `has_many :relationships_from` - Outgoing relationships to other knowledge items
  - `has_many :relationships_to` - Incoming relationships from other knowledge items

  ## Usage

  ADRs are typically created through the `ContextEngineering.Knowledge` context:

      iex> Knowledge.create_adr(%{
      ...>   "title" => "Use PostgreSQL for persistence",
      ...>   "decision" => "We will use PostgreSQL as our primary database",
      ...>   "context" => "We need ACID guarantees and complex queries"
      ...> })

  Or via the Mix task:

      $ mix context.adr --title "Use Redis for caching" --decision "..." --context "..."

  ## Status Lifecycle

  1. **active** - Current, in-use decision
  2. **superseded** - Replaced by a newer ADR (set `:superseded_by`)
  3. **archived** - Old, no longer relevant (set by decay worker)

  """
  use Ecto.Schema
  import Ecto.Changeset
  alias ContextEngineering.Contexts.Relationships.Relationship

  @derive {Jason.Encoder,
           only: [
             :id,
             :title,
             :decision,
             :context,
             :options_considered,
             :outcome,
             :status,
             :created_date,
             :supersedes,
             :superseded_by,
             :tags,
             :author,
             :stakeholders,
             :access_count_30d,
             :reference_count,
             :inserted_at,
             :updated_at
           ]}

  @primary_key {:id, :string, autogenerate: false}
  schema "adrs" do
    field :title, :string
    field :decision, :string
    field :context, :string
    field :options_considered, :map
    field :outcome, :string
    field :status, :string, default: "active"
    field :created_date, :date
    field :supersedes, {:array, :string}, default: []
    field :superseded_by, :string
    field :tags, {:array, :string}, default: []
    field :author, :string
    field :stakeholders, {:array, :string}, default: []
    field :embedding, Pgvector.Ecto.Vector
    field :access_count_30d, :integer, default: 0
    field :reference_count, :integer, default: 0

    has_many :relationships_from, Relationship, foreign_key: :from_id
    has_many :relationships_to, Relationship, foreign_key: :to_id

    timestamps()
  end

  @doc """
  Changeset for creating or updating an ADR.

  ## Required fields
  - `:id` - Must be set (usually via `Knowledge.next_id("adr")`)
  - `:title`
  - `:decision`
  - `:created_date`

  ## Valid status values
  - "active" (default)
  - "superseded"
  - "archived"
  """
  def changeset(adr, attrs) do
    adr
    |> cast(attrs, [
      :id,
      :title,
      :decision,
      :context,
      :options_considered,
      :outcome,
      :status,
      :created_date,
      :supersedes,
      :superseded_by,
      :tags,
      :author,
      :stakeholders
    ])
    |> validate_required([:id, :title, :decision, :created_date])
    |> validate_inclusion(:status, ["active", "superseded", "archived"])
    |> unique_constraint(:id)
  end

  @doc """
  Adds a vector embedding to the changeset.

  Called automatically by `Knowledge.create_adr/1` after generating
  embeddings via `EmbeddingService`.
  """
  def with_embedding(changeset, embedding) do
    put_change(changeset, :embedding, embedding)
  end
end

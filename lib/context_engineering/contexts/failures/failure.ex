defmodule ContextEngineering.Contexts.Failures.Failure do
  use Ecto.Schema
  import Ecto.Changeset
  alias ContextEngineering.Contexts.Relationships.Relationship

  @derive {Jason.Encoder,
           only: [
             :id, :title, :incident_date, :severity, :root_cause, :symptoms, :impact,
             :resolution, :prevention, :status, :pattern, :tags, :lessons_learned,
             :author, :access_count_30d, :reference_count, :inserted_at, :updated_at
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

  def changeset(failure, attrs) do
    failure
    |> cast(attrs, [
      :id, :title, :incident_date, :severity, :root_cause,
      :symptoms, :impact, :resolution, :prevention, :status,
      :pattern, :tags, :lessons_learned, :author
    ])
    |> validate_required([:id, :title, :incident_date, :root_cause])
    |> validate_inclusion(:severity, ["low", "medium", "high", "critical"])
    |> validate_inclusion(:status, ["investigating", "resolved", "recurring"])
    |> unique_constraint(:id)
  end

  def with_embedding(changeset, embedding) do
    put_change(changeset, :embedding, embedding)
  end
end

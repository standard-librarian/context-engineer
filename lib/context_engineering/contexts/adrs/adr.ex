defmodule ContextEngineering.Contexts.ADRs.ADR do
  use Ecto.Schema
  import Ecto.Changeset
  alias ContextEngineering.Contexts.Relationships.Relationship

  @derive {Jason.Encoder,
           only: [
             :id, :title, :decision, :context, :options_considered, :outcome,
             :status, :created_date, :supersedes, :superseded_by, :tags, :author,
             :stakeholders, :access_count_30d, :reference_count, :inserted_at, :updated_at
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

  def changeset(adr, attrs) do
    adr
    |> cast(attrs, [
      :id, :title, :decision, :context, :options_considered,
      :outcome, :status, :created_date, :supersedes, :superseded_by,
      :tags, :author, :stakeholders
    ])
    |> validate_required([:id, :title, :decision, :created_date])
    |> validate_inclusion(:status, ["active", "superseded", "archived"])
    |> unique_constraint(:id)
  end

  def with_embedding(changeset, embedding) do
    put_change(changeset, :embedding, embedding)
  end
end

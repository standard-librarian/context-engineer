defmodule ContextEngineering.Contexts.Snapshots.Snapshot do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id, :commit_hash, :author, :message, :date, :tags, :status,
             :access_count_30d, :inserted_at, :updated_at
           ]}

  @primary_key {:id, :string, autogenerate: false}
  schema "snapshots" do
    field :commit_hash, :string
    field :author, :string
    field :message, :string
    field :date, :date
    field :tags, {:array, :string}, default: []
    field :status, :string, default: "active"
    field :embedding, Pgvector.Ecto.Vector
    field :access_count_30d, :integer, default: 0

    timestamps()
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [:id, :commit_hash, :author, :message, :date, :tags, :status])
    |> validate_required([:id, :commit_hash, :message, :date])
    |> validate_inclusion(:status, ["active", "archived"])
    |> unique_constraint(:id)
    |> unique_constraint(:commit_hash)
  end

  def with_embedding(changeset, embedding) do
    put_change(changeset, :embedding, embedding)
  end
end

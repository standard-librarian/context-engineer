defmodule ContextEngineering.Contexts.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id, :meeting_title, :date, :decisions, :attendees, :tags, :status,
             :access_count_30d, :inserted_at, :updated_at
           ]}

  @primary_key {:id, :string, autogenerate: false}
  schema "meetings" do
    field :meeting_title, :string
    field :date, :date
    field :decisions, :map
    field :attendees, {:array, :string}, default: []
    field :tags, {:array, :string}, default: []
    field :status, :string, default: "active"
    field :embedding, Pgvector.Ecto.Vector
    field :access_count_30d, :integer, default: 0

    timestamps()
  end

  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [:id, :meeting_title, :date, :decisions, :attendees, :tags, :status])
    |> validate_required([:id, :meeting_title, :date, :decisions])
    |> validate_inclusion(:status, ["active", "completed", "cancelled"])
    |> unique_constraint(:id)
  end

  def with_embedding(changeset, embedding) do
    put_change(changeset, :embedding, embedding)
  end
end

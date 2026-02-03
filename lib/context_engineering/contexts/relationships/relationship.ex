defmodule ContextEngineering.Contexts.Relationships.Relationship do
  use Ecto.Schema
  import Ecto.Changeset

  schema "relationships" do
    field :from_id, :string
    field :from_type, :string
    field :to_id, :string
    field :to_type, :string
    field :relationship_type, :string
    field :strength, :float, default: 1.0

    timestamps()
  end

  def changeset(relationship, attrs) do
    relationship
    |> cast(attrs, [:from_id, :from_type, :to_id, :to_type, :relationship_type, :strength])
    |> validate_required([:from_id, :from_type, :to_id, :to_type, :relationship_type])
    |> validate_inclusion(:from_type, ["adr", "failure", "meeting", "snapshot"])
    |> validate_inclusion(:to_type, ["adr", "failure", "meeting", "snapshot"])
  end
end

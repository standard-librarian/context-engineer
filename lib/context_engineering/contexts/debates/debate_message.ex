defmodule ContextEngineering.Contexts.Debates.DebateMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :debate_id,
             :contributor_id,
             :contributor_type,
             :stance,
             :argument,
             :inserted_at,
             :updated_at
           ]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "debate_messages" do
    field(:debate_id, :binary_id)
    field(:contributor_id, :string)
    field(:contributor_type, :string, default: "agent")
    field(:stance, :string)
    field(:argument, :string)

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:debate_id, :contributor_id, :contributor_type, :stance, :argument])
    |> validate_required([:debate_id, :stance, :argument])
    |> validate_inclusion(:stance, ["agree", "disagree", "neutral", "question"])
    |> validate_inclusion(:contributor_type, ["agent", "human"])
    |> validate_length(:argument, min: 10, max: 5000)
  end
end

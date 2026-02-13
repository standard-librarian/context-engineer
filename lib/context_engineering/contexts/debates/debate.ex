defmodule ContextEngineering.Contexts.Debates.Debate do
  use Ecto.Schema
  import Ecto.Changeset

  alias ContextEngineering.Contexts.Debates.DebateMessage
  alias ContextEngineering.Contexts.Debates.DebateJudgment

  @derive {Jason.Encoder,
           only: [
             :id,
             :resource_id,
             :resource_type,
             :status,
             :message_count,
             :judge_triggered_at,
             :inserted_at,
             :updated_at
           ]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "debates" do
    field(:resource_id, :string)
    field(:resource_type, :string)
    field(:status, :string, default: "open")
    field(:message_count, :integer, default: 0)
    field(:judge_triggered_at, :naive_datetime)

    has_many(:messages, DebateMessage, foreign_key: :debate_id)
    has_one(:judgment, DebateJudgment, foreign_key: :debate_id)

    timestamps()
  end

  def changeset(debate, attrs) do
    debate
    |> cast(attrs, [:resource_id, :resource_type, :status, :message_count, :judge_triggered_at])
    |> validate_required([:resource_id, :resource_type])
    |> validate_inclusion(:resource_type, ["adr", "failure", "meeting", "snapshot"])
    |> validate_inclusion(:status, ["open", "judged", "closed"])
    |> unique_constraint([:resource_id, :resource_type],
      name: :debates_resource_id_resource_type_index
    )
  end
end

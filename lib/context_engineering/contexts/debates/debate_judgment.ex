defmodule ContextEngineering.Contexts.Debates.DebateJudgment do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :debate_id,
             :judge_agent_id,
             :score,
             :accuracy_score,
             :relevance_score,
             :completeness_score,
             :clarity_score,
             :confidence,
             :summary,
             :suggested_action,
             :action_reason,
             :inserted_at,
             :updated_at
           ]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "debate_judgments" do
    field(:debate_id, :binary_id)
    field(:judge_agent_id, :string)
    field(:score, :integer)
    field(:accuracy_score, :integer)
    field(:relevance_score, :integer)
    field(:completeness_score, :integer)
    field(:clarity_score, :integer)
    field(:confidence, :float)
    field(:summary, :string)
    field(:suggested_action, :string)
    field(:action_reason, :string)

    timestamps()
  end

  def changeset(judgment, attrs) do
    judgment
    |> cast(attrs, [
      :debate_id,
      :judge_agent_id,
      :score,
      :accuracy_score,
      :relevance_score,
      :completeness_score,
      :clarity_score,
      :confidence,
      :summary,
      :suggested_action,
      :action_reason
    ])
    |> validate_required([:debate_id, :score, :summary])
    |> validate_number(:score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:accuracy_score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:relevance_score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:completeness_score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:clarity_score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:confidence, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_inclusion(:suggested_action, ["none", "review", "update", "deprecate"])
  end
end

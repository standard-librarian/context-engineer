defmodule ContextEngineering.Repo.Migrations.CreateDebateJudgments do
  use Ecto.Migration

  def change do
    create table(:debate_judgments, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:debate_id, references(:debates, type: :binary_id, on_delete: :delete_all), null: false)
      add(:judge_agent_id, :string)
      add(:score, :integer)
      add(:accuracy_score, :integer)
      add(:relevance_score, :integer)
      add(:completeness_score, :integer)
      add(:clarity_score, :integer)
      add(:confidence, :float)
      add(:summary, :text)
      add(:suggested_action, :string)
      add(:action_reason, :text)

      timestamps()
    end

    create(index(:debate_judgments, [:debate_id]))
  end
end

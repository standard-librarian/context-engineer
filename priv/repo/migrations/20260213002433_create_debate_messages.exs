defmodule ContextEngineering.Repo.Migrations.CreateDebateMessages do
  use Ecto.Migration

  def change do
    create table(:debate_messages, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:debate_id, references(:debates, type: :binary_id, on_delete: :delete_all), null: false)
      add(:contributor_id, :string)
      add(:contributor_type, :string, default: "agent")
      add(:stance, :string, null: false)
      add(:argument, :text, null: false)

      timestamps()
    end

    create(index(:debate_messages, [:debate_id]))
    create(index(:debate_messages, [:contributor_id]))
  end
end

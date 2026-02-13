defmodule ContextEngineering.Repo.Migrations.CreateDebates do
  use Ecto.Migration

  def change do
    create table(:debates, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:resource_id, :string, null: false)
      add(:resource_type, :string, null: false)
      add(:status, :string, default: "open")
      add(:message_count, :integer, default: 0)
      add(:judge_triggered_at, :naive_datetime)

      timestamps()
    end

    create(index(:debates, [:resource_id, :resource_type]))
    create(index(:debates, [:status]))
  end
end

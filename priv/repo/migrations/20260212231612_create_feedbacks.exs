defmodule ContextEngineering.Repo.Migrations.CreateFeedbacks do
  use Ecto.Migration

  def change do
    create table(:feedbacks, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:query_id, :binary_id)
      add(:query_text, :text)
      add(:overall_rating, :integer)
      add(:items_helpful, {:array, :string}, default: [])
      add(:items_not_helpful, {:array, :string}, default: [])
      add(:items_used, {:array, :string}, default: [])
      add(:missing_context, :text)
      add(:agent_id, :string)
      add(:session_id, :string)
      add(:metadata, :map, default: %{})

      timestamps()
    end

    create(index(:feedbacks, [:query_id]))
    create(index(:feedbacks, [:agent_id]))
    create(index(:feedbacks, [:session_id]))
    create(index(:feedbacks, [:inserted_at]))
  end
end

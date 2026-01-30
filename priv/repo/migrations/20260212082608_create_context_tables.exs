defmodule ContextEngineering.Repo.Migrations.CreateContextTables do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    # ADRs table
    create table(:adrs, primary_key: false) do
      add :id, :string, primary_key: true
      add :title, :text, null: false
      add :decision, :text, null: false
      add :context, :text
      add :options_considered, :map
      add :outcome, :text
      add :status, :string, default: "active"
      add :created_date, :date, null: false
      add :supersedes, {:array, :string}, default: []
      add :superseded_by, :string
      add :tags, {:array, :string}, default: []
      add :author, :string
      add :stakeholders, {:array, :string}, default: []
      add :embedding, :vector, size: 384
      add :access_count_30d, :integer, default: 0
      add :reference_count, :integer, default: 0

      timestamps()
    end

    # Failures table
    create table(:failures, primary_key: false) do
      add :id, :string, primary_key: true
      add :title, :text, null: false
      add :incident_date, :date, null: false
      add :severity, :string
      add :root_cause, :text, null: false
      add :symptoms, :text
      add :impact, :text
      add :resolution, :text
      add :prevention, {:array, :string}, default: []
      add :status, :string, default: "resolved"
      add :pattern, :string
      add :tags, {:array, :string}, default: []
      add :lessons_learned, :text
      add :author, :string
      add :embedding, :vector, size: 384
      add :access_count_30d, :integer, default: 0
      add :reference_count, :integer, default: 0

      timestamps()
    end

    # Meetings table
    create table(:meetings, primary_key: false) do
      add :id, :string, primary_key: true
      add :meeting_title, :text, null: false
      add :date, :date, null: false
      add :decisions, :map, null: false
      add :attendees, {:array, :string}, default: []
      add :tags, {:array, :string}, default: []
      add :status, :string, default: "active"
      add :embedding, :vector, size: 384
      add :access_count_30d, :integer, default: 0

      timestamps()
    end

    # Relationships table
    create table(:relationships) do
      add :from_id, :string, null: false
      add :from_type, :string, null: false
      add :to_id, :string, null: false
      add :to_type, :string, null: false
      add :relationship_type, :string, null: false
      add :strength, :float, default: 1.0

      timestamps()
    end

    # Usage analytics
    create table(:context_usage) do
      add :agent_id, :string
      add :query, :text
      add :retrieved_items, :map
      add :was_helpful, :boolean
      add :response_time_ms, :integer

      timestamps()
    end

    # Indexes
    create index(:adrs, [:status])
    create index(:adrs, [:tags], using: :gin)
    create index(:adrs, [:created_date])

    create index(:failures, [:status])
    create index(:failures, [:severity])
    create index(:failures, [:pattern])
    create index(:failures, [:tags], using: :gin)

    create index(:meetings, [:status])
    create index(:meetings, [:date])
    create index(:meetings, [:tags], using: :gin)

    create index(:relationships, [:from_id, :from_type])
    create index(:relationships, [:to_id, :to_type])
    create index(:relationships, [:relationship_type])

    create index(:context_usage, [:agent_id])
    create index(:context_usage, [:inserted_at])
  end

  def down do
    drop table(:context_usage)
    drop table(:relationships)
    drop table(:meetings)
    drop table(:failures)
    drop table(:adrs)
    execute "DROP EXTENSION IF EXISTS vector"
  end
end

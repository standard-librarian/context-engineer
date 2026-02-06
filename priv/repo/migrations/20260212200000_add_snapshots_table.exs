defmodule ContextEngineering.Repo.Migrations.AddSnapshotsTable do
  use Ecto.Migration

  def change do
    create table(:snapshots, primary_key: false) do
      add :id, :string, primary_key: true
      add :commit_hash, :string
      add :author, :string
      add :message, :string
      add :date, :date
      add :tags, {:array, :string}, default: []
      add :status, :string, default: "active"
      add :embedding, :vector, size: 384
      add :access_count_30d, :integer, default: 0

      timestamps()
    end

    create index(:snapshots, [:status])
    create index(:snapshots, [:date])
    create index(:snapshots, [:tags], using: "GIN")
    create unique_index(:snapshots, [:commit_hash])
  end
end

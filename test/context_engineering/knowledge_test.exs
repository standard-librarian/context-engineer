defmodule ContextEngineering.KnowledgeTest do
  use ContextEngineering.DataCase

  alias ContextEngineering.Knowledge
  alias ContextEngineering.Contexts.ADRs.ADR

  # --- Create ---

  test "create_adr creates an ADR with embedding and returns it" do
    params = %{
      "id" => "ADR-100",
      "title" => "Use Elixir",
      "decision" => "Adopt Elixir for backend services",
      "context" => "Need concurrent processing",
      "created_date" => "2026-01-15",
      "tags" => ["infrastructure"]
    }

    assert {:ok, adr} = Knowledge.create_adr(params)
    assert adr.id == "ADR-100"
    assert adr.title == "Use Elixir"
    assert adr.embedding != nil
  end

  test "create_failure creates a failure with embedding" do
    params = %{
      "id" => "FAIL-100",
      "title" => "API Timeout",
      "root_cause" => "Slow database query",
      "incident_date" => "2026-01-10",
      "severity" => "high"
    }

    assert {:ok, failure} = Knowledge.create_failure(params)
    assert failure.id == "FAIL-100"
    assert failure.embedding != nil
  end

  test "create_meeting creates a meeting with embedding" do
    params = %{
      "id" => "MEET-100",
      "meeting_title" => "Sprint Planning",
      "date" => "2026-01-20",
      "decisions" => %{"items" => [%{"decision" => "Start new feature"}]}
    }

    assert {:ok, meeting} = Knowledge.create_meeting(params)
    assert meeting.id == "MEET-100"
    assert meeting.embedding != nil
  end

  # --- Next ID ---

  test "next_id generates sequential IDs" do
    # With no existing records, should return *-001
    assert Knowledge.next_id("adr") == "ADR-001"
    assert Knowledge.next_id("failure") == "FAIL-001"
    assert Knowledge.next_id("meeting") == "MEET-001"
    assert Knowledge.next_id("snapshot") == "SNAP-001"

    # Insert one ADR and check increment
    {:ok, _} =
      Knowledge.create_adr(%{
        "id" => "ADR-001",
        "title" => "First",
        "decision" => "Test",
        "created_date" => "2026-01-01"
      })

    assert Knowledge.next_id("adr") == "ADR-002"
  end

  # --- Auto Tags ---

  test "auto_tags extracts relevant tags from text" do
    tags = Knowledge.auto_tags("PostgreSQL database performance optimization under load")
    assert "database" in tags
    assert "performance" in tags
  end

  test "auto_tags returns empty list for empty text" do
    assert Knowledge.auto_tags("") == []
    assert Knowledge.auto_tags(nil) == []
  end

  # --- Timeline ---

  test "timeline returns items in chronological order" do
    {:ok, _} =
      Knowledge.create_adr(%{
        "id" => "ADR-T1",
        "title" => "Early ADR",
        "decision" => "Early decision",
        "created_date" => "2026-01-01"
      })

    {:ok, _} =
      Knowledge.create_failure(%{
        "id" => "FAIL-T1",
        "title" => "Mid Failure",
        "root_cause" => "Something broke",
        "incident_date" => "2026-01-15",
        "severity" => "medium"
      })

    {:ok, _} =
      Knowledge.create_meeting(%{
        "id" => "MEET-T1",
        "meeting_title" => "Late Meeting",
        "date" => "2026-01-30",
        "decisions" => %{"items" => []}
      })

    items = Knowledge.timeline(~D[2026-01-01], ~D[2026-02-01])
    assert length(items) == 3

    dates = Enum.map(items, & &1.date)
    assert dates == Enum.sort(dates, {:asc, Date})

    assert Enum.at(items, 0).id == "ADR-T1"
    assert Enum.at(items, 1).id == "FAIL-T1"
    assert Enum.at(items, 2).id == "MEET-T1"
  end

  # --- Update ---

  test "update_adr updates fields" do
    {:ok, _} =
      Knowledge.create_adr(%{
        "id" => "ADR-U1",
        "title" => "Original",
        "decision" => "Original decision",
        "created_date" => "2026-01-01"
      })

    assert {:ok, updated} = Knowledge.update_adr("ADR-U1", %{"title" => "Updated Title"})
    assert updated.title == "Updated Title"
  end

  test "update_failure returns not_found for missing ID" do
    assert {:error, :not_found} = Knowledge.update_failure("NONEXISTENT", %{"title" => "X"})
  end

  # --- Snapshot ---

  test "create_snapshot stores git commit data as snapshot" do
    commit_data = %{
      "commit_hash" => "abc123def456",
      "author" => "dev@company.com",
      "message" => "Fix database connection pool issue",
      "date" => "2026-02-01"
    }

    assert {:ok, snapshot} = Knowledge.create_snapshot(commit_data)
    assert String.starts_with?(snapshot.id, "SNAP-")
    assert snapshot.commit_hash == "abc123def456"
    assert snapshot.author == "dev@company.com"
    assert snapshot.message == "Fix database connection pool issue"
    assert "git-snapshot" in snapshot.tags
    assert snapshot.status == "active"
    assert snapshot.embedding != nil
  end

  # --- Auto tags on create ---

  test "create_adr auto-tags when tags not provided" do
    params = %{
      "id" => "ADR-AT1",
      "title" => "PostgreSQL database optimization",
      "decision" => "Optimize slow database queries for better performance",
      "created_date" => "2026-01-01"
    }

    assert {:ok, adr} = Knowledge.create_adr(params)
    assert "database" in adr.tags
    assert "performance" in adr.tags
  end

  # --- Format errors ---

  test "format_errors converts changeset errors to map" do
    changeset =
      %ADR{}
      |> ADR.changeset(%{})

    errors = Knowledge.format_errors(changeset)
    assert Map.has_key?(errors, :id)
    assert Map.has_key?(errors, :title)
  end
end

defmodule ContextEngineeringWeb.ADRControllerTest do
  use ContextEngineeringWeb.ConnCase

  alias ContextEngineering.Services.EmbeddingService
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Repo

  setup do
    {:ok, embedding} =
      EmbeddingService.generate_embedding("Test ADR for PostgreSQL database choice")

    %ADR{
      id: "ADR-TEST",
      title: "Test ADR",
      decision: "Use PostgreSQL",
      context: "Testing context",
      status: "active",
      created_date: ~D[2025-06-15],
      tags: ["database"],
      author: "test@test.com",
      embedding: embedding
    }
    |> Repo.insert!()

    :ok
  end

  test "GET /api/adr returns list of ADRs", %{conn: conn} do
    conn = get(conn, "/api/adr")
    response = json_response(conn, 200)
    assert is_list(response)
    assert length(response) > 0
    assert hd(response)["id"] == "ADR-TEST"
  end

  test "GET /api/adr/:id returns a specific ADR", %{conn: conn} do
    conn = get(conn, "/api/adr/ADR-TEST")
    response = json_response(conn, 200)
    assert response["adr"]["id"] == "ADR-TEST"
    assert response["adr"]["title"] == "Test ADR"
  end

  test "GET /api/adr/:id returns 404 for missing ADR", %{conn: conn} do
    conn = get(conn, "/api/adr/NONEXISTENT")
    assert json_response(conn, 404)["error"] == "ADR not found"
  end

  test "POST /api/adr creates a new ADR", %{conn: conn} do
    conn =
      post(conn, "/api/adr", %{
        "adr" => %{
          "id" => "ADR-NEW",
          "title" => "New Test ADR",
          "decision" => "Use Elixir",
          "created_date" => "2025-12-01",
          "tags" => ["language"]
        }
      })

    response = json_response(conn, 201)
    assert response["id"] == "ADR-NEW"
    assert response["status"] == "created"

    # Verify it was persisted
    assert Repo.get(ADR, "ADR-NEW") != nil
  end
end

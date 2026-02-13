defmodule ContextEngineeringWeb.DebateControllerTest do
  use ContextEngineeringWeb.ConnCase

  alias ContextEngineering.Knowledge

  setup do
    {:ok, _} =
      Knowledge.create_adr(%{
        "id" => "ADR-TEST",
        "title" => "Test ADR",
        "decision" => "Use PostgreSQL",
        "created_date" => "2026-02-13"
      })

    :ok
  end

  test "GET /api/debate lists debates", %{conn: conn} do
    {:ok, _} = Knowledge.get_or_create_debate("ADR-TEST", "adr")

    conn = get(conn, "/api/debate")
    response = json_response(conn, 200)

    assert is_list(response)
    assert length(response) > 0
  end

  test "GET /api/debate/by-resource returns debate for resource", %{conn: conn} do
    {:ok, debate} = Knowledge.get_or_create_debate("ADR-TEST", "adr")

    conn = get(conn, "/api/debate/by-resource?resource_id=ADR-TEST&resource_type=adr")
    response = json_response(conn, 200)

    assert response["id"] == debate.id
    assert response["resource_id"] == "ADR-TEST"
  end

  test "GET /api/debate/by-resource returns nil for non-existent debate", %{conn: conn} do
    conn = get(conn, "/api/debate/by-resource?resource_id=NONEXISTENT&resource_type=adr")
    response = json_response(conn, 200)

    assert response == nil
  end

  test "GET /api/debate/:id returns specific debate", %{conn: conn} do
    {:ok, debate} = Knowledge.get_or_create_debate("ADR-TEST", "adr")

    conn = get(conn, "/api/debate/#{debate.id}")
    response = json_response(conn, 200)

    assert response["id"] == debate.id
    assert response["resource_id"] == "ADR-TEST"
  end

  test "GET /api/debate/:id returns 404 for missing debate", %{conn: conn} do
    conn = get(conn, "/api/debate/#{Ecto.UUID.generate()}")
    assert json_response(conn, 404)["error"] == "Debate not found"
  end

  test "POST /api/feedback with debate_contributions creates debate", %{conn: conn} do
    query_id = Ecto.UUID.generate()

    conn =
      post(conn, "/api/feedback", %{
        "query_id" => query_id,
        "overall_rating" => 4,
        "agent_id" => "test-agent",
        "debate_contributions" => [
          %{
            "resource_id" => "ADR-TEST",
            "stance" => "agree",
            "argument" => "This ADR is accurate and well documented."
          }
        ]
      })

    response = json_response(conn, 201)
    assert response["debates_processed"] != nil
    assert length(response["debates_processed"]) == 1

    debate = hd(response["debates_processed"])
    assert debate["resource_id"] == "ADR-TEST"
    assert debate["message_count"] == 1
  end

  test "POST /api/feedback triggers judge at 3 messages", %{conn: conn} do
    for i <- 1..3 do
      post(conn, "/api/feedback", %{
        "query_id" => Ecto.UUID.generate(),
        "agent_id" => "agent-#{i}",
        "debate_contributions" => [
          %{
            "resource_id" => "ADR-TEST",
            "stance" => if(rem(i, 2) == 0, do: "disagree", else: "agree"),
            "argument" => "Argument number #{i} about this ADR."
          }
        ]
      })
    end

    Process.sleep(100)

    {:ok, debate} = Knowledge.get_debate_by_resource("ADR-TEST", "adr")
    assert debate.message_count == 3
  end

  test "GET /api/debate/pending-judgment lists debates with 3+ messages", %{conn: conn} do
    {:ok, debate} = Knowledge.get_or_create_debate("ADR-TEST", "adr")

    for i <- 1..3 do
      Knowledge.add_debate_message(debate.id, %{
        "contributor_id" => "agent-#{i}",
        "stance" => "agree",
        "argument" => "Argument #{i}"
      })
    end

    conn = get(conn, "/api/debate/pending-judgment")
    response = json_response(conn, 200)

    assert is_list(response)
    pending_ids = Enum.map(response, & &1["id"])
    assert debate.id in pending_ids
  end
end

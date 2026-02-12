defmodule ContextEngineeringWeb.FeedbackControllerTest do
  use ContextEngineeringWeb.ConnCase

  alias ContextEngineering.Knowledge

  test "POST /api/feedback creates feedback", %{conn: conn} do
    query_id = Ecto.UUID.generate()

    conn =
      post(conn, "/api/feedback", %{
        "query_id" => query_id,
        "query_text" => "Why did we choose PostgreSQL?",
        "overall_rating" => 4,
        "items_helpful" => ["ADR-001", "FAIL-042"],
        "items_not_helpful" => ["MEET-012"],
        "agent_id" => "test-agent"
      })

    response = json_response(conn, 201)
    assert response["query_id"] == query_id
    assert response["overall_rating"] == 4
    assert response["items_helpful"] == ["ADR-001", "FAIL-042"]
  end

  test "POST /api/feedback validates rating range", %{conn: conn} do
    conn =
      post(conn, "/api/feedback", %{
        "query_id" => Ecto.UUID.generate(),
        "overall_rating" => 10
      })

    assert json_response(conn, 422)["errors"]["overall_rating"]
  end

  test "GET /api/feedback lists feedback", %{conn: conn} do
    {:ok, _} =
      Knowledge.create_feedback(%{
        "query_id" => Ecto.UUID.generate(),
        "query_text" => "Test query",
        "agent_id" => "agent-1"
      })

    conn = get(conn, "/api/feedback")
    response = json_response(conn, 200)

    assert is_list(response)
    assert length(response) > 0
  end

  test "GET /api/feedback filters by agent_id", %{conn: conn} do
    {:ok, _} =
      Knowledge.create_feedback(%{
        "query_id" => Ecto.UUID.generate(),
        "query_text" => "Query 1",
        "agent_id" => "agent-1"
      })

    {:ok, _} =
      Knowledge.create_feedback(%{
        "query_id" => Ecto.UUID.generate(),
        "query_text" => "Query 2",
        "agent_id" => "agent-2"
      })

    conn = get(conn, "/api/feedback?agent_id=agent-1")
    response = json_response(conn, 200)

    assert length(response) == 1
    assert hd(response)["agent_id"] == "agent-1"
  end

  test "GET /api/feedback/:id returns specific feedback", %{conn: conn} do
    {:ok, feedback} =
      Knowledge.create_feedback(%{
        "query_id" => Ecto.UUID.generate(),
        "query_text" => "Test query"
      })

    conn = get(conn, "/api/feedback/#{feedback.id}")
    response = json_response(conn, 200)

    assert response["id"] == feedback.id
    assert response["query_text"] == "Test query"
  end

  test "GET /api/feedback/:id returns 404 for missing feedback", %{conn: conn} do
    conn = get(conn, "/api/feedback/#{Ecto.UUID.generate()}")
    assert json_response(conn, 404)["error"] == "Feedback not found"
  end

  test "GET /api/feedback/stats returns analytics", %{conn: conn} do
    {:ok, _} =
      Knowledge.create_feedback(%{
        "query_id" => Ecto.UUID.generate(),
        "query_text" => "Query 1",
        "overall_rating" => 4,
        "items_helpful" => ["ADR-001", "ADR-002"]
      })

    {:ok, _} =
      Knowledge.create_feedback(%{
        "query_id" => Ecto.UUID.generate(),
        "query_text" => "Query 2",
        "overall_rating" => 5,
        "items_helpful" => ["ADR-001"]
      })

    conn = get(conn, "/api/feedback/stats")
    response = json_response(conn, 200)

    assert response["total_feedback"] >= 2
    assert response["avg_rating"] != nil
    assert is_list(response["most_helpful_items"])
  end
end

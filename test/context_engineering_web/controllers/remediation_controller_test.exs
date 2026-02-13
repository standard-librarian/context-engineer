defmodule ContextEngineeringWeb.RemediationControllerTest do
  use ContextEngineeringWeb.ConnCase

  alias ContextEngineering.Knowledge

  describe "POST /api/remediate" do
    setup do
      {:ok, _failure} =
        Knowledge.create_failure(%{
          "id" => "FAIL-REM-001",
          "title" => "Connection Pool Exhaustion",
          "incident_date" => "2026-01-15",
          "root_cause" => "Database connection pool was too small",
          "resolution" => "Increased pool size to 200",
          "prevention" => ["Add monitoring", "Set alerts"],
          "status" => "resolved",
          "pattern" => "connection_error",
          "author" => "system"
        })

      {:ok, _failure} =
        Knowledge.create_failure(%{
          "id" => "FAIL-REM-002",
          "title" => "Database Query Timeout",
          "incident_date" => "2026-01-20",
          "root_cause" => "Slow SQL query without index",
          "resolution" => "Added index on user_id column",
          "prevention" => ["Query review process"],
          "status" => "resolved",
          "pattern" => "database_error",
          "author" => "system"
        })

      {:ok, _failure} =
        Knowledge.create_failure(%{
          "id" => "FAIL-REM-003",
          "title" => "Active Connection Issue",
          "incident_date" => "2026-02-01",
          "root_cause" => "Network partition",
          "resolution" => "Still investigating",
          "status" => "investigating",
          "pattern" => "connection_error",
          "author" => "system"
        })

      :ok
    end

    test "returns similar resolved incidents for connection error", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "connection timeout to database",
          "top_k" => 5
        })

      response = json_response(conn, 200)

      assert response["pattern"] == "connection_error"
      assert response["severity"] == "high"
      assert is_list(response["similar_incidents"])
      assert is_list(response["suggested_actions"])

      incident_ids = Enum.map(response["similar_incidents"], & &1["id"])
      assert "FAIL-REM-001" in incident_ids
      refute "FAIL-REM-003" in incident_ids
    end

    test "returns similar resolved incidents for database error", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "SQL query failed",
          "top_k" => 5
        })

      response = json_response(conn, 200)

      assert response["pattern"] == "database_error"
      assert response["severity"] == "high"
      assert is_list(response["similar_incidents"])
    end

    test "allows pattern override", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "something went wrong",
          "pattern" => "connection_error",
          "top_k" => 5
        })

      response = json_response(conn, 200)
      assert response["pattern"] == "connection_error"
    end

    test "returns suggested actions for pattern", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "runtime panic nil pointer",
          "top_k" => 5
        })

      response = json_response(conn, 200)

      assert response["pattern"] == "runtime_panic"
      assert response["severity"] == "critical"
      assert "Add defensive nil checks" in response["suggested_actions"]
    end

    test "only returns resolved failures", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "connection issue",
          "top_k" => 10
        })

      response = json_response(conn, 200)

      Enum.each(response["similar_incidents"], fn incident ->
        refute incident["id"] == "FAIL-REM-003"
      end)
    end

    test "respects top_k limit", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "connection timeout",
          "top_k" => 1
        })

      response = json_response(conn, 200)
      assert length(response["similar_incidents"]) <= 1
    end

    test "includes similarity score in results", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "connection pool exhaustion",
          "top_k" => 5
        })

      response = json_response(conn, 200)

      Enum.each(response["similar_incidents"], fn incident ->
        assert Map.has_key?(incident, "similarity")
        assert is_number(incident["similarity"])
        assert incident["similarity"] >= 0 and incident["similarity"] <= 1
      end)
    end

    test "classifies unknown pattern for unrecognized errors", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "something completely unexpected happened",
          "top_k" => 5
        })

      response = json_response(conn, 200)
      assert response["pattern"] == "unknown"
      assert response["severity"] == "medium"
    end

    test "works with stack trace", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "failed",
          "stack_trace" => "panic: runtime error: nil pointer dereference\ngoroutine 1",
          "top_k" => 5
        })

      response = json_response(conn, 200)
      assert response["pattern"] == "runtime_panic"
      assert response["severity"] == "critical"
    end

    test "incident has required fields", %{conn: conn} do
      conn =
        post(conn, "/api/remediate", %{
          "error_message" => "connection timeout",
          "top_k" => 5
        })

      response = json_response(conn, 200)

      Enum.each(response["similar_incidents"], fn incident ->
        assert Map.has_key?(incident, "id")
        assert Map.has_key?(incident, "title")
        assert Map.has_key?(incident, "root_cause")
        assert Map.has_key?(incident, "resolution")
        assert Map.has_key?(incident, "prevention")
        assert Map.has_key?(incident, "similarity")
        assert Map.has_key?(incident, "incident_date")
      end)
    end
  end
end

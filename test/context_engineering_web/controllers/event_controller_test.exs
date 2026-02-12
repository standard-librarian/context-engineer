defmodule ContextEngineeringWeb.EventControllerTest do
  use ContextEngineeringWeb.ConnCase

  # --- Error endpoint ---

  test "POST /api/events/error creates a failure", %{conn: conn} do
    conn =
      post(conn, "/api/events/error", %{
        "title" => "nil pointer dereference",
        "app_name" => "echo-api",
        "stack_trace" => "panic: runtime error: nil pointer dereference\ngoroutine 1",
        "severity" => "critical",
        "environment" => "production"
      })

    response = json_response(conn, 201)
    assert response["status"] == "captured"
    assert String.starts_with?(response["failure_id"], "FAIL-")
  end

  test "POST /api/events/error works with minimal payload", %{conn: conn} do
    conn = post(conn, "/api/events/error", %{"title" => "something broke"})

    response = json_response(conn, 201)
    assert response["status"] == "captured"
  end

  # --- Deploy endpoint ---

  test "POST /api/events/deploy creates a snapshot", %{conn: conn} do
    conn =
      post(conn, "/api/events/deploy", %{
        "app_name" => "echo-api",
        "version" => "v1.0.0",
        "deployer" => "dev@company.com",
        "commit_hash" => "deadbeef123",
        "environment" => "production",
        "changes" => ["Initial release"]
      })

    response = json_response(conn, 201)
    assert response["status"] == "captured"
    assert String.starts_with?(response["snapshot_id"], "SNAP-")
  end

  # --- Metric endpoint ---

  test "POST /api/events/metric creates failure when threshold exceeded", %{conn: conn} do
    conn =
      post(conn, "/api/events/metric", %{
        "app_name" => "echo-api",
        "metric_name" => "response_time_ms",
        "value" => 2000,
        "threshold" => 500,
        "severity" => "high"
      })

    response = json_response(conn, 201)
    assert response["status"] == "captured"
    assert String.starts_with?(response["failure_id"], "FAIL-")
  end

  test "POST /api/events/metric returns ok when within threshold", %{conn: conn} do
    conn =
      post(conn, "/api/events/metric", %{
        "metric_name" => "response_time_ms",
        "value" => 100,
        "threshold" => 500
      })

    response = json_response(conn, 200)
    assert response["status"] == "ok"
  end

  test "POST /api/events/metric returns error when fields missing", %{conn: conn} do
    conn = post(conn, "/api/events/metric", %{"metric_name" => "cpu"})

    assert json_response(conn, 400)["error"] != nil
  end

  # --- Log streaming ---

  test "POST /api/logs/stream processes error logs from batch", %{conn: conn} do
    logs = [
      %{"level" => "ERROR", "message" => "connection refused to db", "app" => "echo-api", "timestamp" => "2026-02-12T10:00:00Z"},
      %{"level" => "INFO", "message" => "request completed", "app" => "echo-api"},
      %{"level" => "PANIC", "message" => "nil pointer dereference", "app" => "echo-api"}
    ]

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/logs/stream", Jason.encode!(logs))

    response = json_response(conn, 201)
    assert response["status"] == "accepted"
    assert response["logs_received"] == 3
    assert response["errors_detected"] == 2
    assert length(response["failures_created"]) == 2
  end

  test "POST /api/logs/stream skips non-error logs", %{conn: conn} do
    logs = [
      %{"level" => "INFO", "message" => "started", "app" => "my-app"},
      %{"level" => "DEBUG", "message" => "query ran", "app" => "my-app"}
    ]

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/logs/stream", Jason.encode!(logs))

    response = json_response(conn, 201)
    assert response["errors_detected"] == 0
    assert response["failures_created"] == []
  end
end

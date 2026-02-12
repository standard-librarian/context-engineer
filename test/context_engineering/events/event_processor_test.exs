defmodule ContextEngineering.Events.EventProcessorTest do
  use ContextEngineering.DataCase

  alias ContextEngineering.Events.EventProcessor

  # --- Error Events ---

  test "process_error_event creates a failure from error data" do
    params = %{
      "title" => "connection refused",
      "app_name" => "my-go-app",
      "stack_trace" => "goroutine 1 [running]:\nmain.handler()\n\tserver.go:42",
      "severity" => "high",
      "environment" => "production",
      "timestamp" => "2026-02-12T10:30:00Z"
    }

    assert {:ok, failure} = EventProcessor.process_error_event(params)
    assert String.starts_with?(failure.id, "FAIL-")
    assert failure.title == "connection refused in my-go-app"
    assert failure.severity == "high"
    assert failure.status == "investigating"
    assert "auto-captured" in failure.tags
    assert "my-go-app" in failure.tags
    assert failure.embedding != nil
  end

  test "process_error_event auto-classifies severity when not provided" do
    params = %{
      "title" => "database query timeout",
      "app_name" => "api-service",
      "stack_trace" => "Error: database connection timeout after 30s"
    }

    assert {:ok, failure} = EventProcessor.process_error_event(params)
    # "database" pattern => "high" severity
    assert failure.severity == "high"
    assert failure.pattern == "database_error"
  end

  test "process_error_event works with minimal fields" do
    params = %{"title" => "something broke"}

    assert {:ok, failure} = EventProcessor.process_error_event(params)
    assert failure.title == "something broke"
    assert failure.severity != nil
    assert failure.status == "investigating"
  end

  test "process_error_event classifies Go panic patterns" do
    params = %{
      "title" => "runtime error",
      "stack_trace" => "panic: runtime error: nil pointer dereference\ngoroutine 1 [running]:",
      "app_name" => "echo-api"
    }

    assert {:ok, failure} = EventProcessor.process_error_event(params)
    assert failure.pattern == "runtime_panic"
    assert failure.severity == "critical"
  end

  # --- Deploy Events ---

  test "process_deploy_event creates a snapshot" do
    params = %{
      "app_name" => "my-go-app",
      "version" => "v1.2.3",
      "environment" => "production",
      "deployer" => "alice@company.com",
      "commit_hash" => "abc123def456",
      "changes" => ["Added health endpoint", "Fixed goroutine leak"]
    }

    assert {:ok, snapshot} = EventProcessor.process_deploy_event(params)
    assert String.starts_with?(snapshot.id, "SNAP-")
    assert snapshot.commit_hash == "abc123def456"
    assert snapshot.author == "alice@company.com"
    assert String.contains?(snapshot.message, "my-go-app")
    assert String.contains?(snapshot.message, "v1.2.3")
    assert snapshot.embedding != nil
  end

  test "process_deploy_event works without changes list" do
    params = %{
      "app_name" => "echo-api",
      "version" => "v2.0.0",
      "deployer" => "bob@company.com"
    }

    assert {:ok, snapshot} = EventProcessor.process_deploy_event(params)
    assert String.starts_with?(snapshot.id, "SNAP-")
    assert snapshot.message == "Deploy echo-api v2.0.0"
  end

  # --- Metric Events ---

  test "process_metric_event creates failure when threshold exceeded" do
    params = %{
      "app_name" => "echo-api",
      "metric_name" => "api_latency_p99",
      "value" => 1500,
      "threshold" => 1000,
      "severity" => "high"
    }

    assert {:ok, failure} = EventProcessor.process_metric_event(params)
    assert String.starts_with?(failure.id, "FAIL-")
    assert String.contains?(failure.title, "api_latency_p99")
    assert failure.pattern == "performance"
    assert failure.severity == "high"
  end

  test "process_metric_event returns :below_threshold when ok" do
    params = %{
      "metric_name" => "api_latency_p99",
      "value" => 500,
      "threshold" => 1000
    }

    assert {:ok, :below_threshold} = EventProcessor.process_metric_event(params)
  end

  test "process_metric_event returns error when fields missing" do
    assert {:error, _} = EventProcessor.process_metric_event(%{"metric_name" => "cpu"})
  end
end

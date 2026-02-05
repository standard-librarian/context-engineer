defmodule ContextEngineeringWeb.EventController do
  @moduledoc """
  Language-agnostic event ingestion endpoints.
  Any application (Go, Python, Node.js, Java, etc.) can POST events here.
  """

  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Events.EventProcessor
  alias ContextEngineering.Knowledge

  @doc """
  Receive error events from any application.

  POST /api/events/error
  {
    "title": "Database connection failed",
    "stack_trace": "...",
    "app_name": "my-go-app",
    "environment": "production",
    "severity": "high",
    "timestamp": "2026-02-12T10:30:00Z",
    "metadata": {"request_id": "abc123"}
  }
  """
  def error(conn, params) do
    case EventProcessor.process_error_event(params) do
      {:ok, failure} ->
        conn
        |> put_status(:created)
        |> json(%{
          status: "captured",
          failure_id: failure.id,
          message: "Error recorded"
        })

      {:error, changeset} when is_struct(changeset) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Receive deployment events from any application.

  POST /api/events/deploy
  {
    "app_name": "my-go-app",
    "version": "v1.2.3",
    "environment": "production",
    "deployer": "alice@company.com",
    "commit_hash": "abc123def",
    "changes": ["Added feature X", "Fixed bug Y"]
  }
  """
  def deploy(conn, params) do
    case EventProcessor.process_deploy_event(params) do
      {:ok, snapshot} ->
        conn
        |> put_status(:created)
        |> json(%{
          status: "captured",
          snapshot_id: snapshot.id,
          message: "Deployment recorded"
        })

      {:error, changeset} when is_struct(changeset) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Receive metric/performance threshold events.

  POST /api/events/metric
  {
    "app_name": "my-go-app",
    "metric_name": "api_latency_p99",
    "value": 1500,
    "threshold": 1000,
    "severity": "high"
  }
  """
  def metric(conn, params) do
    case EventProcessor.process_metric_event(params) do
      {:ok, failure} when is_struct(failure) ->
        conn
        |> put_status(:created)
        |> json(%{
          status: "captured",
          failure_id: failure.id,
          message: "Metric threshold violation recorded"
        })

      {:ok, :below_threshold} ->
        json(conn, %{status: "ok", message: "Metric within threshold"})

      {:error, changeset} when is_struct(changeset) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: to_string(reason)})
    end
  end
end

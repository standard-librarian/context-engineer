defmodule ContextEngineeringWeb.LogController do
  @moduledoc """
  Log streaming ingestion endpoint.
  Accepts structured log batches from Fluentd, Logstash, or direct POST from any application.
  """

  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Events.LogParser

  @doc """
  Ingest a batch of structured log entries.
  Filters for error-level logs and creates failure records.

  POST /api/logs/stream
  [
    {"timestamp": "...", "level": "ERROR", "message": "...", "app": "my-app"},
    {"timestamp": "...", "level": "INFO", "message": "...", "app": "my-app"}
  ]

  Also accepts a single log entry as a map.
  """
  def ingest(conn, %{"_json" => logs}) when is_list(logs) do
    do_ingest(conn, logs)
  end

  def ingest(conn, params) when is_map(params) do
    # Single log entry posted as a JSON object
    do_ingest(conn, [params])
  end

  defp do_ingest(conn, logs) do
    error_count = Enum.count(logs, &LogParser.error_log?/1)
    results = LogParser.process_batch(logs)

    created =
      results
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, failure} -> failure.id end)

    conn
    |> put_status(:created)
    |> json(%{
      status: "accepted",
      logs_received: length(logs),
      errors_detected: error_count,
      failures_created: created
    })
  end
end

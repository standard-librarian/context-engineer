defmodule ContextEngineeringWeb.RemediationController do
  @moduledoc """
  Auto-remediation endpoint for finding similar resolved incidents.
  """

  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Services.RemediationService

  @doc """
  Find similar resolved incidents for an error.

  POST /api/remediate
  {
    "error_message": "connection timeout",
    "stack_trace": "optional stack trace",
    "pattern": "optional override pattern",
    "app_name": "optional app name",
    "top_k": 5
  }
  """
  def create(conn, params) do
    case RemediationService.remediate(params) do
      {:ok, result} ->
        json(conn, result)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: to_string(reason)})
    end
  end
end

defmodule ContextEngineeringWeb.FeedbackController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Knowledge

  def create(conn, params) do
    case Knowledge.create_feedback(params) do
      {:ok, feedback} ->
        conn
        |> put_status(:created)
        |> json(feedback)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})
    end
  end

  def index(conn, params) do
    feedback = Knowledge.list_feedback(params)
    json(conn, feedback)
  end

  def show(conn, %{"id" => id}) do
    case Knowledge.get_feedback(id) do
      {:ok, feedback} ->
        json(conn, feedback)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Feedback not found"})
    end
  end

  def stats(conn, params) do
    days_back = Map.get(params, "days_back", "30") |> String.to_integer()
    stats = Knowledge.feedback_stats(days_back: days_back)
    json(conn, stats)
  end
end

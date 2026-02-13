defmodule ContextEngineeringWeb.DebateController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Knowledge

  def index(conn, params) do
    debates = Knowledge.list_debates(params)
    json(conn, debates)
  end

  def show(conn, %{"id" => id}) do
    case Knowledge.get_debate(id) do
      {:ok, debate} ->
        json(conn, debate)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Debate not found"})
    end
  end

  def by_resource(conn, %{"resource_id" => resource_id, "resource_type" => resource_type}) do
    case Knowledge.get_debate_by_resource(resource_id, resource_type) do
      {:ok, debate} ->
        json(conn, debate)

      {:error, :not_found} ->
        json(conn, nil)
    end
  end

  def pending_judgment(conn, _params) do
    debates = Knowledge.list_pending_judgments()
    json(conn, debates)
  end

  def judge(conn, %{"id" => debate_id}) do
    case Knowledge.get_debate_with_resource(debate_id) do
      {:ok, debate} ->
        ContextEngineering.Workers.JudgeWorker.trigger_judge(debate.id)
        json(conn, %{status: "judge_triggered", debate_id: debate_id})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Debate not found"})
    end
  end
end

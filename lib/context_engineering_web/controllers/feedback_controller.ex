defmodule ContextEngineeringWeb.FeedbackController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Knowledge

  def create(conn, params) do
    debate_contributions = Map.get(params, "debate_contributions", [])
    feedback_params = Map.drop(params, ["debate_contributions"])

    case Knowledge.create_feedback(feedback_params) do
      {:ok, feedback} ->
        agent_id = Map.get(params, "agent_id")

        debates_processed =
          Enum.map(debate_contributions, fn contribution ->
            process_debate_contribution(contribution, agent_id)
          end)

        response = %{
          id: feedback.id,
          query_id: feedback.query_id,
          query_text: feedback.query_text,
          overall_rating: feedback.overall_rating,
          items_helpful: feedback.items_helpful,
          items_not_helpful: feedback.items_not_helpful,
          items_used: feedback.items_used,
          missing_context: feedback.missing_context,
          agent_id: feedback.agent_id,
          session_id: feedback.session_id,
          inserted_at: feedback.inserted_at,
          updated_at: feedback.updated_at,
          debates_processed: debates_processed
        }

        conn
        |> put_status(:created)
        |> json(response)

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

  defp process_debate_contribution(contribution, agent_id) do
    resource_id = contribution["resource_id"]
    resource_type = contribution["resource_type"] || infer_resource_type(resource_id)
    stance = contribution["stance"]
    argument = contribution["argument"]

    {:ok, debate} = Knowledge.get_or_create_debate(resource_id, resource_type)

    {:ok, updated_debate} =
      Knowledge.add_debate_message(debate.id, %{
        "contributor_id" => agent_id,
        "contributor_type" => "agent",
        "stance" => stance,
        "argument" => argument
      })

    if updated_debate.message_count >= 3 and updated_debate.status == "open" do
      ContextEngineering.Workers.JudgeWorker.trigger_judge(updated_debate.id)
    end

    %{resource_id: resource_id, debate_id: debate.id, message_count: updated_debate.message_count}
  end

  defp infer_resource_type(id) do
    cond do
      String.starts_with?(id, "ADR-") -> "adr"
      String.starts_with?(id, "FAIL-") -> "failure"
      String.starts_with?(id, "MEET-") -> "meeting"
      String.starts_with?(id, "SNAP-") -> "snapshot"
      true -> "adr"
    end
  end
end

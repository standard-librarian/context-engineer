defmodule ContextEngineering.Workers.JudgeWorker do
  @moduledoc """
  Background worker for judging debates.
  Triggered when a debate reaches 3 messages or manually via API.
  """

  use GenServer

  alias ContextEngineering.Knowledge
  alias ContextEngineering.Services.EmbeddingService

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def trigger_judge(debate_id) do
    GenServer.cast(__MODULE__, {:judge, debate_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:judge, debate_id}, state) do
    case Knowledge.get_debate_with_resource(debate_id) do
      {:ok, debate} ->
        if debate.status == "open" do
          judge_debate(debate)
        end

      {:error, _} ->
        :ok
    end

    {:noreply, state}
  end

  defp judge_debate(debate) do
    resource_content = extract_resource_content(debate.resource, debate.resource_type)
    messages = format_messages(debate.messages)

    prompt =
      build_judge_prompt(debate.resource_type, debate.resource_id, resource_content, messages)

    judgment = generate_judgment(prompt)

    Knowledge.create_judgment(debate.id, %{
      "judge_agent_id" => "judge-worker",
      "score" => judgment.score,
      "accuracy_score" => judgment.accuracy_score,
      "relevance_score" => judgment.relevance_score,
      "completeness_score" => judgment.completeness_score,
      "clarity_score" => judgment.clarity_score,
      "confidence" => judgment.confidence,
      "summary" => judgment.summary,
      "suggested_action" => judgment.suggested_action,
      "action_reason" => judgment.action_reason
    })
  end

  defp extract_resource_content(nil, _type), do: "Resource not found"

  defp extract_resource_content(resource, "adr") do
    "Title: #{resource.title}\nDecision: #{resource.decision}\nContext: #{resource.context || "N/A"}"
  end

  defp extract_resource_content(resource, "failure") do
    "Title: #{resource.title}\nRoot Cause: #{resource.root_cause}\nResolution: #{resource.resolution || "N/A"}"
  end

  defp extract_resource_content(resource, "meeting") do
    "Title: #{resource.meeting_title}\nDecisions: #{Jason.encode!(resource.decisions)}"
  end

  defp extract_resource_content(resource, "snapshot") do
    "Message: #{resource.message}\nCommit: #{resource.commit_hash}"
  end

  defp extract_resource_content(resource, _type) do
    inspect(resource)
  end

  defp format_messages(messages) do
    messages
    |> Enum.sort_by(& &1.inserted_at, {:asc, NaiveDateTime})
    |> Enum.map(fn msg ->
      "[#{String.upcase(msg.stance)}] #{msg.contributor_type}: #{msg.argument}"
    end)
    |> Enum.join("\n\n")
  end

  defp build_judge_prompt(resource_type, resource_id, resource_content, messages) do
    """
    You are a judge evaluating a debate about a #{resource_type}.

    RESOURCE:
    ID: #{resource_id}
    #{resource_content}

    DEBATE MESSAGES:
    #{messages}

    Evaluate this resource based on the debate. Respond with JSON only:
    {
      "score": <1-5>,
      "accuracy_score": <1-5>,
      "relevance_score": <1-5>,
      "completeness_score": <1-5>,
      "clarity_score": <1-5>,
      "confidence": <0.0-1.0>,
      "summary": "<2-3 sentence summary of the debate>",
      "suggested_action": "<none|review|update|deprecate>",
      "action_reason": "<why this action is suggested>"
    }
    """
  end

  defp generate_judgment(prompt) do
    {:ok, _embedding} = EmbeddingService.generate_embedding(prompt)

    default_judgment = %{
      score: 3,
      accuracy_score: 3,
      relevance_score: 3,
      completeness_score: 3,
      clarity_score: 3,
      confidence: 0.5,
      summary: "Auto-generated judgment based on debate content.",
      suggested_action: "review",
      action_reason: "Debate exists for this resource - human review recommended."
    }

    agree_count =
      prompt
      |> String.split("[AGREE]")
      |> length()
      |> Kernel.-(1)

    disagree_count =
      prompt
      |> String.split("[DISAGREE]")
      |> length()
      |> Kernel.-(1)

    total = agree_count + disagree_count

    if total > 0 do
      agree_ratio = agree_count / total

      score =
        cond do
          agree_ratio >= 0.8 -> 5
          agree_ratio >= 0.6 -> 4
          agree_ratio >= 0.4 -> 3
          agree_ratio >= 0.2 -> 2
          true -> 1
        end

      action =
        cond do
          agree_ratio >= 0.7 -> "none"
          agree_ratio >= 0.4 -> "review"
          true -> "update"
        end

      %{default_judgment | score: score, suggested_action: action}
    else
      default_judgment
    end
  end
end

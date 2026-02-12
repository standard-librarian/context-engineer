defmodule Mix.Tasks.Context.Meeting do
  @moduledoc """
  Creates a new meeting record from the command line.

  ## Usage

      mix context.meeting --title "Title" --decisions '{"items":[...]}' [--attendees "a,b"] [--tags "a,b"]

  Auto-generates ID and tags if not provided.
  """
  @shortdoc "Create a meeting record"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [title: :string, decisions: :string, attendees: :string, tags: :string]
      )

    title = opts[:title] || Mix.raise("--title is required")
    decisions_str = opts[:decisions] || Mix.raise("--decisions is required")

    decisions =
      case Jason.decode(decisions_str) do
        {:ok, decoded} -> decoded
        {:error, _} -> %{"items" => [%{"decision" => decisions_str}]}
      end

    alias ContextEngineering.Knowledge

    id = Knowledge.next_id("meeting")

    params = %{
      "id" => id,
      "meeting_title" => title,
      "date" => Date.to_iso8601(Date.utc_today()),
      "decisions" => decisions
    }

    params =
      case opts[:attendees] do
        nil -> params
        att -> Map.put(params, "attendees", String.split(att, ",", trim: true))
      end

    params =
      case opts[:tags] do
        nil -> params
        tags_str -> Map.put(params, "tags", String.split(tags_str, ",", trim: true))
      end

    case Knowledge.create_meeting(params) do
      {:ok, meeting} ->
        Mix.shell().info("Created #{meeting.id}: #{meeting.meeting_title}")
        Mix.shell().info("  Tags: #{Enum.join(meeting.tags || [], ", ")}")

      {:error, changeset} ->
        errors = Knowledge.format_errors(changeset)
        Mix.shell().error("Failed to create meeting: #{inspect(errors)}")
    end
  end
end

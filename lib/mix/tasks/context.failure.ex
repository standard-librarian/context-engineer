defmodule Mix.Tasks.Context.Failure do
  @moduledoc """
  Creates a new failure incident from the command line.

  ## Usage

      mix context.failure --title "Title" --root_cause "Cause" [--severity high] [--tags "a,b"]

  Auto-generates ID and tags if not provided.
  """
  @shortdoc "Create a failure incident"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [title: :string, root_cause: :string, severity: :string, tags: :string,
                 symptoms: :string, impact: :string, resolution: :string]
      )

    title = opts[:title] || Mix.raise("--title is required")
    root_cause = opts[:root_cause] || Mix.raise("--root_cause is required")

    alias ContextEngineering.Knowledge

    id = Knowledge.next_id("failure")

    params = %{
      "id" => id,
      "title" => title,
      "root_cause" => root_cause,
      "severity" => opts[:severity] || "medium",
      "incident_date" => Date.to_iso8601(Date.utc_today()),
      "symptoms" => opts[:symptoms],
      "impact" => opts[:impact],
      "resolution" => opts[:resolution]
    }

    params =
      case opts[:tags] do
        nil -> params
        tags_str -> Map.put(params, "tags", String.split(tags_str, ",", trim: true))
      end

    case Knowledge.create_failure(params) do
      {:ok, failure} ->
        Mix.shell().info("Created #{failure.id}: #{failure.title}")
        Mix.shell().info("  Severity: #{failure.severity}")
        Mix.shell().info("  Tags: #{Enum.join(failure.tags || [], ", ")}")

      {:error, changeset} ->
        errors = Knowledge.format_errors(changeset)
        Mix.shell().error("Failed to create failure: #{inspect(errors)}")
    end
  end
end

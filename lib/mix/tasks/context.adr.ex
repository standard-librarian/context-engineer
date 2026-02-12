defmodule Mix.Tasks.Context.Adr do
  @moduledoc """
  Creates a new ADR from the command line.

  ## Usage

      mix context.adr --title "Title" --decision "Decision" [--context "..."] [--tags "a,b"]

  Auto-generates ID and tags if not provided.
  """
  @shortdoc "Create an ADR"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [title: :string, decision: :string, context: :string, tags: :string]
      )

    title = opts[:title] || Mix.raise("--title is required")
    decision = opts[:decision] || Mix.raise("--decision is required")

    alias ContextEngineering.Knowledge

    id = Knowledge.next_id("adr")

    params = %{
      "id" => id,
      "title" => title,
      "decision" => decision,
      "context" => opts[:context],
      "created_date" => Date.to_iso8601(Date.utc_today())
    }

    params =
      case opts[:tags] do
        nil -> params
        tags_str -> Map.put(params, "tags", String.split(tags_str, ",", trim: true))
      end

    case Knowledge.create_adr(params) do
      {:ok, adr} ->
        Mix.shell().info("Created ADR #{adr.id}: #{adr.title}")
        Mix.shell().info("  Tags: #{Enum.join(adr.tags || [], ", ")}")
        Mix.shell().info("  Status: #{adr.status}")

      {:error, changeset} ->
        errors = Knowledge.format_errors(changeset)
        Mix.shell().error("Failed to create ADR: #{inspect(errors)}")
    end
  end
end

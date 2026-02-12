defmodule Mix.Tasks.Context.Query do
  @moduledoc """
  Queries the context engine and prints bundled results.

  ## Usage

      mix context.query "search terms" [--max_tokens 4000] [--domains "d1,d2"]
  """
  @shortdoc "Query the context engine"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, _} =
      OptionParser.parse(args,
        strict: [max_tokens: :integer, domains: :string]
      )

    query_text =
      case positional do
        [text | _] -> text
        [] -> Mix.raise("Usage: mix context.query \"search terms\"")
      end

    max_tokens = opts[:max_tokens] || 4000

    domains =
      case opts[:domains] do
        nil -> []
        d -> String.split(d, ",", trim: true)
      end

    alias ContextEngineering.Services.BundlerService

    {:ok, bundle} =
      BundlerService.bundle_context(query_text, max_tokens: max_tokens, domains: domains)

    Mix.shell().info("=== Context Bundle (#{bundle.total_items} items) ===\n")

    if length(bundle.key_decisions) > 0 do
      Mix.shell().info("--- Key Decisions ---")

      Enum.each(bundle.key_decisions, fn item ->
        Mix.shell().info("  [#{item.id}] #{item.title}")
        Mix.shell().info("    #{String.slice(item[:content] || "", 0, 120)}")
      end)

      Mix.shell().info("")
    end

    if length(bundle.known_issues) > 0 do
      Mix.shell().info("--- Known Issues ---")

      Enum.each(bundle.known_issues, fn item ->
        Mix.shell().info("  [#{item.id}] #{item.title}")
        Mix.shell().info("    #{String.slice(item[:content] || "", 0, 120)}")
      end)

      Mix.shell().info("")
    end

    if length(bundle.recent_changes) > 0 do
      Mix.shell().info("--- Recent Changes ---")

      Enum.each(bundle.recent_changes, fn item ->
        Mix.shell().info("  [#{item.id}] #{item.title}")
      end)

      Mix.shell().info("")
    end

    if bundle.total_items == 0 do
      Mix.shell().info("No results found.")
    end
  end
end

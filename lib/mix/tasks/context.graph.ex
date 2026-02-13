defmodule Mix.Tasks.Context.Graph do
  @moduledoc """
  Visualizes the knowledge graph or exports graph data.

  ## Usage

      # Display graph statistics
      mix context.graph

      # Export graph as JSON
      mix context.graph --export graph.json

      # Export including archived items
      mix context.graph --export graph.json --include-archived

      # Open web visualization in browser
      mix context.graph --web

  ## Examples

      $ mix context.graph
      Knowledge Graph Statistics:
      Nodes: 42 (ADRs: 15, Failures: 18, Meetings: 7, Snapshots: 2)
      Edges: 67 relationships

      $ mix context.graph --export graph.json
      Exported graph to graph.json (42 nodes, 67 edges)

  """
  use Mix.Task

  alias ContextEngineering.Contexts.Relationships.Graph

  @shortdoc "Visualize or export the knowledge graph"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _args, _invalid} =
      OptionParser.parse(args,
        strict: [
          export: :string,
          include_archived: :boolean,
          web: :boolean,
          max_nodes: :integer
        ]
      )

    cond do
      opts[:web] ->
        open_web_visualization()

      opts[:export] ->
        export_graph(opts)

      true ->
        display_stats(opts)
    end
  end

  defp display_stats(opts) do
    include_archived = Keyword.get(opts, :include_archived, false)
    max_nodes = Keyword.get(opts, :max_nodes, 1000)

    {:ok, graph_data} =
      Graph.export_graph(
        include_archived: include_archived,
        max_nodes: max_nodes
      )

    nodes = graph_data.nodes
    edges = graph_data.edges

    type_counts =
      Enum.reduce(nodes, %{}, fn node, acc ->
        Map.update(acc, node.type, 1, &(&1 + 1))
      end)

    IO.puts("\nKnowledge Graph Statistics:")
    IO.puts("---------------------------")
    IO.puts("Total Nodes: #{length(nodes)}")
    IO.puts("  - ADRs: #{Map.get(type_counts, "adr", 0)}")
    IO.puts("  - Failures: #{Map.get(type_counts, "failure", 0)}")
    IO.puts("  - Meetings: #{Map.get(type_counts, "meeting", 0)}")
    IO.puts("  - Snapshots: #{Map.get(type_counts, "snapshot", 0)}")
    IO.puts("\nTotal Edges: #{length(edges)}")

    if length(edges) > 0 do
      relationship_types =
        Enum.reduce(edges, %{}, fn edge, acc ->
          Map.update(acc, edge.type, 1, &(&1 + 1))
        end)

      IO.puts("\nRelationship Types:")

      Enum.each(relationship_types, fn {type, count} ->
        IO.puts("  - #{type}: #{count}")
      end)
    end

    # Find most connected nodes
    most_connected =
      nodes
      |> Enum.sort_by(& &1.reference_count, :desc)
      |> Enum.take(5)
      |> Enum.filter(&(&1.reference_count > 0))

    if length(most_connected) > 0 do
      IO.puts("\nMost Referenced Items:")

      Enum.each(most_connected, fn node ->
        IO.puts("  - #{node.id}: #{node.title} (#{node.reference_count} references)")
      end)
    end

    IO.puts("\nTo visualize the graph:")
    IO.puts("  1. Start the server: mix phx.server")
    IO.puts("  2. Open browser: http://localhost:4000/graph")
    IO.puts("\nTo export as JSON:")
    IO.puts("  mix context.graph --export graph.json")
    IO.puts("")
  end

  defp export_graph(opts) do
    filename = opts[:export]
    include_archived = Keyword.get(opts, :include_archived, false)
    max_nodes = Keyword.get(opts, :max_nodes, 1000)

    {:ok, graph_data} =
      Graph.export_graph(
        include_archived: include_archived,
        max_nodes: max_nodes
      )

    json = Jason.encode!(graph_data, pretty: true)
    File.write!(filename, json)

    IO.puts("\nGraph exported successfully!")
    IO.puts("File: #{filename}")
    IO.puts("Nodes: #{length(graph_data.nodes)}")
    IO.puts("Edges: #{length(graph_data.edges)}")
    IO.puts("")
  end

  defp open_web_visualization do
    IO.puts("\nStarting server for graph visualization...")
    IO.puts("Opening browser to http://localhost:4000/graph")
    IO.puts("\nPress Ctrl+C twice to stop the server.\n")

    Task.start(fn ->
      Process.sleep(1000)
      open_browser()
    end)

    # Start the Phoenix server (blocks)
    Mix.Task.run("phx.server")
  end

  defp open_browser do
    case :os.type() do
      {:unix, :darwin} ->
        System.cmd("open", ["http://localhost:4000/graph"])

      {:unix, _} ->
        System.cmd("xdg-open", ["http://localhost:4000/graph"])

      {:win32, _} ->
        System.cmd("cmd", ["/c", "start", "http://localhost:4000/graph"])

      _ ->
        IO.puts("Please open http://localhost:4000/graph in your browser")
    end
  end
end

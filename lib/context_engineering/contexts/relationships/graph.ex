defmodule ContextEngineering.Contexts.Relationships.Graph do
  @moduledoc """
  Graph traversal and relationship queries.
  """

  import Ecto.Query
  alias ContextEngineering.Repo
  alias ContextEngineering.Contexts.Relationships.Relationship

  @doc """
  Find all items related to a given item via BFS traversal.
  """
  def find_related(item_id, item_type, opts \\ []) do
    depth = Keyword.get(opts, :depth, 2)
    traverse(item_id, item_type, depth, MapSet.new(), [])
  end

  defp traverse(_id, _type, 0, _visited, acc), do: acc

  defp traverse(id, type, depth, visited, acc) do
    if MapSet.member?(visited, {id, type}) do
      acc
    else
      relationships = get_direct_relationships(id, type)
      visited = MapSet.put(visited, {id, type})

      related_items =
        Enum.map(relationships, fn rel ->
          %{
            id: rel.to_id,
            type: rel.to_type,
            relationship: rel.relationship_type,
            strength: rel.strength
          }
        end)

      new_acc = acc ++ related_items

      Enum.reduce(related_items, new_acc, fn item, inner_acc ->
        traverse(item.id, item.type, depth - 1, visited, inner_acc)
      end)
    end
  end

  defp get_direct_relationships(id, type) do
    from(r in Relationship,
      where: r.from_id == ^id and r.from_type == ^type
    )
    |> Repo.all()
  end

  @doc """
  Create a relationship between two items.
  """
  def create_relationship(from_id, from_type, to_id, to_type, rel_type, strength \\ 1.0) do
    %Relationship{}
    |> Relationship.changeset(%{
      from_id: from_id,
      from_type: from_type,
      to_id: to_id,
      to_type: to_type,
      relationship_type: rel_type,
      strength: strength
    })
    |> Repo.insert()
  end

  @doc """
  Auto-discover relationships based on ID references in content.
  Extracts patterns like ADR-001, FAIL-042, MEET-012.
  """
  def auto_link_item(item_id, item_type, content) do
    adr_ids = Regex.scan(~r/ADR-\d+/, content) |> Enum.map(&List.first/1)
    fail_ids = Regex.scan(~r/FAIL-\d+/, content) |> Enum.map(&List.first/1)
    meet_ids = Regex.scan(~r/MEET-\d+/, content) |> Enum.map(&List.first/1)
    snap_ids = Regex.scan(~r/SNAP-\d+/, content) |> Enum.map(&List.first/1)

    for id <- adr_ids, id != item_id do
      create_relationship(item_id, item_type, id, "adr", "references")
    end

    for id <- fail_ids, id != item_id do
      create_relationship(item_id, item_type, id, "failure", "references")
    end

    for id <- meet_ids, id != item_id do
      create_relationship(item_id, item_type, id, "meeting", "references")
    end

    for id <- snap_ids, id != item_id do
      create_relationship(item_id, item_type, id, "snapshot", "references")
    end

    :ok
  end

  @doc """
  Export the entire knowledge graph for visualization.

  Returns a map with:
  - `:nodes` - List of all knowledge items (ADRs, Failures, Meetings, Snapshots)
  - `:edges` - List of all relationships between items

  ## Options

    - `:include_archived` - Include archived items (default: false)
    - `:max_nodes` - Maximum nodes to return (default: 1000)

  ## Returns

    - `{:ok, %{nodes: [...], edges: [...]}}`

  ## Examples

      iex> Graph.export_graph()
      {:ok, %{
        nodes: [
          %{id: "ADR-001", type: "adr", title: "Use PostgreSQL", ...},
          %{id: "FAIL-023", type: "failure", title: "DB timeout", ...}
        ],
        edges: [
          %{from: "ADR-001", to: "FAIL-023", type: "references", strength: 1.0}
        ]
      }}

  """
  def export_graph(opts \\ []) do
    include_archived = Keyword.get(opts, :include_archived, false)
    max_nodes = Keyword.get(opts, :max_nodes, 1000)

    nodes = collect_all_nodes(include_archived, max_nodes)
    edges = collect_all_edges()

    {:ok, %{nodes: nodes, edges: edges}}
  end

  defp collect_all_nodes(include_archived, max_nodes) do
    alias ContextEngineering.Contexts.ADRs.ADR
    alias ContextEngineering.Contexts.Failures.Failure
    alias ContextEngineering.Contexts.Meetings.Meeting
    alias ContextEngineering.Contexts.Snapshots.Snapshot

    adrs =
      if include_archived do
        from(a in ADR, limit: ^div(max_nodes, 4))
      else
        from(a in ADR, where: a.status != "archived", limit: ^div(max_nodes, 4))
      end
      |> Repo.all()
      |> Enum.map(fn a ->
        %{
          id: a.id,
          type: "adr",
          title: a.title,
          status: a.status,
          tags: a.tags || [],
          created_date: a.created_date,
          reference_count: a.reference_count || 0
        }
      end)

    failures =
      if include_archived do
        from(f in Failure, limit: ^div(max_nodes, 4))
      else
        from(f in Failure, where: f.status != "archived", limit: ^div(max_nodes, 4))
      end
      |> Repo.all()
      |> Enum.map(fn f ->
        %{
          id: f.id,
          type: "failure",
          title: f.title,
          severity: f.severity,
          status: f.status,
          tags: f.tags || [],
          created_date: f.incident_date,
          reference_count: f.reference_count || 0
        }
      end)

    meetings =
      if include_archived do
        from(m in Meeting, limit: ^div(max_nodes, 4))
      else
        from(m in Meeting, where: m.status == "active", limit: ^div(max_nodes, 4))
      end
      |> Repo.all()
      |> Enum.map(fn m ->
        %{
          id: m.id,
          type: "meeting",
          title: m.meeting_title,
          status: m.status,
          tags: m.tags || [],
          created_date: m.date,
          reference_count: 0
        }
      end)

    snapshots =
      if include_archived do
        from(s in Snapshot, limit: ^div(max_nodes, 4))
      else
        from(s in Snapshot, where: s.status == "active", limit: ^div(max_nodes, 4))
      end
      |> Repo.all()
      |> Enum.map(fn s ->
        %{
          id: s.id,
          type: "snapshot",
          title: s.message,
          status: s.status,
          tags: s.tags || [],
          created_date: s.date,
          reference_count: 0
        }
      end)

    adrs ++ failures ++ meetings ++ snapshots
  end

  defp collect_all_edges do
    from(r in Relationship)
    |> Repo.all()
    |> Enum.map(fn r ->
      %{
        from: r.from_id,
        from_type: r.from_type,
        to: r.to_id,
        to_type: r.to_type,
        type: r.relationship_type,
        strength: r.strength
      }
    end)
  end
end

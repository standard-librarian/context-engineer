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
end

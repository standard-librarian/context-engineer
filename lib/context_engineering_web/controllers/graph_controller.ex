defmodule ContextEngineeringWeb.GraphController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Contexts.Relationships.Graph

  def related(conn, %{"id" => id} = params) do
    type = Map.get(params, "type", "adr")
    depth = Map.get(params, "depth", "2") |> String.to_integer()

    related = Graph.find_related(id, type, depth: depth)
    json(conn, %{item_id: id, related: related})
  end
end

defmodule ContextEngineeringWeb.ADRController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Knowledge
  alias ContextEngineering.Contexts.Relationships.Graph

  def create(conn, %{"adr" => adr_params}) do
    case Knowledge.create_adr(adr_params) do
      {:ok, adr} ->
        conn
        |> put_status(:created)
        |> json(%{id: adr.id, status: "created"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    case Knowledge.get_adr(id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "ADR not found"})

      {:ok, adr} ->
        related = Graph.find_related(id, "adr", depth: 1)

        json(conn, %{
          adr: serialize_adr(adr),
          related_items: related
        })
    end
  end

  def index(conn, params) do
    adrs =
      Knowledge.list_adrs(params)
      |> Enum.map(&serialize_adr/1)

    json(conn, adrs)
  end

  def update(conn, %{"id" => id, "adr" => adr_params}) do
    case Knowledge.update_adr(id, adr_params) do
      {:ok, updated_adr} ->
        json(conn, %{id: updated_adr.id, status: "updated"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "ADR not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})
    end
  end

  defp serialize_adr(adr) do
    %{
      id: adr.id,
      title: adr.title,
      decision: adr.decision,
      context: adr.context,
      options_considered: adr.options_considered,
      outcome: adr.outcome,
      status: adr.status,
      created_date: adr.created_date,
      supersedes: adr.supersedes,
      superseded_by: adr.superseded_by,
      tags: adr.tags,
      author: adr.author,
      stakeholders: adr.stakeholders,
      access_count_30d: adr.access_count_30d,
      reference_count: adr.reference_count,
      inserted_at: adr.inserted_at,
      updated_at: adr.updated_at
    }
  end
end

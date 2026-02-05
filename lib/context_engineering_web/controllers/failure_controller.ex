defmodule ContextEngineeringWeb.FailureController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Knowledge
  alias ContextEngineering.Contexts.Relationships.Graph

  def create(conn, %{"failure" => failure_params}) do
    case Knowledge.create_failure(failure_params) do
      {:ok, failure} ->
        conn
        |> put_status(:created)
        |> json(%{id: failure.id, status: "created"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    case Knowledge.get_failure(id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Failure not found"})

      {:ok, failure} ->
        related = Graph.find_related(id, "failure", depth: 1)

        json(conn, %{
          failure: serialize_failure(failure),
          related_items: related
        })
    end
  end

  def index(conn, params) do
    failures =
      Knowledge.list_failures(params)
      |> Enum.map(&serialize_failure/1)

    json(conn, failures)
  end

  def update(conn, %{"id" => id, "failure" => failure_params}) do
    case Knowledge.update_failure(id, failure_params) do
      {:ok, updated_failure} ->
        json(conn, %{id: updated_failure.id, status: "updated"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Failure not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})
    end
  end

  defp serialize_failure(failure) do
    %{
      id: failure.id,
      title: failure.title,
      incident_date: failure.incident_date,
      severity: failure.severity,
      root_cause: failure.root_cause,
      symptoms: failure.symptoms,
      impact: failure.impact,
      resolution: failure.resolution,
      prevention: failure.prevention,
      status: failure.status,
      pattern: failure.pattern,
      tags: failure.tags,
      lessons_learned: failure.lessons_learned,
      author: failure.author,
      access_count_30d: failure.access_count_30d,
      reference_count: failure.reference_count,
      inserted_at: failure.inserted_at,
      updated_at: failure.updated_at
    }
  end
end

defmodule ContextEngineeringWeb.ContextController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Services.BundlerService
  alias ContextEngineering.Knowledge
  import Ecto.Query
  alias ContextEngineering.Repo
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Contexts.Meetings.Meeting

  def query(conn, %{"query" => query_text} = params) do
    max_tokens = Map.get(params, "max_tokens", 4000)
    domains = Map.get(params, "domains", [])

    {:ok, bundle} =
      BundlerService.bundle_context(query_text, max_tokens: max_tokens, domains: domains)

    json(conn, bundle)
  end

  def domain(conn, %{"name" => domain_name}) do
    adrs =
      from(a in ADR, where: ^domain_name in a.tags, where: a.status == "active")
      |> Repo.all()

    failures =
      from(f in Failure, where: ^domain_name in f.tags, where: f.status != "archived")
      |> Repo.all()

    json(conn, %{domain: domain_name, adrs: adrs, failures: failures})
  end

  def recent(conn, params) do
    limit = Map.get(params, "limit", "10") |> String.to_integer()

    adrs =
      from(a in ADR, where: a.status == "active", order_by: [desc: a.created_date], limit: ^limit)
      |> Repo.all()

    failures =
      from(f in Failure,
        where: f.status != "archived",
        order_by: [desc: f.incident_date],
        limit: ^limit
      )
      |> Repo.all()

    meetings =
      from(m in Meeting, where: m.status != "archived", order_by: [desc: m.date], limit: ^limit)
      |> Repo.all()

    json(conn, %{adrs: adrs, failures: failures, meetings: meetings})
  end

  def timeline(conn, params) do
    with {:ok, from_date} <- parse_date(params["from"]),
         {:ok, to_date} <- parse_date(params["to"]) do
      items = Knowledge.timeline(from_date, to_date)
      json(conn, %{items: items, count: length(items)})
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def snapshot(conn, params) do
    case Knowledge.create_snapshot(params) do
      {:ok, snapshot} ->
        conn
        |> put_status(:created)
        |> json(%{id: snapshot.id, status: "created", type: "git_snapshot"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})
    end
  end

  defp parse_date(nil), do: {:error, "Missing date parameter. Use ?from=YYYY-MM-DD&to=YYYY-MM-DD"}

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, "Invalid date format: #{date_string}. Use YYYY-MM-DD"}
    end
  end
end

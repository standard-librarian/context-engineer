defmodule ContextEngineering.Workers.DecayWorker do
  @moduledoc """
  Background worker to archive old/irrelevant context.
  Runs daily via Quantum scheduler.
  """

  import Ecto.Query
  alias ContextEngineering.Repo
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure

  def run do
    archive_old_adrs()
    archive_old_failures()
  end

  defp archive_old_adrs do
    now = Date.utc_today()

    from(a in ADR, where: a.status == "active")
    |> Repo.all()
    |> Enum.each(fn adr ->
      score = calculate_decay_score(adr, now)

      if score < 30 do
        adr
        |> Ecto.Changeset.change(%{status: "archived"})
        |> Repo.update()
      end
    end)
  end

  defp archive_old_failures do
    now = Date.utc_today()

    from(f in Failure, where: f.status == "resolved")
    |> Repo.all()
    |> Enum.each(fn failure ->
      score = calculate_decay_score(failure, now)

      if score < 30 do
        failure
        |> Ecto.Changeset.change(%{status: "archived"})
        |> Repo.update()
      end
    end)
  end

  defp calculate_decay_score(item, now) do
    age_days = Date.diff(now, item.created_date || item.incident_date)

    score = 100

    # Age penalty
    score =
      score -
        cond do
          age_days > 365 -> 50
          age_days > 180 -> 25
          true -> 0
        end

    # Superseded items go to 0
    score = if Map.get(item, :status) == "superseded", do: 0, else: score

    # Usage boost
    access_count = Map.get(item, :access_count_30d, 0)
    score = if access_count > 10, do: score + 20, else: score

    # Reference boost
    ref_count = Map.get(item, :reference_count, 0)
    score = if ref_count > 5, do: score + 15, else: score

    score
  end
end

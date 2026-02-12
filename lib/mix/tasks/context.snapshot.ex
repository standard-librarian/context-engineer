defmodule Mix.Tasks.Context.Snapshot do
  @moduledoc """
  Creates a git snapshot from the current HEAD commit.

  ## Usage

      mix context.snapshot

  Reads git HEAD commit info and stores it as a Snapshot record.
  """
  @shortdoc "Snapshot current git HEAD"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    alias ContextEngineering.Knowledge

    case read_git_head() do
      {:ok, commit_data} ->
        case Knowledge.create_snapshot(commit_data) do
          {:ok, snapshot} ->
            Mix.shell().info("Snapshot created: #{snapshot.id}")
            Mix.shell().info("  Commit: #{commit_data["commit_hash"]}")
            Mix.shell().info("  Message: #{commit_data["message"]}")
            Mix.shell().info("  Author: #{commit_data["author"]}")

          {:error, changeset} ->
            errors = Knowledge.format_errors(changeset)
            Mix.shell().error("Failed to create snapshot: #{inspect(errors)}")
        end

      {:error, reason} ->
        Mix.shell().error("Git error: #{reason}")
    end
  end

  defp read_git_head do
    with {hash, 0} <- System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true),
         {message, 0} <- System.cmd("git", ["log", "-1", "--pretty=%s"], stderr_to_stdout: true),
         {author, 0} <- System.cmd("git", ["log", "-1", "--pretty=%ae"], stderr_to_stdout: true),
         {date, 0} <- System.cmd("git", ["log", "-1", "--pretty=%ai"], stderr_to_stdout: true) do
      {:ok,
       %{
         "commit_hash" => String.trim(hash),
         "author" => String.trim(author),
         "message" => String.trim(message),
         "date" => date |> String.trim() |> String.slice(0, 10)
       }}
    else
      {error, _} -> {:error, String.trim(error)}
    end
  end
end

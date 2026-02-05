defmodule ContextEngineeringWeb.MeetingController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Knowledge

  def create(conn, %{"meeting" => meeting_params}) do
    case Knowledge.create_meeting(meeting_params) do
      {:ok, meeting} ->
        conn
        |> put_status(:created)
        |> json(%{id: meeting.id, status: "created"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    case Knowledge.get_meeting(id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Meeting not found"})

      {:ok, meeting} ->
        json(conn, %{meeting: serialize_meeting(meeting)})
    end
  end

  def index(conn, params) do
    meetings =
      Knowledge.list_meetings(params)
      |> Enum.map(&serialize_meeting/1)

    json(conn, meetings)
  end

  def update(conn, %{"id" => id, "meeting" => meeting_params}) do
    case Knowledge.update_meeting(id, meeting_params) do
      {:ok, updated_meeting} ->
        json(conn, %{id: updated_meeting.id, status: "updated"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Meeting not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Knowledge.format_errors(changeset)})
    end
  end

  defp serialize_meeting(meeting) do
    %{
      id: meeting.id,
      meeting_title: meeting.meeting_title,
      date: meeting.date,
      decisions: meeting.decisions,
      attendees: meeting.attendees,
      tags: meeting.tags,
      status: meeting.status,
      access_count_30d: meeting.access_count_30d,
      inserted_at: meeting.inserted_at,
      updated_at: meeting.updated_at
    }
  end
end

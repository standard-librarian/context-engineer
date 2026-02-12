defmodule ContextEngineering.Events.LogParser do
  @moduledoc """
  Parses structured log entries and extracts error events.
  Accepts logs from any application via Fluentd, Logstash, or direct POST.
  """

  alias ContextEngineering.Events.EventProcessor

  @error_levels ["ERROR", "CRITICAL", "FATAL", "PANIC", "error", "critical", "fatal", "panic"]

  @doc """
  Process a batch of log entries. Filters for error-level logs and converts them to failure records.

  Each log entry is expected to have at minimum:
    - "level" — log level string
    - "message" — log message body

  Optional fields: "app" or "app_name", "timestamp", "service"
  """
  def process_batch(logs) when is_list(logs) do
    logs
    |> Enum.filter(&error_log?/1)
    |> Enum.map(&process_error_log/1)
  end

  @doc """
  Process a single error log entry into a failure record.
  """
  def process_error_log(log) do
    error_data = %{
      "title" => extract_title(log),
      "stack_trace" => log["message"],
      "app_name" => log["app"] || log["app_name"] || log["service"] || "unknown",
      "timestamp" => log["timestamp"],
      "severity" => map_level_to_severity(log["level"])
    }

    EventProcessor.process_error_event(error_data)
  end

  def error_log?(log) do
    level = log["level"] || ""
    level in @error_levels
  end

  defp extract_title(log) do
    message = log["message"] || ""

    message
    |> String.split("\n")
    |> List.first("")
    |> String.slice(0..120)
  end

  defp map_level_to_severity(level)
       when level in ["CRITICAL", "FATAL", "PANIC", "critical", "fatal", "panic"], do: "critical"

  defp map_level_to_severity(level) when level in ["ERROR", "error"], do: "high"
  defp map_level_to_severity(_), do: "medium"
end

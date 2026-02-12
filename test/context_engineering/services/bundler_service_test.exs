defmodule ContextEngineering.Services.BundlerServiceTest do
  use ContextEngineering.DataCase

  alias ContextEngineering.Services.BundlerService
  alias ContextEngineering.Services.EmbeddingService
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Contexts.Meetings.Meeting
  alias ContextEngineering.Contexts.Relationships.Graph
  alias ContextEngineering.Repo

  setup do
    # Insert test ADR
    {:ok, adr_embedding} =
      EmbeddingService.generate_embedding(
        "Choose PostgreSQL for database. Strong consistency and ACID compliance."
      )

    %ADR{
      id: "ADR-001",
      title: "Choose PostgreSQL over MongoDB",
      decision: "Use PostgreSQL as primary database for all services",
      context: "Need strong consistency, complex queries, and ACID compliance",
      options_considered: %{
        "postgresql" => %{"pros" => "ACID", "cons" => "Migrations"},
        "mongodb" => %{"pros" => "Flexible", "cons" => "Eventual consistency"}
      },
      outcome: "Successfully implemented.",
      status: "active",
      created_date: ~D[2025-06-15],
      tags: ["database", "infrastructure"],
      author: "jane@company.com",
      embedding: adr_embedding
    }
    |> Repo.insert!()

    # Insert test Failure
    {:ok, fail_embedding} =
      EmbeddingService.generate_embedding(
        "Database connection pool exhaustion under load. Pool size insufficient."
      )

    %Failure{
      id: "FAIL-001",
      title: "Database Connection Pool Exhaustion",
      incident_date: ~D[2025-11-03],
      severity: "high",
      root_cause: "Connection pool size insufficient for peak load",
      symptoms: "API response times increased to 30s",
      impact: "15% of users affected for 2 hours",
      resolution: "Increased pool size to 200",
      prevention: ["Added monitoring"],
      status: "resolved",
      pattern: "resource_exhaustion",
      tags: ["database", "performance"],
      author: "oncall@company.com",
      embedding: fail_embedding
    }
    |> Repo.insert!()

    # Insert test Meeting
    {:ok, meet_embedding} =
      EmbeddingService.generate_embedding(
        "Post-mortem discussion about database connection pool failure"
      )

    %Meeting{
      id: "MEET-001",
      meeting_title: "Incident Post-Mortem",
      date: ~D[2025-12-15],
      decisions: %{"items" => [%{"decision" => "Add connection pool monitoring"}]},
      attendees: ["oncall@company.com"],
      tags: ["incident", "database"],
      status: "active",
      embedding: meet_embedding
    }
    |> Repo.insert!()

    # Create relationships
    Graph.create_relationship("FAIL-001", "failure", "ADR-001", "adr", "caused_by")
    Graph.create_relationship("MEET-001", "meeting", "FAIL-001", "failure", "references")

    :ok
  end

  test "bundles relevant context for database performance query" do
    {:ok, bundle} = BundlerService.bundle_context("database performance issues")

    assert length(bundle.key_decisions) > 0
    assert length(bundle.known_issues) > 0
    assert bundle.total_items > 0

    # Should find the PostgreSQL ADR
    assert Enum.any?(bundle.key_decisions, fn item ->
             String.contains?(item.title || "", "PostgreSQL")
           end)

    # Should find the connection pool failure
    assert Enum.any?(bundle.known_issues, fn item ->
             String.contains?(item.title || "", "Connection Pool")
           end)
  end

  test "respects domain filtering" do
    {:ok, bundle} =
      BundlerService.bundle_context("database issues", domains: ["nonexistent-domain"])

    assert bundle.total_items == 0
  end

  test "returns structured bundle with all sections" do
    {:ok, bundle} = BundlerService.bundle_context("any query")

    assert Map.has_key?(bundle, :key_decisions)
    assert Map.has_key?(bundle, :known_issues)
    assert Map.has_key?(bundle, :recent_changes)
    assert Map.has_key?(bundle, :total_items)
    assert is_list(bundle.key_decisions)
    assert is_list(bundle.known_issues)
    assert is_list(bundle.recent_changes)
    assert is_integer(bundle.total_items)
  end
end

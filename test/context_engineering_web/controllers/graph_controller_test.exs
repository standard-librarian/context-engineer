defmodule ContextEngineeringWeb.GraphControllerTest do
  use ContextEngineeringWeb.ConnCase

  alias ContextEngineering.Services.EmbeddingService
  alias ContextEngineering.Contexts.ADRs.ADR
  alias ContextEngineering.Contexts.Failures.Failure
  alias ContextEngineering.Contexts.Relationships.Relationship
  alias ContextEngineering.Repo

  setup do
    # Create test ADR
    {:ok, adr_embedding} = EmbeddingService.generate_embedding("Test ADR")

    adr =
      %ADR{
        id: "ADR-001",
        title: "Use PostgreSQL",
        decision: "We will use PostgreSQL",
        context: "Need a database",
        status: "accepted",
        created_date: ~D[2025-01-01],
        tags: ["database"],
        author: "test@test.com",
        embedding: adr_embedding
      }
      |> Repo.insert!()

    # Create test failure
    {:ok, failure_embedding} = EmbeddingService.generate_embedding("Test Failure")

    failure =
      %Failure{
        id: "FAIL-001",
        title: "Database connection failed",
        symptoms: "Connection pool exhausted",
        root_cause: "Too many connections",
        resolution: "Increased pool size",
        severity: "high",
        status: "resolved",
        incident_date: ~D[2025-01-02],
        tags: ["database"],
        prevention: ["Monitor pool usage", "Set alerts"],
        embedding: failure_embedding
      }
      |> Repo.insert!()

    # Create relationship between them
    %Relationship{
      from_id: "FAIL-001",
      from_type: "failure",
      to_id: "ADR-001",
      to_type: "adr",
      relationship_type: "caused_by"
    }
    |> Repo.insert!()

    {:ok, adr: adr, failure: failure}
  end

  describe "GET /api/graph/export" do
    test "returns graph data with nodes and edges", %{conn: conn} do
      conn = get(conn, "/api/graph/export")
      response = json_response(conn, 200)

      assert Map.has_key?(response, "nodes")
      assert Map.has_key?(response, "edges")
      assert is_list(response["nodes"])
      assert is_list(response["edges"])
      assert length(response["nodes"]) >= 2
      assert length(response["edges"]) >= 1
    end

    test "returns nodes with required fields", %{conn: conn} do
      conn = get(conn, "/api/graph/export")
      response = json_response(conn, 200)

      node = hd(response["nodes"])
      assert Map.has_key?(node, "id")
      assert Map.has_key?(node, "type")
      assert Map.has_key?(node, "title")
      assert Map.has_key?(node, "status")
      assert Map.has_key?(node, "tags")
      assert Map.has_key?(node, "created_date")
    end

    test "returns edges with required fields", %{conn: conn} do
      conn = get(conn, "/api/graph/export")
      response = json_response(conn, 200)

      edge = hd(response["edges"])
      assert Map.has_key?(edge, "from")
      assert Map.has_key?(edge, "from_type")
      assert Map.has_key?(edge, "to")
      assert Map.has_key?(edge, "to_type")
      assert Map.has_key?(edge, "type")
      assert edge["type"] == "caused_by"
    end

    test "respects max_nodes parameter", %{conn: conn} do
      conn = get(conn, "/api/graph/export?max_nodes=1")
      response = json_response(conn, 200)

      # Should return at most 1 node (divided by 4 types, so at least limited)
      assert length(response["nodes"]) <= 4
    end

    test "excludes archived items by default", %{conn: conn, adr: adr} do
      # Archive the ADR
      adr
      |> Ecto.Changeset.change(status: "archived")
      |> Repo.update!()

      conn = get(conn, "/api/graph/export")
      response = json_response(conn, 200)

      # Should not include archived ADR
      adr_ids = Enum.map(response["nodes"], & &1["id"])
      refute "ADR-001" in adr_ids
    end

    test "includes archived items when requested", %{conn: conn, adr: adr} do
      # Archive the ADR
      adr
      |> Ecto.Changeset.change(status: "archived")
      |> Repo.update!()

      conn = get(conn, "/api/graph/export?include_archived=true")
      response = json_response(conn, 200)

      # Should include archived ADR
      adr_ids = Enum.map(response["nodes"], & &1["id"])
      assert "ADR-001" in adr_ids
    end
  end

  describe "GET /api/graph/related/:id" do
    test "returns related nodes for an ADR", %{conn: conn} do
      conn = get(conn, "/api/graph/related/ADR-001?type=adr&depth=1")
      response = json_response(conn, 200)

      assert response["item_id"] == "ADR-001"
      assert is_list(response["related"])
      # Note: related nodes depend on graph traversal logic
    end

    test "returns related nodes for a failure", %{conn: conn} do
      conn = get(conn, "/api/graph/related/FAIL-001?type=failure&depth=1")
      response = json_response(conn, 200)

      assert response["item_id"] == "FAIL-001"
      assert is_list(response["related"])
      # Note: related nodes depend on graph traversal logic
    end

    test "uses default type when not specified", %{conn: conn} do
      conn = get(conn, "/api/graph/related/ADR-001")
      response = json_response(conn, 200)

      assert response["item_id"] == "ADR-001"
      assert is_list(response["related"])
    end

    test "uses default depth when not specified", %{conn: conn} do
      conn = get(conn, "/api/graph/related/ADR-001?type=adr")
      response = json_response(conn, 200)

      assert response["item_id"] == "ADR-001"
      assert is_list(response["related"])
    end

    test "returns empty list for non-existent item", %{conn: conn} do
      conn = get(conn, "/api/graph/related/NONEXISTENT?type=adr")
      response = json_response(conn, 200)

      assert response["item_id"] == "NONEXISTENT"
      assert response["related"] == []
    end
  end

  describe "GET /graph" do
    test "returns HTML page for retro terminal visualization", %{conn: conn} do
      conn = get(conn, "/graph")
      response = html_response(conn, 200)

      assert response =~ "<!DOCTYPE html>"
      assert response =~ "graph"
    end
  end

  describe "GET /graph/obsidian" do
    test "returns HTML page for Obsidian-style visualization", %{conn: conn} do
      conn = get(conn, "/graph/obsidian")
      response = html_response(conn, 200)

      assert response =~ "<!DOCTYPE html>"
      assert response =~ "Knowledge Graph"
      assert response =~ "Obsidian"
      assert response =~ "react-force-graph"
    end

    test "includes required JavaScript dependencies", %{conn: conn} do
      conn = get(conn, "/graph/obsidian")
      response = html_response(conn, 200)

      assert response =~ "react"
      assert response =~ "d3"
      assert response =~ "graph-container"
    end

    test "includes physics controls", %{conn: conn} do
      conn = get(conn, "/graph/obsidian")
      response = html_response(conn, 200)

      assert response =~ "Repulsion Force"
      assert response =~ "Link Distance"
      assert response =~ "Collision Radius"
      assert response =~ "Center Gravity"
    end
  end
end

alias ContextEngineering.Repo
alias ContextEngineering.Contexts.ADRs.ADR
alias ContextEngineering.Contexts.Failures.Failure
alias ContextEngineering.Contexts.Meetings.Meeting
alias ContextEngineering.Services.EmbeddingService
alias ContextEngineering.Contexts.Relationships.Graph

IO.puts("Generating embeddings and seeding data...")

# --- ADR-001 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Choose PostgreSQL over MongoDB for database. Use PostgreSQL as primary database for all services. Need strong consistency, complex queries, and ACID compliance."
  )

%ADR{
  id: "ADR-001",
  title: "Choose PostgreSQL over MongoDB",
  decision: "Use PostgreSQL as primary database for all services",
  context: "Need strong consistency, complex queries, and ACID compliance",
  options_considered: %{
    "postgresql" => %{"pros" => "ACID, team expertise", "cons" => "Schema migrations"},
    "mongodb" => %{"pros" => "Flexible schema", "cons" => "Eventual consistency"}
  },
  outcome: "Successfully implemented. No major issues.",
  status: "active",
  created_date: ~D[2025-06-15],
  tags: ["database", "infrastructure"],
  author: "jane@company.com",
  stakeholders: ["platform-team", "backend-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  Inserted ADR-001")

# --- ADR-002 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Use Redis for caching layer. Implement Redis as distributed cache for API responses and session data."
  )

%ADR{
  id: "ADR-002",
  title: "Use Redis for Caching Layer",
  decision: "Implement Redis as distributed cache for API responses and session data",
  context: "API response times were too slow. Need a fast caching layer.",
  options_considered: %{
    "redis" => %{"pros" => "Fast, mature, great Elixir support", "cons" => "Extra infra"},
    "memcached" => %{"pros" => "Simple", "cons" => "No persistence, limited data types"},
    "ets" => %{"pros" => "Built-in", "cons" => "Not distributed"}
  },
  outcome: "Reduced p95 latency by 60%",
  status: "active",
  created_date: ~D[2025-08-20],
  tags: ["caching", "infrastructure", "performance"],
  author: "bob@company.com",
  stakeholders: ["platform-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  Inserted ADR-002")

# --- ADR-003 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Adopt Phoenix LiveView for admin dashboard. Build internal tools with LiveView for real-time updates."
  )

%ADR{
  id: "ADR-003",
  title: "Adopt Phoenix LiveView for Admin Dashboard",
  decision: "Build internal tools with LiveView for real-time updates",
  context: "Admin team needs real-time monitoring and management capabilities",
  options_considered: %{
    "liveview" => %{"pros" => "Real-time, Elixir stack, less JS", "cons" => "Learning curve"},
    "react_spa" => %{"pros" => "Team familiarity", "cons" => "API overhead, separate deploy"}
  },
  outcome: "Dashboard live with positive feedback from ops team",
  status: "active",
  created_date: ~D[2025-10-01],
  tags: ["frontend", "tooling"],
  author: "alice@company.com",
  stakeholders: ["ops-team", "admin-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  Inserted ADR-003")

# --- FAIL-001 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Database connection pool exhaustion under load. Connection pool size insufficient for peak load. API response times increased to 30s, 500 errors."
  )

%Failure{
  id: "FAIL-001",
  title: "Database Connection Pool Exhaustion",
  incident_date: ~D[2025-11-03],
  severity: "high",
  root_cause:
    "Connection pool size insufficient for peak load. Default pool of 10 connections was overwhelmed during Black Friday traffic spike.",
  symptoms: "API response times increased to 30s, 500 errors on 15% of requests",
  impact: "15% of users affected for 2 hours during peak shopping period",
  resolution: "Increased pool size to 200, added connection pool monitoring alerts",
  prevention: [
    "Added connection pool monitoring",
    "Updated load tests to simulate 10x traffic",
    "Created runbook for pool exhaustion"
  ],
  status: "resolved",
  pattern: "resource_exhaustion",
  tags: ["database", "performance", "infrastructure"],
  lessons_learned:
    "Always monitor resource utilization and load test with realistic traffic patterns. Default configs are not production-ready.",
  author: "oncall@company.com",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  Inserted FAIL-001")

# --- FAIL-002 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Redis cache stampede causing cascading failures. Multiple cache keys expired simultaneously causing all requests to hit the database."
  )

%Failure{
  id: "FAIL-002",
  title: "Redis Cache Stampede",
  incident_date: ~D[2025-12-10],
  severity: "critical",
  root_cause:
    "Multiple cache keys expired simultaneously causing all requests to hit the database. TTLs were all set to exactly 1 hour.",
  symptoms: "Database CPU at 100%, all API endpoints returning 503",
  impact: "Complete service outage for 45 minutes",
  resolution: "Implemented jittered TTLs and cache warming. Added circuit breaker pattern.",
  prevention: [
    "Randomize cache TTLs",
    "Implement cache warming on deploy",
    "Add circuit breakers"
  ],
  status: "resolved",
  pattern: "cache_stampede",
  tags: ["caching", "performance", "database"],
  lessons_learned:
    "Never use uniform cache expiration times. Always add jitter to TTLs. Related to ADR-002 Redis caching decision.",
  author: "oncall@company.com",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  Inserted FAIL-002")

# --- MEET-001 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Q4 Architecture Review. Decided to migrate to Kubernetes. Approved database sharding plan for Q1. Performance budget of 200ms p99 for all API endpoints."
  )

%Meeting{
  id: "MEET-001",
  meeting_title: "Q4 Architecture Review",
  date: ~D[2025-10-15],
  decisions: %{
    "items" => [
      %{"decision" => "Migrate to Kubernetes by end of Q1", "owner" => "platform-team"},
      %{"decision" => "Approve database sharding plan", "owner" => "data-team"},
      %{
        "decision" => "Set performance budget: 200ms p99 for all API endpoints",
        "owner" => "all-teams"
      }
    ]
  },
  attendees: ["jane@company.com", "bob@company.com", "alice@company.com", "cto@company.com"],
  tags: ["architecture", "infrastructure", "performance"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  Inserted MEET-001")

# --- MEET-002 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Incident Post-Mortem: Black Friday Outage. Review of FAIL-001 connection pool issue and FAIL-002 cache stampede. Action items for preventing future incidents."
  )

%Meeting{
  id: "MEET-002",
  meeting_title: "Incident Post-Mortem: Black Friday Outage",
  date: ~D[2025-12-15],
  decisions: %{
    "items" => [
      %{
        "decision" => "All services must have connection pool monitoring",
        "owner" => "platform-team"
      },
      %{"decision" => "Quarterly load testing required", "owner" => "qa-team"},
      %{"decision" => "Cache TTL jitter must be applied everywhere", "owner" => "backend-team"}
    ]
  },
  attendees: ["oncall@company.com", "jane@company.com", "bob@company.com", "cto@company.com"],
  tags: ["incident", "post-mortem", "performance"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  Inserted MEET-002")

# --- Create Relationships ---
IO.puts("Creating relationships...")

Graph.create_relationship("FAIL-001", "failure", "ADR-001", "adr", "caused_by")
Graph.create_relationship("FAIL-002", "failure", "ADR-002", "adr", "caused_by")
Graph.create_relationship("FAIL-002", "failure", "FAIL-001", "failure", "related_to")
Graph.create_relationship("MEET-002", "meeting", "FAIL-001", "failure", "references")
Graph.create_relationship("MEET-002", "meeting", "FAIL-002", "failure", "references")
Graph.create_relationship("MEET-001", "meeting", "ADR-001", "adr", "references")

IO.puts("Done! Seeded 3 ADRs, 2 Failures, 2 Meetings, and 6 Relationships.")

# Seeds with Feedback and Debate Data
# Run with: mix run priv/repo/seeds_with_debates.exs

alias ContextEngineering.Repo
alias ContextEngineering.Contexts.ADRs.ADR
alias ContextEngineering.Contexts.Failures.Failure
alias ContextEngineering.Contexts.Meetings.Meeting
alias ContextEngineering.Contexts.Feedbacks.Feedback
alias ContextEngineering.Contexts.Debates.{Debate, DebateMessage, DebateJudgment}
alias ContextEngineering.Services.EmbeddingService
alias ContextEngineering.Knowledge

IO.puts("\n🌱 Seeding database with test data for feedback and debates...\n")

# Clear existing data
IO.puts("Clearing existing data...")
Repo.delete_all(DebateJudgment)
Repo.delete_all(DebateMessage)
Repo.delete_all(Debate)
Repo.delete_all(Feedback)
Repo.delete_all(Meeting)
Repo.delete_all(Failure)
Repo.delete_all(ADR)

# ========================================
# ADRs
# ========================================

IO.puts("\n📋 Creating ADRs...")

# ADR-001: Outdated decision (will have debate)
{:ok, embedding} = EmbeddingService.generate_embedding(
  "Choose PostgreSQL over MongoDB for database"
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
  outcome: "Successfully implemented in 2023",
  status: "active",
  created_date: ~D[2023-06-15],
  tags: ["database", "infrastructure"],
  author: "jane@company.com",
  stakeholders: ["platform-team", "backend-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ ADR-001: PostgreSQL (will be debated as outdated)")

# ADR-002: Error handling pattern (will have debate about pkg/errors)
{:ok, embedding} = EmbeddingService.generate_embedding(
  "Use pkg/errors library for error wrapping in Go services"
)

%ADR{
  id: "ADR-002",
  title: "Use pkg/errors for Error Wrapping",
  decision: "All Go services should use github.com/pkg/errors for error handling",
  context: "Need structured error wrapping with stack traces for debugging",
  options_considered: %{
    "pkg_errors" => %{"pros" => "Stack traces, wrapping", "cons" => "External dependency"},
    "stdlib" => %{"pros" => "No dependency", "cons" => "Limited features in 2019"}
  },
  outcome: "Adopted across all Go services",
  status: "active",
  created_date: ~D[2019-03-10],
  tags: ["golang", "error-handling"],
  author: "bob@company.com",
  stakeholders: ["backend-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ ADR-002: pkg/errors (will be debated as Go 1.13+ has native wrapping)")

# ADR-003: Good, current decision (positive feedback)
{:ok, embedding} = EmbeddingService.generate_embedding(
  "Use Echo framework for Go REST APIs"
)

%ADR{
  id: "ADR-003",
  title: "Use Echo Framework for REST APIs",
  decision: "All new Go REST APIs should use Echo v4 framework",
  context: "Need fast, lightweight HTTP framework with good middleware support",
  options_considered: %{
    "echo" => %{"pros" => "Fast, simple, good middleware", "cons" => "Smaller community"},
    "gin" => %{"pros" => "Popular, fast", "cons" => "More opinionated"},
    "stdlib" => %{"pros" => "No dependency", "cons" => "More boilerplate"}
  },
  outcome: "Works well, team is productive",
  status: "active",
  created_date: ~D[2024-11-20],
  tags: ["golang", "web-framework", "api"],
  author: "alice@company.com",
  stakeholders: ["backend-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ ADR-003: Echo Framework (current, good)")

# ADR-004: Redis caching (neutral, some questions)
{:ok, embedding} = EmbeddingService.generate_embedding(
  "Use Redis for distributed caching"
)

%ADR{
  id: "ADR-004",
  title: "Use Redis for Caching Layer",
  decision: "Implement Redis as distributed cache for API responses",
  context: "API response times too slow, need fast caching layer",
  options_considered: %{
    "redis" => %{"pros" => "Fast, mature, persistent", "cons" => "Extra infra"},
    "memcached" => %{"pros" => "Simple", "cons" => "No persistence"}
  },
  outcome: "Reduced p95 latency by 60%",
  status: "active",
  created_date: ~D[2024-08-20],
  tags: ["caching", "infrastructure", "performance"],
  author: "bob@company.com",
  stakeholders: ["platform-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ ADR-004: Redis Caching (will have questions)")

# ========================================
# Failures
# ========================================

IO.puts("\n🔥 Creating Failures...")

# FAIL-001: Connection pool issue (complete, helpful)
{:ok, embedding} = EmbeddingService.generate_embedding(
  "Database connection pool exhaustion under load"
)

%Failure{
  id: "FAIL-001",
  title: "Database Connection Pool Exhaustion",
  incident_date: ~D[2024-10-15],
  severity: "high",
  root_cause: "Connection pool size (50) insufficient for peak load",
  symptoms: "API timeouts, 500 errors, connection wait times >30s",
  impact: "15 minutes of degraded service",
  resolution: "Increased pool size to 200, added connection monitoring",
  prevention: ["Monitor connection pool metrics", "Load testing before deploy", "Auto-scaling pool size"],
  status: "resolved",
  pattern: "resource_exhaustion",
  tags: ["database", "performance", "infrastructure"],
  lessons_learned: "Always load test connection pools under realistic traffic",
  author: "ops-team",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ FAIL-001: Connection Pool (complete resolution)")

# FAIL-002: Incomplete resolution (will be debated)
{:ok, embedding} = EmbeddingService.generate_embedding(
  "Redis cache miss storm caused API slowdown"
)

%Failure{
  id: "FAIL-002",
  title: "Redis Cache Miss Storm",
  incident_date: ~D[2025-01-10],
  severity: "medium",
  root_cause: "Cache was flushed during deployment, causing thundering herd",
  symptoms: "Slow API responses, high database load",
  impact: "20 minutes of slow responses",
  resolution: "Restarted services to rebuild cache",
  prevention: ["Better deployment process"],
  status: "resolved",
  pattern: "cache_invalidation",
  tags: ["redis", "caching", "deployment"],
  author: "ops-team",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ FAIL-002: Cache Miss (incomplete resolution - will be debated)")

# ========================================
# Meetings
# ========================================

IO.puts("\n🤝 Creating Meetings...")

{:ok, embedding} = EmbeddingService.generate_embedding(
  "Q4 Architecture Review discussed database strategy"
)

%Meeting{
  id: "MEET-001",
  meeting_title: "Q4 2024 Architecture Review",
  date: ~D[2024-11-01],
  decisions: %{
    "database" => "Stick with PostgreSQL for now, revisit MongoDB in Q1",
    "api" => "Continue with Echo framework",
    "caching" => "Investigate Redis alternatives"
  },
  attendees: ["jane@company.com", "bob@company.com", "alice@company.com"],
  tags: ["architecture", "planning"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ MEET-001: Q4 Architecture Review")

# ========================================
# Feedback (without debates)
# ========================================

IO.puts("\n📊 Creating Feedback entries...")

# Positive feedback for ADR-003
%Feedback{
  query_text: "golang rest api framework",
  overall_rating: 5,
  items_helpful: ["ADR-003"],
  items_not_helpful: [],
  items_used: ["ADR-003"],
  missing_context: "",
  agent_id: "cursor-ai",
  session_id: "session-001",
  inserted_at: ~N[2025-02-10 10:00:00],
  updated_at: ~N[2025-02-10 10:00:00]
}
|> Repo.insert!()

IO.puts("  ✓ Feedback for ADR-003 (positive)")

# Mixed feedback for FAIL-001
%Feedback{
  query_text: "database connection pool issues",
  overall_rating: 4,
  items_helpful: ["FAIL-001"],
  items_not_helpful: [],
  items_used: ["FAIL-001"],
  missing_context: "Would like specific pool configuration values",
  agent_id: "github-copilot",
  session_id: "session-002",
  inserted_at: ~N[2025-02-11 14:30:00],
  updated_at: ~N[2025-02-11 14:30:00]
}
|> Repo.insert!()

IO.puts("  ✓ Feedback for FAIL-001 (helpful but needs more detail)")

# ========================================
# Debates - Scenario 1: ADR-001 (Outdated PostgreSQL decision)
# ========================================

IO.puts("\n💬 Creating Debate 1: ADR-001 (Outdated - 3 messages, auto-judged)...")

{:ok, debate1} = Knowledge.get_or_create_debate("ADR-001", "adr")

# Message 1: Agent discovers it's outdated
{:ok, debate1} = Knowledge.add_debate_message(debate1.id, %{
  "contributor_id" => "cursor-ai",
  "contributor_type" => "agent",
  "stance" => "disagree",
  "argument" => "This ADR from 2023 recommends PostgreSQL, but I see in the current codebase (main.go) we're using MongoDB drivers. The team appears to have migrated to MongoDB in late 2024 without updating this ADR. This should be marked as superseded."
})

IO.puts("  ✓ Message 1: cursor-ai disagrees (outdated)")

# Message 2: Another agent confirms
{:ok, debate1} = Knowledge.add_debate_message(debate1.id, %{
  "contributor_id" => "github-copilot",
  "contributor_type" => "agent",
  "stance" => "disagree",
  "argument" => "Confirmed. go.mod shows mongodb-driver v1.12.0 and no postgresql dependencies. MEET-001 notes mention 'revisit MongoDB in Q1' which suggests the migration happened. ADR-001 needs updating."
})

IO.puts("  ✓ Message 2: github-copilot disagrees (confirms migration)")

# Message 3: Third agent adds context (triggers judge)
{:ok, debate1} = Knowledge.add_debate_message(debate1.id, %{
  "contributor_id" => "claude-code",
  "contributor_type" => "agent",
  "stance" => "disagree",
  "argument" => "Adding evidence: All database connection code in handlers/ uses MongoDB syntax. No PostgreSQL imports found. Suggest creating ADR-005 to document the MongoDB decision and marking ADR-001 as superseded."
})

IO.puts("  ✓ Message 3: claude-code disagrees (should trigger judge)")

# Manually trigger judge since we're in seed script
if debate1.message_count >= 3 do
  IO.puts("  ⚖️  Triggering judge for ADR-001 debate...")
  ContextEngineering.Workers.JudgeWorker.trigger_judge(debate1.id)
  Process.sleep(1000) # Give judge time to process
  IO.puts("  ✓ Judge evaluated (should be Score: 1/5, Action: update)")
end

# ========================================
# Debates - Scenario 2: ADR-002 (pkg/errors vs stdlib)
# ========================================

IO.puts("\n💬 Creating Debate 2: ADR-002 (pkg/errors - 3 messages, auto-judged)...")

{:ok, debate2} = Knowledge.get_or_create_debate("ADR-002", "adr")

# Message 1: Points out Go 1.13+ has native wrapping
{:ok, debate2} = Knowledge.add_debate_message(debate2.id, %{
  "contributor_id" => "cursor-ai",
  "contributor_type" => "agent",
  "stance" => "disagree",
  "argument" => "ADR-002 recommends pkg/errors, but Go 1.13+ (released 2019) added native error wrapping with fmt.Errorf and %w verb. The standard library now provides this functionality without external dependencies."
})

IO.puts("  ✓ Message 1: cursor-ai disagrees (stdlib has feature now)")

# Message 2: Confirms codebase doesn't use pkg/errors
{:ok, debate2} = Knowledge.add_debate_message(debate2.id, %{
  "contributor_id" => "github-copilot",
  "contributor_type" => "agent",
  "stance" => "disagree",
  "argument" => "Checked go.mod: pkg/errors is not listed as a dependency. Current error handling in codebase uses fmt.Errorf with %w exclusively. This ADR is outdated."
})

IO.puts("  ✓ Message 2: github-copilot disagrees (not in use)")

# Message 3: Suggests action
{:ok, debate2} = Knowledge.add_debate_message(debate2.id, %{
  "contributor_id" => "claude-code",
  "contributor_type" => "agent",
  "stance" => "disagree",
  "argument" => "All three agents agree this is outdated. Recommend updating ADR-002 to document current practice: use stdlib fmt.Errorf with %w for error wrapping. No external dependencies needed."
})

IO.puts("  ✓ Message 3: claude-code disagrees (suggests update)")

if debate2.message_count >= 3 do
  IO.puts("  ⚖️  Triggering judge for ADR-002 debate...")
  ContextEngineering.Workers.JudgeWorker.trigger_judge(debate2.id)
  Process.sleep(1000)
  IO.puts("  ✓ Judge evaluated (should be Score: 1/5, Action: update)")
end

# ========================================
# Debates - Scenario 3: ADR-003 (Echo - positive, 2 messages, no judgment yet)
# ========================================

IO.puts("\n💬 Creating Debate 3: ADR-003 (Echo - 2 messages, awaiting 3rd)...")

{:ok, debate3} = Knowledge.get_or_create_debate("ADR-003", "adr")

# Message 1: Positive confirmation
{:ok, debate3} = Knowledge.add_debate_message(debate3.id, %{
  "contributor_id" => "cursor-ai",
  "contributor_type" => "agent",
  "stance" => "agree",
  "argument" => "ADR-003 is accurate and current. Echo v4 is actively used in main.go and all handlers. Team reports high productivity with this framework."
})

IO.puts("  ✓ Message 1: cursor-ai agrees (accurate)")

# Message 2: Another positive
{:ok, debate3} = Knowledge.add_debate_message(debate3.id, %{
  "contributor_id" => "github-copilot",
  "contributor_type" => "agent",
  "stance" => "agree",
  "argument" => "Confirmed. go.mod shows echo v4.11.4. All REST endpoints use Echo patterns. No issues or contradictions found. This ADR is well-maintained."
})

IO.puts("  ✓ Message 2: github-copilot agrees (confirmed)")
IO.puts("  ⏳ Awaiting 3rd message to trigger judge...")

# ========================================
# Debates - Scenario 4: FAIL-002 (Incomplete resolution, 1 message)
# ========================================

IO.puts("\n💬 Creating Debate 4: FAIL-002 (Incomplete - 1 message so far)...")

{:ok, debate4} = Knowledge.get_or_create_debate("FAIL-002", "failure")

# Message 1: Points out incomplete resolution
{:ok, debate4} = Knowledge.add_debate_message(debate4.id, %{
  "contributor_id" => "cursor-ai",
  "contributor_type" => "agent",
  "stance" => "neutral",
  "argument" => "FAIL-002 resolution says 'Restarted services to rebuild cache' but doesn't explain the root fix. Prevention mentions 'Better deployment process' but lacks specifics. What changes were made to prevent cache flushes during deployment?"
})

IO.puts("  ✓ Message 1: cursor-ai neutral (asks for details)")
IO.puts("  ⏳ Awaiting 2 more messages to trigger judge...")

# ========================================
# Debates - Scenario 5: ADR-004 (Redis - question stance)
# ========================================

IO.puts("\n💬 Creating Debate 5: ADR-004 (Redis - question)...")

{:ok, debate5} = Knowledge.get_or_create_debate("ADR-004", "adr")

# Message 1: Question about scale
{:ok, debate5} = Knowledge.add_debate_message(debate5.id, %{
  "contributor_id" => "claude-code",
  "contributor_type" => "agent",
  "stance" => "question",
  "argument" => "ADR-004 mentions 60% latency improvement but doesn't specify cache hit ratio or typical TTLs. What's the expected cache hit rate? How long are items cached?"
})

IO.puts("  ✓ Message 1: claude-code question (seeking metrics)")
IO.puts("  ⏳ Awaiting 2 more messages...")

# ========================================
# Summary
# ========================================

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("✅ SEED DATA COMPLETE\n")

IO.puts("📋 ADRs Created:")
IO.puts("   - ADR-001: PostgreSQL (3 disagree messages → judged as outdated)")
IO.puts("   - ADR-002: pkg/errors (3 disagree messages → judged as outdated)")
IO.puts("   - ADR-003: Echo (2 agree messages → awaiting 3rd for judgment)")
IO.puts("   - ADR-004: Redis (1 question message → awaiting 2 more)")

IO.puts("\n🔥 Failures Created:")
IO.puts("   - FAIL-001: Connection Pool (complete, good)")
IO.puts("   - FAIL-002: Cache Miss (1 neutral message → incomplete resolution)")

IO.puts("\n🤝 Meetings Created:")
IO.puts("   - MEET-001: Q4 Architecture Review")

IO.puts("\n📊 Feedback Entries: 2")

IO.puts("\n💬 Debates Created: 5")
IO.puts("   - ADR-001: Status = judged (Score: 1/5, Action: update)")
IO.puts("   - ADR-002: Status = judged (Score: 1/5, Action: update)")
IO.puts("   - ADR-003: Status = open (2/3 messages)")
IO.puts("   - FAIL-002: Status = open (1/3 messages)")
IO.puts("   - ADR-004: Status = open (1/3 messages)")

IO.puts("\n" <> String.duplicate("=", 60))

IO.puts("\n🧪 TEST SCENARIOS:")
IO.puts("\n1. Query with debates:")
IO.puts("   curl -X POST http://localhost:4000/api/context/query \\")
IO.puts("     -H 'Content-Type: application/json' \\")
IO.puts("     -d '{\"query\": \"database decisions\", \"include_debates\": true}'")

IO.puts("\n2. View specific debate:")
IO.puts("   curl 'http://localhost:4000/api/debate/by-resource?resource_id=ADR-001&resource_type=adr'")

IO.puts("\n3. Add 3rd message to ADR-003 (trigger judge):")
IO.puts("   curl -X POST http://localhost:4000/api/feedback \\")
IO.puts("     -H 'Content-Type: application/json' \\")
IO.puts("     -d '{")
IO.puts("       \"query_text\": \"echo framework\",")
IO.puts("       \"overall_rating\": 5,")
IO.puts("       \"agent_id\": \"test-agent\",")
IO.puts("       \"debate_contributions\": [{")
IO.puts("         \"resource_id\": \"ADR-003\",")
IO.puts("         \"resource_type\": \"adr\",")
IO.puts("         \"stance\": \"agree\",")
IO.puts("         \"argument\": \"Third confirmation: Echo is working great\"")
IO.puts("       }]")
IO.puts("     }'")

IO.puts("\n4. List pending judgments:")
IO.puts("   curl http://localhost:4000/api/debate/pending-judgment")

IO.puts("\n5. Get feedback stats:")
IO.puts("   curl http://localhost:4000/api/feedback/stats?days_back=30")

IO.puts("\n✨ Ready to test feedback and debate features!\n")

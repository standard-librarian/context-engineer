import Ecto.Query

alias ContextEngineering.Repo
alias ContextEngineering.Contexts.ADRs.ADR
alias ContextEngineering.Contexts.Failures.Failure
alias ContextEngineering.Contexts.Meetings.Meeting
alias ContextEngineering.Contexts.Snapshots.Snapshot
alias ContextEngineering.Services.EmbeddingService
alias ContextEngineering.Contexts.Relationships.Graph

IO.puts("Clearing existing data...")
Repo.delete_all("relationships")
Repo.delete_all(Snapshot)
Repo.delete_all(Meeting)
Repo.delete_all(Failure)
Repo.delete_all(ADR)

IO.puts("Generating embeddings and seeding data...")

# =============================================================================
# ADRs - Architecture Decision Records
# =============================================================================

# --- ADR-001 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Choose PostgreSQL over MongoDB for database. Use PostgreSQL as primary database for all services. Need strong consistency, complex queries, and ACID compliance."
  )

%ADR{
  id: "ADR-001",
  title: "Choose PostgreSQL over MongoDB",
  decision: "Use PostgreSQL as primary database for all services",
  context:
    "Need strong consistency, complex queries, and ACID compliance. Team has experience with relational databases. Expected complex joins and transactions.",
  options_considered: %{
    "postgresql" => %{
      "pros" => "ACID guarantees, team expertise, excellent Elixir support with Ecto",
      "cons" => "Schema migrations required, less flexible for unstructured data"
    },
    "mongodb" => %{
      "pros" => "Flexible schema, good for rapid prototyping",
      "cons" => "Eventual consistency model, team unfamiliar with document databases"
    }
  },
  outcome: "Successfully implemented. No major issues. Query performance excellent.",
  status: "active",
  created_date: ~D[2024-01-15],
  tags: ["database", "infrastructure", "postgresql"],
  author: "jane.doe@company.com",
  stakeholders: ["platform-team", "backend-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted ADR-001")

# --- ADR-002 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Use Redis for caching layer. Implement Redis as distributed cache for API responses and session data. Need fast caching with persistence options."
  )

%ADR{
  id: "ADR-002",
  title: "Use Redis for Caching Layer",
  decision: "Implement Redis as distributed cache for API responses and session data",
  context:
    "API response times were too slow (avg 800ms). Need a fast, distributed caching layer that can handle high throughput and provide optional persistence.",
  options_considered: %{
    "redis" => %{
      "pros" => "Fast, mature, great Elixir support, rich data types, optional persistence",
      "cons" => "Extra infrastructure to manage, memory-based cost"
    },
    "memcached" => %{
      "pros" => "Simple, fast, low memory overhead",
      "cons" => "No persistence, limited data types, no Pub/Sub"
    },
    "ets" => %{
      "pros" => "Built-in to Erlang, no extra infrastructure",
      "cons" => "Not distributed, lost on node restart, harder to inspect"
    }
  },
  outcome: "Reduced p95 latency from 800ms to 120ms (85% improvement). Cache hit rate of 78%.",
  status: "active",
  created_date: ~D[2024-03-20],
  tags: ["caching", "infrastructure", "performance", "redis"],
  author: "bob.smith@company.com",
  stakeholders: ["platform-team", "backend-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted ADR-002")

# --- ADR-003 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Adopt Phoenix LiveView for admin dashboard. Build internal tools with LiveView for real-time updates without complex JavaScript frameworks."
  )

%ADR{
  id: "ADR-003",
  title: "Adopt Phoenix LiveView for Admin Dashboard",
  decision: "Build internal admin tools using Phoenix LiveView for real-time functionality",
  context:
    "Admin team needs real-time monitoring and management capabilities. Current dashboard requires full page reloads. Team wants to minimize JavaScript complexity.",
  options_considered: %{
    "liveview" => %{
      "pros" =>
        "Real-time updates via WebSocket, stays in Elixir ecosystem, less JavaScript needed",
      "cons" => "Learning curve for team, newer technology, some UI limitations"
    },
    "react_spa" => %{
      "pros" => "Team has React experience, rich ecosystem, flexible UI",
      "cons" => "Separate deployment, API overhead, more complex state management"
    },
    "vue_spa" => %{
      "pros" => "Lightweight, easy to learn, good documentation",
      "cons" => "Separate frontend build, need REST API layer, more moving parts"
    }
  },
  outcome:
    "Dashboard live with positive feedback from ops team. Development velocity increased 40%.",
  status: "active",
  created_date: ~D[2024-05-10],
  tags: ["frontend", "tooling", "liveview", "realtime"],
  author: "alice.wonder@company.com",
  stakeholders: ["ops-team", "admin-team", "frontend-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted ADR-003")

# --- ADR-004 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Implement background job processing with Oban. Use Oban for reliable async job processing with retries and observability built-in to PostgreSQL."
  )

%ADR{
  id: "ADR-004",
  title: "Use Oban for Background Job Processing",
  decision: "Implement Oban as our background job processor for async tasks",
  context:
    "Need reliable background job processing for email sending, report generation, data exports. Want to avoid additional infrastructure. Need observability and retry logic.",
  options_considered: %{
    "oban" => %{
      "pros" =>
        "Uses existing PostgreSQL, excellent observability, built-in retries, cron scheduling",
      "cons" => "Requires database polling, adds load to DB"
    },
    "sidekiq" => %{
      "pros" => "Battle-tested, rich ecosystem",
      "cons" => "Requires Redis and Ruby runtime, separate tech stack"
    },
    "exq" => %{
      "pros" => "Elixir-native, Sidekiq compatible",
      "cons" => "Less actively maintained, requires Redis"
    }
  },
  outcome:
    "Processing 50K+ jobs/day reliably. Observability dashboard highly valued by ops team.",
  status: "active",
  created_date: ~D[2024-06-05],
  tags: ["background-jobs", "infrastructure", "async", "oban"],
  author: "bob.smith@company.com",
  stakeholders: ["platform-team", "backend-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted ADR-004")

# --- ADR-005 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Adopt OpenTelemetry for distributed tracing and observability. Implement OpenTelemetry for traces, metrics, and logs with vendor-neutral format."
  )

%ADR{
  id: "ADR-005",
  title: "Adopt OpenTelemetry for Observability",
  decision: "Use OpenTelemetry as our standard for traces, metrics, and logs",
  context:
    "Growing microservices architecture makes debugging difficult. Need distributed tracing to understand request flows. Want vendor-neutral solution.",
  options_considered: %{
    "opentelemetry" => %{
      "pros" => "Vendor-neutral, industry standard, rich Elixir support, future-proof",
      "cons" => "More setup than vendor-specific, need separate collector"
    },
    "datadog_native" => %{
      "pros" => "Integrated experience, easy setup",
      "cons" => "Vendor lock-in, expensive at scale"
    },
    "elastic_apm" => %{
      "pros" => "Good Elixir support, self-hostable",
      "cons" => "Heavy infrastructure, complex setup"
    }
  },
  outcome:
    "Reduced mean time to resolution (MTTR) by 45%. Team loves distributed trace visualization.",
  status: "active",
  created_date: ~D[2024-07-22],
  tags: ["observability", "tracing", "monitoring", "opentelemetry"],
  author: "alice.wonder@company.com",
  stakeholders: ["platform-team", "all-engineering"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted ADR-005")

# --- ADR-006 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Migrate to Kubernetes for container orchestration. Move from Docker Swarm to Kubernetes for better scalability, ecosystem, and operational tooling."
  )

%ADR{
  id: "ADR-006",
  title: "Migrate to Kubernetes from Docker Swarm",
  decision: "Migrate all services to Kubernetes for container orchestration",
  context:
    "Docker Swarm limiting our scaling and operational capabilities. Industry moving to Kubernetes. Need better autoscaling, service mesh integration, and ecosystem tools.",
  options_considered: %{
    "kubernetes" => %{
      "pros" => "Industry standard, massive ecosystem, excellent autoscaling, service mesh ready",
      "cons" => "Complex learning curve, more operational overhead, YAML heavy"
    },
    "nomad" => %{
      "pros" => "Simpler than K8s, HashiCorp stack integration",
      "cons" => "Smaller ecosystem, less community support"
    },
    "stay_with_swarm" => %{
      "pros" => "No migration cost, team knows it",
      "cons" => "Limited features, declining community support, blocking future needs"
    }
  },
  outcome:
    "Migration 70% complete. Improved deployment velocity and resource utilization by 35%.",
  status: "active",
  created_date: ~D[2024-08-15],
  tags: ["kubernetes", "infrastructure", "containers", "orchestration"],
  author: "jane.doe@company.com",
  stakeholders: ["platform-team", "devops-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted ADR-006")

# --- ADR-007 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Use GraphQL for public API. Implement GraphQL alongside REST for more flexible client queries and reduced over-fetching."
  )

%ADR{
  id: "ADR-007",
  title: "Add GraphQL API Alongside REST",
  decision: "Implement GraphQL API for mobile and web clients while maintaining REST for legacy",
  context:
    "Mobile team requesting more flexible queries to reduce network round-trips. REST endpoints causing over-fetching. Want to improve mobile app performance.",
  options_considered: %{
    "graphql" => %{
      "pros" => "Client-controlled queries, reduced over-fetching, strong typing, introspection",
      "cons" => "Learning curve, N+1 query risk, caching complexity"
    },
    "improve_rest" => %{
      "pros" => "Team familiar, simple caching, widespread tooling",
      "cons" => "Doesn't solve over-fetching, need many specialized endpoints"
    },
    "grpc" => %{
      "pros" => "Fast binary protocol, strong typing, code generation",
      "cons" => "Not browser-friendly, less tooling for Elixir"
    }
  },
  outcome: "Mobile app data usage reduced 40%. Development velocity increased for new features.",
  status: "active",
  created_date: ~D[2024-09-30],
  tags: ["api", "graphql", "mobile", "performance"],
  author: "carlos.rivera@company.com",
  stakeholders: ["api-team", "mobile-team", "web-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted ADR-007")

# --- ADR-008 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Implement database connection pooling with PgBouncer. Add PgBouncer for connection pooling to handle increased concurrent connections efficiently."
  )

%ADR{
  id: "ADR-008",
  title: "Add PgBouncer for Connection Pooling",
  decision: "Deploy PgBouncer as connection pooler between application and PostgreSQL",
  context:
    "Application connection pools reaching PostgreSQL max_connections limit during peak traffic. Need better connection management without increasing database resources.",
  options_considered: %{
    "pgbouncer" => %{
      "pros" =>
        "Lightweight, battle-tested, transaction pooling, significant connection reduction",
      "cons" => "Additional component to manage, some features require session pooling"
    },
    "increase_postgres_connections" => %{
      "pros" => "Simple, no new components",
      "cons" => "Doesn't scale well, increases memory usage, affects performance"
    },
    "pgpool" => %{
      "pros" => "More features, load balancing, query caching",
      "cons" => "More complex, heavier, harder to operate"
    }
  },
  outcome:
    "Reduced database connections from 800 to 50. Improved connection latency and stability.",
  status: "active",
  created_date: ~D[2024-11-12],
  tags: ["database", "infrastructure", "performance", "postgresql", "connection-pooling"],
  author: "jane.doe@company.com",
  stakeholders: ["platform-team", "database-team"],
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted ADR-008")

# =============================================================================
# FAILURES - Incidents and Post-Mortems
# =============================================================================

# --- FAIL-001 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Database connection pool exhaustion under load. Connection pool size insufficient for peak load. API response times increased to 30s, 500 errors during Black Friday traffic spike."
  )

%Failure{
  id: "FAIL-001",
  title: "Database Connection Pool Exhaustion During Black Friday",
  incident_date: ~D[2024-11-24],
  severity: "critical",
  root_cause:
    "Application connection pool size (10 per node × 4 nodes = 40 total) was insufficient for Black Friday traffic spike. All connections busy, requests queuing indefinitely. No monitoring on pool utilization.",
  symptoms:
    "API response times increased from 200ms average to 30+ seconds. 15% of requests returning 504 Gateway Timeout. Database CPU at only 30% while application servers showed connection wait.",
  impact:
    "15% of users affected for 2 hours during peak shopping period. Estimated $150K in lost revenue. Customer support tickets increased 300%.",
  resolution:
    "Emergency increase of pool size from 10 to 50 per node (200 total). Added connection pool monitoring with alerts at 80% utilization. Implemented circuit breakers to fail fast.",
  prevention: [
    "Added connection pool utilization metrics and alerts at 80% threshold",
    "Updated load tests to simulate 10x traffic scenarios",
    "Created runbook for pool exhaustion incidents",
    "Scheduled quarterly capacity planning reviews",
    "Implemented graceful degradation for non-critical queries"
  ],
  status: "resolved",
  pattern: "resource_exhaustion",
  tags: ["database", "performance", "infrastructure", "connection-pool", "black-friday"],
  lessons_learned:
    "Always monitor resource utilization at application AND database level. Default configurations are rarely production-ready. Load tests must simulate realistic peak traffic, not just average load. Related to ADR-001 (PostgreSQL) and ADR-008 (PgBouncer not yet implemented).",
  author: "oncall-team@company.com",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted FAIL-001")

# --- FAIL-002 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Redis cache stampede causing cascading database failures. Multiple cache keys expired simultaneously causing thundering herd to database. All cache TTLs set to exactly 1 hour."
  )

%Failure{
  id: "FAIL-002",
  title: "Redis Cache Stampede Causing Database Overload",
  incident_date: ~D[2024-12-10],
  severity: "critical",
  root_cause:
    "All cache keys set with exactly 3600 second TTL. During deployment at 2:00 PM, cache warmed all keys simultaneously. At 3:00 PM, all keys expired at same moment causing thundering herd. Database couldn't handle sudden 100x request increase.",
  symptoms:
    "Database CPU spiked to 100%. Query latency jumped from 10ms to 45+ seconds. All API endpoints returning 503. Redis hit rate dropped from 85% to 2% instantly. Application server memory exhausted from connection backlog.",
  impact:
    "Complete service outage for 45 minutes. All 50K active users affected. Third critical outage this quarter, customer trust impacted.",
  resolution:
    "Emergency cache flush and restart with staggered TTLs. Implemented jittered TTLs (base ± 20% random). Added cache warming on deployment with gradual TTL distribution. Implemented circuit breaker pattern to fail fast and prevent cascading failures.",
  prevention: [
    "Randomize all cache TTLs with ±20% jitter to prevent synchronized expiration",
    "Implement probabilistic early expiration (refresh 5% of keys early)",
    "Add cache warming script with staggered delays for deployments",
    "Implement request coalescing for cache misses (dedupe concurrent requests)",
    "Add circuit breakers between application and database",
    "Create dashboard for cache hit rates and expiration patterns"
  ],
  status: "resolved",
  pattern: "cache_stampede",
  tags: ["caching", "performance", "database", "redis", "thundering-herd"],
  lessons_learned:
    "Never use uniform cache expiration times - always add jitter. Cache stampedes can be more dangerous than having no cache. Related to ADR-002 Redis caching decision. This is a textbook cache stampede pattern. Circuit breakers are essential for preventing cascading failures.",
  author: "oncall-team@company.com",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted FAIL-002")

# --- FAIL-003 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "LiveView memory leak from unbounded PubSub subscriptions. Phoenix LiveView processes accumulating subscriptions without cleanup causing node memory exhaustion."
  )

%Failure{
  id: "FAIL-003",
  title: "LiveView Memory Leak from PubSub Subscription Accumulation",
  incident_date: ~D[2024-12-18],
  severity: "high",
  root_cause:
    "Admin dashboard LiveView subscribed to multiple PubSub topics on mount but never unsubscribed. Each page navigation created new LiveView process with new subscriptions. After 3 days of admin usage, 15K+ subscriptions accumulated causing memory to grow from 2GB to 14GB per node.",
  symptoms:
    "Application nodes gradually using more memory over days. Node restarts temporarily fixed issue. Admin dashboard becoming slower. Eventually nodes crashed with out-of-memory errors. Kubernetes kept restarting pods in crash loop.",
  impact:
    "Admin dashboard unavailable for 4 hours. Ops team couldn't access monitoring tools during incident. Manual node restarts required every 6 hours until fix deployed.",
  resolution:
    "Added Phoenix.PubSub.unsubscribe/2 calls in terminate/2 callback. Implemented process monitoring to detect subscription leaks. Added memory alerts at 80% node capacity. Deployed fix and restarted all nodes.",
  prevention: [
    "Added terminate/2 callbacks to all LiveViews that subscribe to PubSub",
    "Created linter rule to check PubSub subscribe/unsubscribe pairing",
    "Implemented process memory monitoring per LiveView type",
    "Added integration test that simulates multiple LiveView mount/unmount cycles",
    "Created dashboard showing PubSub subscription counts by topic",
    "Documented PubSub best practices in team wiki"
  ],
  status: "resolved",
  pattern: "memory_leak",
  tags: ["liveview", "memory-leak", "pubsub", "phoenix", "performance"],
  lessons_learned:
    "Always clean up resources in LiveView terminate/2 callbacks. PubSub subscriptions are not automatically cleaned up. Memory leaks in stateful processes can be hard to detect without proper monitoring. Related to ADR-003 LiveView adoption. Load testing should include long-running sessions.",
  author: "alice.wonder@company.com",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted FAIL-003")

# --- FAIL-004 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Kubernetes pod eviction during deployment causing request failures. Rolling deployment caused pods to be evicted before connection draining completed. Requests in flight failed with connection reset errors."
  )

%Failure{
  id: "FAIL-004",
  title: "Pod Eviction During K8s Deployment Causing Request Failures",
  incident_date: ~D[2024-12-22],
  severity: "medium",
  root_cause:
    "Kubernetes terminationGracePeriodSeconds set to 30s but application took 45-60s to drain in-flight requests during peak traffic. K8s sent SIGTERM but killed pods with SIGKILL after 30s, terminating active connections. No preStop hook to notify load balancer.",
  symptoms:
    "Every deployment caused spike in 502 errors (3-5% of requests). Users reported intermittent connection resets. Error rate correlated exactly with deployment times.",
  impact:
    "2-5% of requests failing during each deployment (6 deployments/day = 12-30% daily affected). User experience degraded during peak hours. Some checkout processes interrupted.",
  resolution:
    "Increased terminationGracePeriodSeconds to 120s. Added preStop hook to deregister from load balancer immediately. Implemented health check endpoint that returns unhealthy after SIGTERM. Added connection draining logic to wait for in-flight requests.",
  prevention: [
    "Set terminationGracePeriodSeconds to 120s for all services",
    "Implement preStop hook to deregister from load balancer",
    "Add /readiness endpoint that returns unhealthy after SIGTERM received",
    "Configure connection draining with timeout monitoring",
    "Update deployment strategy to wait for pod deregistration",
    "Add deployment error rate monitoring to CI/CD pipeline",
    "Test deployments under load in staging environment"
  ],
  status: "resolved",
  pattern: "graceful_shutdown",
  tags: ["kubernetes", "deployment", "infrastructure", "connection-draining"],
  lessons_learned:
    "Graceful shutdown is critical for zero-downtime deployments. Default K8s settings don't account for application-specific shutdown needs. Always test deployments under realistic load. Related to ADR-006 Kubernetes migration - we should have considered this earlier.",
  author: "jane.doe@company.com",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted FAIL-004")

# --- FAIL-005 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Oban job queue backup causing delayed email notifications. Background job queue grew to 500K+ jobs due to external email API rate limiting. Jobs timing out and retrying, making problem worse."
  )

%Failure{
  id: "FAIL-005",
  title: "Oban Job Queue Backup from Email API Rate Limiting",
  incident_date: ~D[2024-12-28],
  severity: "medium",
  root_cause:
    "Email provider (SendGrid) started rate limiting us at 1000 emails/minute due to increased sending volume. Oban workers were configured with 10 second timeout but provider returning 429 after 25 seconds of waiting. Jobs timing out, retrying immediately, and making queue backup worse. No backoff strategy for rate limit errors.",
  symptoms:
    "Oban queue depth growing by 50K jobs/hour. Email notifications delayed by 4-6 hours. Dashboard showing 85% job failure rate. Database CPU increased from handling job retries. Users complaining about missing email notifications.",
  impact:
    "Critical email notifications (password resets, 2FA codes) delayed up to 6 hours. 30K users affected. Support ticket volume increased 150%. Business metrics reporting delayed.",
  resolution:
    "Implemented exponential backoff for rate limit errors. Increased job timeout to 60s. Added rate limiting detection to avoid retries on 429 responses. Scaled down to 5 concurrent email workers. Contacted SendGrid to increase rate limits. Processed backlog over 12 hours.",
  prevention: [
    "Implement exponential backoff for all external API errors",
    "Add rate limit detection - discard jobs instead of retry for 429s",
    "Configure per-queue concurrency limits for external APIs",
    "Add monitoring for job queue depth with alerts at 10K jobs",
    "Implement priority queues for critical emails (2FA, password reset)",
    "Create failover to secondary email provider",
    "Set up better timeout handling with provider-specific settings",
    "Add queue depth dashboards to operations center"
  ],
  status: "resolved",
  pattern: "queue_backup",
  tags: ["oban", "background-jobs", "email", "rate-limiting", "async"],
  lessons_learned:
    "Always implement backoff strategies for external API calls. Rate limiting can cause cascading failures in job queues. Retrying rate-limited requests immediately makes the problem worse. Related to ADR-004 Oban adoption. Need better queue monitoring and alerting.",
  author: "bob.smith@company.com",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted FAIL-005")

# --- FAIL-006 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "GraphQL N+1 query problem causing API timeouts. Deeply nested GraphQL queries causing thousands of database queries per request. Missing dataloader implementation."
  )

%Failure{
  id: "FAIL-006",
  title: "GraphQL N+1 Queries Causing API Performance Degradation",
  incident_date: ~D[2025-01-05],
  severity: "high",
  root_cause:
    "GraphQL resolvers not using dataloader for associations. Mobile app query requesting user -> posts -> comments -> author caused N+1 queries. For user with 100 posts × 50 comments = 5000+ database queries per request. No query complexity limits or depth limits configured.",
  symptoms:
    "API response times increased from 200ms to 30+ seconds for user profile endpoint. Database connection pool exhausted. Query logs showing thousands of duplicate queries. Mobile app timing out and showing errors.",
  impact:
    "User profile page unusable for 3 hours. 40% of mobile users affected. App Store ratings dropped from 4.5 to 3.8 stars. Database read replicas at 100% CPU.",
  resolution:
    "Implemented Dataloader for all associations. Added GraphQL query complexity limits (max 1000). Set max query depth to 8. Added query cost calculation. Cached expensive resolvers. Deployed and immediately saw 95% reduction in database queries.",
  prevention: [
    "Use Dataloader for all GraphQL association loading",
    "Configure query complexity limits in GraphQL schema",
    "Set maximum query depth to prevent abuse",
    "Add query cost calculation and per-user rate limiting",
    "Implement caching for expensive resolvers",
    "Add database query count monitoring per request",
    "Create GraphQL query performance testing in CI",
    "Document GraphQL best practices for team"
  ],
  status: "resolved",
  pattern: "n_plus_one",
  tags: ["graphql", "performance", "database", "n-plus-one", "api"],
  lessons_learned:
    "GraphQL N+1 problems are more dangerous than REST because queries are user-controlled. Always use dataloader for associations. Query complexity limits are essential for production GraphQL APIs. Related to ADR-007 GraphQL adoption - should have implemented dataloader from start. Load testing must include complex, nested queries.",
  author: "carlos.rivera@company.com",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted FAIL-006")

# =============================================================================
# MEETINGS - Decision Meetings and Reviews
# =============================================================================

# --- MEET-001 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Q4 2024 Architecture Review. Discussed Kubernetes migration timeline, database sharding strategy, and performance budgets for all services. Approved migration plan and set performance targets."
  )

%Meeting{
  id: "MEET-001",
  meeting_title: "Q4 2024 Architecture Review",
  date: ~D[2024-10-15],
  decisions: %{
    "items" => [
      %{
        "decision" => "Approve Kubernetes migration plan - complete by end of Q1 2025",
        "owner" => "platform-team",
        "rationale" =>
          "Current Docker Swarm limiting scalability. K8s provides better ecosystem and tooling.",
        "action_items" => [
          "Create migration runbook by Nov 1",
          "Migrate non-critical services first",
          "Complete team K8s training by Nov 15"
        ]
      },
      %{
        "decision" => "Approve database sharding plan for user data",
        "owner" => "data-team",
        "rationale" =>
          "Single database approaching capacity. Need horizontal scaling for growth.",
        "action_items" => [
          "Design shard key strategy",
          "Test shard migration in staging",
          "Document query patterns for sharded data"
        ]
      },
      %{
        "decision" => "Set performance budget: 200ms p99 for all API endpoints",
        "owner" => "all-teams",
        "rationale" =>
          "User research shows 200ms is threshold for 'instant' feeling. Current p99 is 450ms.",
        "action_items" => [
          "Add performance budgets to CI/CD",
          "Create performance dashboard",
          "Identify and optimize slow endpoints"
        ]
      }
    ]
  },
  attendees: [
    "jane.doe@company.com",
    "bob.smith@company.com",
    "alice.wonder@company.com",
    "cto@company.com",
    "carlos.rivera@company.com"
  ],
  tags: ["architecture", "infrastructure", "performance", "quarterly-review"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted MEET-001")

# --- MEET-002 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Post-mortem: Black Friday 2024 outages. Review of database connection pool exhaustion and Redis cache stampede incidents. Established action items to prevent future holiday season failures."
  )

%Meeting{
  id: "MEET-002",
  meeting_title: "Post-Mortem: Black Friday 2024 Outages",
  date: ~D[2024-12-15],
  decisions: %{
    "items" => [
      %{
        "decision" => "All services must have connection pool monitoring with alerts at 80%",
        "owner" => "platform-team",
        "rationale" => "FAIL-001 could have been prevented with proper monitoring.",
        "action_items" => [
          "Add pool utilization metrics to all services",
          "Configure alerts in PagerDuty",
          "Create dashboard for connection pool health"
        ]
      },
      %{
        "decision" => "Mandatory quarterly load testing at 10x peak traffic",
        "owner" => "qa-team",
        "rationale" =>
          "Current load tests don't simulate realistic peak traffic. Both failures happened under load.",
        "action_items" => [
          "Build realistic load test scenarios",
          "Schedule load tests before major shopping events",
          "Document load test results and share with team"
        ]
      },
      %{
        "decision" => "Cache TTL jitter must be applied everywhere - no exceptions",
        "owner" => "backend-team",
        "rationale" => "FAIL-002 cache stampede caused by synchronized TTLs. Classic mistake.",
        "action_items" => [
          "Audit all cache.put() calls",
          "Create helper function with jitter built-in",
          "Add linter rule to prevent uniform TTLs"
        ]
      },
      %{
        "decision" => "Implement circuit breakers for all external dependencies",
        "owner" => "backend-team",
        "rationale" => "Prevent cascading failures when dependencies are slow or down.",
        "action_items" => [
          "Add Fuse library for circuit breakers",
          "Wrap all external API calls",
          "Configure appropriate timeout and error thresholds"
        ]
      }
    ]
  },
  attendees: [
    "oncall-team@company.com",
    "jane.doe@company.com",
    "bob.smith@company.com",
    "cto@company.com",
    "vp-engineering@company.com"
  ],
  tags: ["incident", "post-mortem", "performance", "black-friday"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted MEET-002")

# --- MEET-003 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Frontend Technology Stack Review. Discussion of LiveView adoption, mobile app architecture, and GraphQL vs REST API strategy. Decided to continue with hybrid approach."
  )

%Meeting{
  id: "MEET-003",
  meeting_title: "Frontend Technology Stack Review",
  date: ~D[2024-11-08],
  decisions: %{
    "items" => [
      %{
        "decision" => "Continue LiveView for internal tools, React for public web app",
        "owner" => "frontend-team",
        "rationale" =>
          "LiveView working well for admin dashboard. Public app needs SEO and progressive enhancement that React provides better.",
        "action_items" => [
          "Document when to use LiveView vs React",
          "Create component library shared between stacks",
          "Standardize authentication flow across both"
        ]
      },
      %{
        "decision" => "GraphQL primary for mobile, maintain REST for legacy clients",
        "owner" => "api-team",
        "rationale" =>
          "GraphQL reducing mobile bandwidth by 40%. Legacy web app not ready to migrate yet.",
        "action_items" => [
          "Complete GraphQL migration for mobile by Q1",
          "Add Dataloader to prevent N+1 queries",
          "Create migration guide for REST to GraphQL"
        ]
      },
      %{
        "decision" => "Build design system with TailwindCSS for consistency",
        "owner" => "design-team",
        "rationale" =>
          "Inconsistent UI across products. TailwindCSS works well with both LiveView and React.",
        "action_items" => [
          "Create component library in Storybook",
          "Document design tokens and patterns",
          "Migrate existing UIs incrementally"
        ]
      }
    ]
  },
  attendees: [
    "alice.wonder@company.com",
    "carlos.rivera@company.com",
    "design-lead@company.com",
    "product-manager@company.com"
  ],
  tags: ["frontend", "architecture", "design-system", "liveview", "graphql"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted MEET-003")

# --- MEET-004 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Database Scaling Strategy Meeting. Discussed read replicas, connection pooling with PgBouncer, and long-term sharding approach. Approved immediate PgBouncer deployment and replica setup."
  )

%Meeting{
  id: "MEET-004",
  meeting_title: "Database Scaling Strategy Session",
  date: ~D[2024-11-20],
  decisions: %{
    "items" => [
      %{
        "decision" => "Deploy PgBouncer immediately for connection pooling",
        "owner" => "platform-team",
        "rationale" =>
          "Connection exhaustion during Black Friday shows we need better pooling before next major event.",
        "action_items" => [
          "Deploy PgBouncer in staging by Nov 25",
          "Load test with PgBouncer",
          "Production rollout by Dec 1"
        ]
      },
      %{
        "decision" => "Add 2 read replicas for reporting and analytics queries",
        "owner" => "data-team",
        "rationale" =>
          "Heavy analytical queries impacting production database performance. Read replicas will offload this traffic.",
        "action_items" => [
          "Provision read replicas with streaming replication",
          "Update reporting queries to use replicas",
          "Monitor replication lag"
        ]
      },
      %{
        "decision" => "Plan for horizontal sharding in Q2 2025 if growth continues",
        "owner" => "data-team",
        "rationale" =>
          "Current growth rate suggests we'll hit single-database limits in 6-9 months.",
        "action_items" => [
          "Research sharding strategies (by user_id vs by tenant)",
          "Evaluate Citus vs application-level sharding",
          "Create PoC with test data"
        ]
      }
    ]
  },
  attendees: [
    "jane.doe@company.com",
    "bob.smith@company.com",
    "dba-team@company.com",
    "cto@company.com"
  ],
  tags: ["database", "infrastructure", "scaling", "postgresql"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted MEET-004")

# --- MEET-005 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Incident Response Process Review. Post-mortem of recent incidents revealed gaps in runbooks, monitoring, and escalation procedures. Approved new on-call rotation and incident management tools."
  )

%Meeting{
  id: "MEET-005",
  meeting_title: "Incident Response Process Improvement",
  date: ~D[2025-01-10],
  decisions: %{
    "items" => [
      %{
        "decision" => "Adopt PagerDuty for incident management and on-call rotation",
        "owner" => "ops-team",
        "rationale" =>
          "Current ad-hoc Slack pings causing confusion and delayed response. Need proper escalation.",
        "action_items" => [
          "Set up PagerDuty account and integrations",
          "Configure escalation policies",
          "Migrate existing alerts to PagerDuty"
        ]
      },
      %{
        "decision" => "Create runbooks for all critical failure patterns",
        "owner" => "platform-team",
        "rationale" =>
          "On-call engineers wasting time figuring out basic steps. Need documented procedures.",
        "action_items" => [
          "Document top 10 incident types with step-by-step runbooks",
          "Include diagnostic queries and commands",
          "Link runbooks from monitoring alerts"
        ]
      },
      %{
        "decision" => "Mandatory post-mortem for all high and critical incidents",
        "owner" => "engineering-managers",
        "rationale" =>
          "Learning from failures inconsistent. Need systematic approach to prevent recurrence.",
        "action_items" => [
          "Create post-mortem template",
          "Schedule within 48 hours of incident resolution",
          "Track action items in project management tool"
        ]
      },
      %{
        "decision" => "Implement chaos engineering practices starting Q1",
        "owner" => "reliability-team",
        "rationale" =>
          "Proactively identify failure modes before they impact users. Build confidence in system resilience.",
        "action_items" => [
          "Start with simple experiments (pod restarts, network delays)",
          "Run chaos days monthly in staging",
          "Gradually increase to production experiments"
        ]
      }
    ]
  },
  attendees: [
    "oncall-team@company.com",
    "jane.doe@company.com",
    "bob.smith@company.com",
    "alice.wonder@company.com",
    "vp-engineering@company.com"
  ],
  tags: ["incident-management", "operations", "reliability", "process"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted MEET-005")

# =============================================================================
# SNAPSHOTS - Git Commits / Code Changes
# =============================================================================

# --- SNAP-001 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Initial PostgreSQL database setup with Ecto. Created database schemas, migrations, and connection configuration for main application database."
  )

%Snapshot{
  id: "SNAP-001",
  commit_hash: "a1b2c3d4e5f6",
  author: "jane.doe@company.com",
  message: "Initial PostgreSQL setup with Ecto schemas and migrations",
  date: ~D[2024-01-20],
  tags: ["database", "setup", "postgresql", "ecto"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-001")

# --- SNAP-002 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Implement Redis caching layer with Redix. Added cache module, connection pooling, and TTL configuration for API response caching."
  )

%Snapshot{
  id: "SNAP-002",
  commit_hash: "b2c3d4e5f6a1",
  author: "bob.smith@company.com",
  message: "Add Redis caching layer with Redix for API responses",
  date: ~D[2024-03-25],
  tags: ["caching", "redis", "performance"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-002")

# --- SNAP-003 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Build admin dashboard with Phoenix LiveView. Created real-time monitoring interface with LiveView components and PubSub for updates."
  )

%Snapshot{
  id: "SNAP-003",
  commit_hash: "c3d4e5f6a1b2",
  author: "alice.wonder@company.com",
  message: "Build admin dashboard with LiveView and real-time monitoring",
  date: ~D[2024-05-15],
  tags: ["liveview", "frontend", "admin", "realtime"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-003")

# --- SNAP-004 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Add Oban for background job processing. Configured job queues, workers, and scheduling for async tasks like email sending and report generation."
  )

%Snapshot{
  id: "SNAP-004",
  commit_hash: "d4e5f6a1b2c3",
  author: "bob.smith@company.com",
  message: "Integrate Oban for background job processing with queues and workers",
  date: ~D[2024-06-10],
  tags: ["oban", "background-jobs", "async"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-004")

# --- SNAP-005 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Implement OpenTelemetry tracing. Added telemetry instrumentation, spans, and traces for distributed request tracking across services."
  )

%Snapshot{
  id: "SNAP-005",
  commit_hash: "e5f6a1b2c3d4",
  author: "alice.wonder@company.com",
  message: "Add OpenTelemetry distributed tracing with instrumentation",
  date: ~D[2024-07-28],
  tags: ["observability", "tracing", "opentelemetry"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-005")

# --- SNAP-006 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Kubernetes deployment configuration. Created k8s manifests, deployment configs, services, and ingress rules for container orchestration."
  )

%Snapshot{
  id: "SNAP-006",
  commit_hash: "f6a1b2c3d4e5",
  author: "jane.doe@company.com",
  message: "Add Kubernetes manifests and deployment configurations",
  date: ~D[2024-08-20],
  tags: ["kubernetes", "deployment", "infrastructure"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-006")

# --- SNAP-007 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Add GraphQL API with Absinthe. Implemented GraphQL schema, resolvers, queries, and mutations for flexible client queries."
  )

%Snapshot{
  id: "SNAP-007",
  commit_hash: "a1b2c3d4e5f7",
  author: "carlos.rivera@company.com",
  message: "Implement GraphQL API with Absinthe schema and resolvers",
  date: ~D[2024-10-05],
  tags: ["graphql", "api", "absinthe"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-007")

# --- SNAP-008 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Fix Black Friday connection pool exhaustion. Increased database connection pool size and added monitoring alerts for pool utilization."
  )

%Snapshot{
  id: "SNAP-008",
  commit_hash: "b2c3d4e5f6a7",
  author: "oncall-team@company.com",
  message: "Emergency fix: increase DB connection pool size and add monitoring",
  date: ~D[2024-11-24],
  tags: ["bugfix", "database", "performance", "hotfix"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-008")

# --- SNAP-009 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Deploy PgBouncer for connection pooling. Added PgBouncer configuration and deployment for efficient database connection management."
  )

%Snapshot{
  id: "SNAP-009",
  commit_hash: "c3d4e5f6a7b2",
  author: "jane.doe@company.com",
  message: "Deploy PgBouncer for database connection pooling",
  date: ~D[2024-11-28],
  tags: ["database", "infrastructure", "pgbouncer", "connection-pooling"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-009")

# --- SNAP-010 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Fix Redis cache stampede with jittered TTLs. Implemented randomized cache expiration times to prevent synchronized cache invalidation."
  )

%Snapshot{
  id: "SNAP-010",
  commit_hash: "d4e5f6a7b2c3",
  author: "bob.smith@company.com",
  message: "Fix cache stampede by implementing jittered TTLs and request coalescing",
  date: ~D[2024-12-11],
  tags: ["caching", "bugfix", "redis", "performance"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-010")

# --- SNAP-011 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Fix LiveView PubSub memory leak. Added terminate callback to unsubscribe from PubSub topics and prevent subscription accumulation."
  )

%Snapshot{
  id: "SNAP-011",
  commit_hash: "e5f6a7b2c3d4",
  author: "alice.wonder@company.com",
  message: "Fix LiveView memory leak by properly unsubscribing from PubSub",
  date: ~D[2024-12-19],
  tags: ["liveview", "bugfix", "memory-leak", "pubsub"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-011")

# --- SNAP-012 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Improve Kubernetes graceful shutdown. Added preStop hooks and increased termination grace period for proper connection draining during deployments."
  )

%Snapshot{
  id: "SNAP-012",
  commit_hash: "f6a7b2c3d4e5",
  author: "jane.doe@company.com",
  message: "Add K8s preStop hooks and connection draining for zero-downtime deployments",
  date: ~D[2024-12-23],
  tags: ["kubernetes", "deployment", "graceful-shutdown"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-012")

# --- SNAP-013 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Fix Oban email queue backup. Implemented exponential backoff and rate limit detection for external email API to prevent job queue accumulation."
  )

%Snapshot{
  id: "SNAP-013",
  commit_hash: "a7b2c3d4e5f6",
  author: "bob.smith@company.com",
  message: "Add exponential backoff and rate limit handling to Oban email jobs",
  date: ~D[2024-12-29],
  tags: ["oban", "bugfix", "email", "rate-limiting"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-013")

# --- SNAP-014 ---
{:ok, embedding} =
  EmbeddingService.generate_embedding(
    "Add Dataloader to GraphQL resolvers. Implemented Dataloader for efficient batch loading to eliminate N+1 query problems in GraphQL API."
  )

%Snapshot{
  id: "SNAP-014",
  commit_hash: "b7c3d4e5f6a1",
  author: "carlos.rivera@company.com",
  message: "Add Dataloader to GraphQL resolvers and query complexity limits",
  date: ~D[2025-01-06],
  tags: ["graphql", "performance", "dataloader", "bugfix"],
  status: "active",
  embedding: embedding
}
|> Repo.insert!()

IO.puts("  ✓ Inserted SNAP-014")

# =============================================================================
# RELATIONSHIPS - Knowledge Graph Connections
# =============================================================================

IO.puts("\nCreating knowledge graph relationships...")

# ADR-001 (PostgreSQL) relationships
Graph.create_relationship("SNAP-001", "snapshot", "ADR-001", "adr", "implements")
Graph.create_relationship("FAIL-001", "failure", "ADR-001", "adr", "related_to")
Graph.create_relationship("ADR-008", "adr", "ADR-001", "adr", "extends")
Graph.create_relationship("MEET-004", "meeting", "ADR-001", "adr", "references")

# ADR-002 (Redis) relationships
Graph.create_relationship("SNAP-002", "snapshot", "ADR-002", "adr", "implements")
Graph.create_relationship("FAIL-002", "failure", "ADR-002", "adr", "caused_by")
Graph.create_relationship("SNAP-010", "snapshot", "FAIL-002", "failure", "fixes")
Graph.create_relationship("MEET-002", "meeting", "ADR-002", "adr", "references")

# ADR-003 (LiveView) relationships
Graph.create_relationship("SNAP-003", "snapshot", "ADR-003", "adr", "implements")
Graph.create_relationship("FAIL-003", "failure", "ADR-003", "adr", "caused_by")
Graph.create_relationship("SNAP-011", "snapshot", "FAIL-003", "failure", "fixes")
Graph.create_relationship("MEET-003", "meeting", "ADR-003", "adr", "references")

# ADR-004 (Oban) relationships
Graph.create_relationship("SNAP-004", "snapshot", "ADR-004", "adr", "implements")
Graph.create_relationship("FAIL-005", "failure", "ADR-004", "adr", "related_to")
Graph.create_relationship("SNAP-013", "snapshot", "FAIL-005", "failure", "fixes")

# ADR-005 (OpenTelemetry) relationships
Graph.create_relationship("SNAP-005", "snapshot", "ADR-005", "adr", "implements")
Graph.create_relationship("MEET-001", "meeting", "ADR-005", "adr", "references")

# ADR-006 (Kubernetes) relationships
Graph.create_relationship("SNAP-006", "snapshot", "ADR-006", "adr", "implements")
Graph.create_relationship("FAIL-004", "failure", "ADR-006", "adr", "related_to")
Graph.create_relationship("SNAP-012", "snapshot", "FAIL-004", "failure", "fixes")
Graph.create_relationship("MEET-001", "meeting", "ADR-006", "adr", "references")

# ADR-007 (GraphQL) relationships
Graph.create_relationship("SNAP-007", "snapshot", "ADR-007", "adr", "implements")
Graph.create_relationship("FAIL-006", "failure", "ADR-007", "adr", "caused_by")
Graph.create_relationship("SNAP-014", "snapshot", "FAIL-006", "failure", "fixes")
Graph.create_relationship("MEET-003", "meeting", "ADR-007", "adr", "references")

# ADR-008 (PgBouncer) relationships
Graph.create_relationship("SNAP-008", "snapshot", "ADR-008", "adr", "implements")
Graph.create_relationship("MEET-004", "meeting", "ADR-008", "adr", "references")
Graph.create_relationship("FAIL-001", "failure", "ADR-008", "adr", "motivates")

# Cross-cutting failure relationships
Graph.create_relationship("FAIL-002", "failure", "FAIL-001", "failure", "related_to")
Graph.create_relationship("FAIL-003", "failure", "FAIL-001", "failure", "related_to")
Graph.create_relationship("FAIL-005", "failure", "FAIL-001", "failure", "related_to")
Graph.create_relationship("FAIL-006", "failure", "FAIL-002", "failure", "similar_pattern")

# Post-mortem meeting relationships
Graph.create_relationship("MEET-002", "meeting", "FAIL-001", "failure", "references")
Graph.create_relationship("MEET-002", "meeting", "FAIL-002", "failure", "references")
Graph.create_relationship("SNAP-009", "snapshot", "MEET-002", "meeting", "action_item")
Graph.create_relationship("SNAP-010", "snapshot", "MEET-002", "meeting", "action_item")

# Incident response meeting relationships
Graph.create_relationship("MEET-005", "meeting", "FAIL-001", "failure", "informs")
Graph.create_relationship("MEET-005", "meeting", "FAIL-002", "failure", "informs")
Graph.create_relationship("MEET-005", "meeting", "FAIL-003", "failure", "informs")
Graph.create_relationship("MEET-005", "meeting", "FAIL-004", "failure", "informs")
Graph.create_relationship("MEET-005", "meeting", "FAIL-005", "failure", "informs")
Graph.create_relationship("MEET-005", "meeting", "FAIL-006", "failure", "informs")

# Database-related connections
Graph.create_relationship("MEET-004", "meeting", "FAIL-001", "failure", "addresses")
Graph.create_relationship("SNAP-009", "snapshot", "ADR-001", "adr", "improves")

IO.puts("\nSeeding complete!")
IO.puts("=" <> String.duplicate("=", 79))
IO.puts("Summary:")
IO.puts("  • 8 ADRs (Architecture Decision Records)")
IO.puts("  • 6 Failures (Incidents & Post-Mortems)")
IO.puts("  • 5 Meetings (Decision & Review Sessions)")
IO.puts("  • 14 Snapshots (Code Changes)")
IO.puts("  • 43 Relationships (Knowledge Graph Edges)")
IO.puts("=" <> String.duplicate("=", 79))

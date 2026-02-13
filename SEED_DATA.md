# Seed Data Documentation

This document describes the comprehensive seed data used to populate the Context Engineering knowledge base with realistic, interconnected examples.

## Overview

The seed data creates a realistic knowledge graph representing a software engineering organization's architectural decisions, failures, meetings, and code changes over approximately one year (Jan 2024 - Jan 2025).

## Statistics

- **8 ADRs** (Architecture Decision Records)
- **6 Failures** (Incidents & Post-Mortems)
- **5 Meetings** (Decision & Review Sessions)
- **14 Snapshots** (Git Commits / Code Changes)
- **44 Relationships** (Knowledge Graph Edges)

## Architecture Decision Records (ADRs)

### ADR-001: Choose PostgreSQL over MongoDB
- **Date**: 2024-01-15
- **Author**: jane.doe@company.com
- **Decision**: Use PostgreSQL as primary database for all services
- **Tags**: database, infrastructure, postgresql
- **Status**: Active

### ADR-002: Use Redis for Caching Layer
- **Date**: 2024-03-20
- **Author**: bob.smith@company.com
- **Decision**: Implement Redis as distributed cache for API responses and session data
- **Outcome**: Reduced p95 latency from 800ms to 120ms (85% improvement)
- **Tags**: caching, infrastructure, performance, redis
- **Status**: Active

### ADR-003: Adopt Phoenix LiveView for Admin Dashboard
- **Date**: 2024-05-10
- **Author**: alice.wonder@company.com
- **Decision**: Build internal admin tools using Phoenix LiveView for real-time functionality
- **Outcome**: Development velocity increased 40%
- **Tags**: frontend, tooling, liveview, realtime
- **Status**: Active

### ADR-004: Use Oban for Background Job Processing
- **Date**: 2024-06-05
- **Author**: bob.smith@company.com
- **Decision**: Implement Oban as background job processor for async tasks
- **Outcome**: Processing 50K+ jobs/day reliably
- **Tags**: background-jobs, infrastructure, async, oban
- **Status**: Active

### ADR-005: Adopt OpenTelemetry for Observability
- **Date**: 2024-07-22
- **Author**: alice.wonder@company.com
- **Decision**: Use OpenTelemetry as standard for traces, metrics, and logs
- **Outcome**: Reduced mean time to resolution (MTTR) by 45%
- **Tags**: observability, tracing, monitoring, opentelemetry
- **Status**: Active

### ADR-006: Migrate to Kubernetes from Docker Swarm
- **Date**: 2024-08-15
- **Author**: jane.doe@company.com
- **Decision**: Migrate all services to Kubernetes for container orchestration
- **Outcome**: Migration 70% complete. Improved deployment velocity by 35%
- **Tags**: kubernetes, infrastructure, containers, orchestration
- **Status**: Active

### ADR-007: Add GraphQL API Alongside REST
- **Date**: 2024-09-30
- **Author**: carlos.rivera@company.com
- **Decision**: Implement GraphQL API for mobile and web clients while maintaining REST
- **Outcome**: Mobile app data usage reduced 40%
- **Tags**: api, graphql, mobile, performance
- **Status**: Active

### ADR-008: Add PgBouncer for Connection Pooling
- **Date**: 2024-11-12
- **Author**: jane.doe@company.com
- **Decision**: Deploy PgBouncer as connection pooler between application and PostgreSQL
- **Outcome**: Reduced database connections from 800 to 50
- **Tags**: database, infrastructure, performance, postgresql, connection-pooling
- **Status**: Active

## Failures (Incidents)

### FAIL-001: Database Connection Pool Exhaustion During Black Friday
- **Date**: 2024-11-24
- **Severity**: Critical
- **Pattern**: resource_exhaustion
- **Root Cause**: Connection pool size (40 total) insufficient for Black Friday traffic spike
- **Impact**: 15% of users affected for 2 hours, $150K lost revenue
- **Resolution**: Increased pool size to 200, added monitoring
- **Tags**: database, performance, infrastructure, connection-pool, black-friday

### FAIL-002: Redis Cache Stampede Causing Database Overload
- **Date**: 2024-12-10
- **Severity**: Critical
- **Pattern**: cache_stampede
- **Root Cause**: All cache keys expired simultaneously causing thundering herd
- **Impact**: Complete service outage for 45 minutes
- **Resolution**: Implemented jittered TTLs and cache warming
- **Tags**: caching, performance, database, redis, thundering-herd

### FAIL-003: LiveView Memory Leak from PubSub Subscription Accumulation
- **Date**: 2024-12-18
- **Severity**: High
- **Pattern**: memory_leak
- **Root Cause**: LiveView subscribed to PubSub topics but never unsubscribed
- **Impact**: Admin dashboard unavailable for 4 hours
- **Resolution**: Added terminate/2 callbacks with unsubscribe calls
- **Tags**: liveview, memory-leak, pubsub, phoenix, performance

### FAIL-004: Pod Eviction During K8s Deployment Causing Request Failures
- **Date**: 2024-12-22
- **Severity**: Medium
- **Pattern**: graceful_shutdown
- **Root Cause**: K8s terminationGracePeriodSeconds too short, pods killed before draining
- **Impact**: 2-5% of requests failing during each deployment
- **Resolution**: Increased grace period to 120s, added preStop hooks
- **Tags**: kubernetes, deployment, infrastructure, connection-draining

### FAIL-005: Oban Job Queue Backup from Email API Rate Limiting
- **Date**: 2024-12-28
- **Severity**: Medium
- **Pattern**: queue_backup
- **Root Cause**: Email provider rate limiting without proper backoff strategy
- **Impact**: Critical emails delayed up to 6 hours, 30K users affected
- **Resolution**: Implemented exponential backoff and rate limit detection
- **Tags**: oban, background-jobs, email, rate-limiting, async

### FAIL-006: GraphQL N+1 Queries Causing API Performance Degradation
- **Date**: 2025-01-05
- **Severity**: High
- **Pattern**: n_plus_one
- **Root Cause**: GraphQL resolvers not using dataloader, causing 5000+ queries per request
- **Impact**: User profile page unusable for 3 hours, 40% of mobile users affected
- **Resolution**: Implemented Dataloader, added query complexity limits
- **Tags**: graphql, performance, database, n-plus-one, api

## Meetings

### MEET-001: Q4 2024 Architecture Review
- **Date**: 2024-10-15
- **Key Decisions**:
  - Approve Kubernetes migration plan (complete by Q1 2025)
  - Approve database sharding plan for user data
  - Set performance budget: 200ms p99 for all API endpoints
- **Tags**: architecture, infrastructure, performance, quarterly-review

### MEET-002: Post-Mortem: Black Friday 2024 Outages
- **Date**: 2024-12-15
- **Key Decisions**:
  - Mandatory connection pool monitoring with alerts at 80%
  - Quarterly load testing at 10x peak traffic required
  - Cache TTL jitter must be applied everywhere
  - Implement circuit breakers for all external dependencies
- **Tags**: incident, post-mortem, performance, black-friday

### MEET-003: Frontend Technology Stack Review
- **Date**: 2024-11-08
- **Key Decisions**:
  - Continue LiveView for internal tools, React for public web
  - GraphQL primary for mobile, maintain REST for legacy clients
  - Build design system with TailwindCSS
- **Tags**: frontend, architecture, design-system, liveview, graphql

### MEET-004: Database Scaling Strategy Session
- **Date**: 2024-11-20
- **Key Decisions**:
  - Deploy PgBouncer immediately for connection pooling
  - Add 2 read replicas for reporting and analytics
  - Plan for horizontal sharding in Q2 2025
- **Tags**: database, infrastructure, scaling, postgresql

### MEET-005: Incident Response Process Improvement
- **Date**: 2025-01-10
- **Key Decisions**:
  - Adopt PagerDuty for incident management
  - Create runbooks for all critical failure patterns
  - Mandatory post-mortem for high and critical incidents
  - Implement chaos engineering practices starting Q1
- **Tags**: incident-management, operations, reliability, process

## Snapshots (Code Changes)

### SNAP-001: Initial PostgreSQL setup with Ecto schemas and migrations
- **Date**: 2024-01-20
- **Commit**: a1b2c3d4e5f6
- **Implements**: ADR-001

### SNAP-002: Add Redis caching layer with Redix for API responses
- **Date**: 2024-03-25
- **Commit**: b2c3d4e5f6a1
- **Implements**: ADR-002

### SNAP-003: Build admin dashboard with LiveView and real-time monitoring
- **Date**: 2024-05-15
- **Commit**: c3d4e5f6a1b2
- **Implements**: ADR-003

### SNAP-004: Integrate Oban for background job processing with queues and workers
- **Date**: 2024-06-10
- **Commit**: d4e5f6a1b2c3
- **Implements**: ADR-004

### SNAP-005: Add OpenTelemetry distributed tracing with instrumentation
- **Date**: 2024-07-28
- **Commit**: e5f6a1b2c3d4
- **Implements**: ADR-005

### SNAP-006: Begin Kubernetes migration with initial service deployments
- **Date**: 2024-08-20
- **Commit**: f6a1b2c3d4e5
- **Implements**: ADR-006

### SNAP-007: Implement GraphQL API with Absinthe for mobile clients
- **Date**: 2024-10-05
- **Commit**: a1b2c3d4e5f7
- **Implements**: ADR-007

### SNAP-008: Deploy PgBouncer for database connection pooling
- **Date**: 2024-11-13
- **Commit**: b2c3d4e5f6a8
- **Implements**: ADR-008

### SNAP-009: Emergency fix: increase database connection pool size
- **Date**: 2024-11-24
- **Commit**: c3d4e5f6a7b1
- **Fixes**: FAIL-001
- **Tags**: database, hotfix, connection-pool

### SNAP-010: Fix Redis cache stampede with jittered TTLs
- **Date**: 2024-12-11
- **Commit**: d4e5f6a1b2c9
- **Fixes**: FAIL-002
- **Tags**: caching, bugfix, redis, performance

### SNAP-011: Fix LiveView memory leak by properly unsubscribing from PubSub
- **Date**: 2024-12-19
- **Commit**: e5f6a7b2c3d4
- **Fixes**: FAIL-003
- **Tags**: liveview, bugfix, memory-leak, pubsub

### SNAP-012: Add K8s preStop hooks and connection draining for zero-downtime deployments
- **Date**: 2024-12-23
- **Commit**: f6a7b2c3d4e5
- **Fixes**: FAIL-004
- **Tags**: kubernetes, deployment, graceful-shutdown

### SNAP-013: Add exponential backoff and rate limit handling to Oban email jobs
- **Date**: 2024-12-29
- **Commit**: a7b2c3d4e5f6
- **Fixes**: FAIL-005
- **Tags**: oban, bugfix, email, rate-limiting

### SNAP-014: Add Dataloader to GraphQL resolvers and query complexity limits
- **Date**: 2025-01-06
- **Commit**: b7c3d4e5f6a1
- **Fixes**: FAIL-006
- **Tags**: graphql, performance, dataloader, bugfix

## Knowledge Graph Relationships

The seed data creates 44 relationships across 11 relationship types, forming a rich knowledge graph that connects decisions, failures, meetings, and code changes.

### Relationship Types

#### IMPLEMENTS (8 relationships)
Snapshots that implement architectural decisions:
- SNAP-001 → ADR-001 (PostgreSQL)
- SNAP-002 → ADR-002 (Redis)
- SNAP-003 → ADR-003 (LiveView)
- SNAP-004 → ADR-004 (Oban)
- SNAP-005 → ADR-005 (OpenTelemetry)
- SNAP-006 → ADR-006 (Kubernetes)
- SNAP-007 → ADR-007 (GraphQL)
- SNAP-008 → ADR-008 (PgBouncer)

#### FIXES (5 relationships)
Snapshots that fix failures:
- SNAP-010 → FAIL-002 (Cache stampede fix)
- SNAP-011 → FAIL-003 (LiveView memory leak fix)
- SNAP-012 → FAIL-004 (K8s graceful shutdown fix)
- SNAP-013 → FAIL-005 (Oban rate limiting fix)
- SNAP-014 → FAIL-006 (GraphQL N+1 fix)

#### CAUSED_BY (3 relationships)
Failures caused by architectural decisions:
- FAIL-002 → ADR-002 (Cache stampede from Redis implementation)
- FAIL-003 → ADR-003 (Memory leak from LiveView adoption)
- FAIL-006 → ADR-007 (N+1 queries from GraphQL implementation)

#### REFERENCES (9 relationships)
Meetings that reference ADRs or failures:
- MEET-004 → ADR-001 (PostgreSQL)
- MEET-002 → ADR-002 (Redis)
- MEET-003 → ADR-003 (LiveView)
- MEET-001 → ADR-005 (OpenTelemetry)
- MEET-001 → ADR-006 (Kubernetes)
- MEET-003 → ADR-007 (GraphQL)
- MEET-004 → ADR-008 (PgBouncer)
- MEET-002 → FAIL-001 (Black Friday outage)
- MEET-002 → FAIL-002 (Cache stampede)

#### RELATED_TO (6 relationships)
Items that are related but not directly causal:
- FAIL-001 → ADR-001 (Connection exhaustion related to PostgreSQL)
- FAIL-005 → ADR-004 (Queue backup related to Oban)
- FAIL-004 → ADR-006 (Pod eviction related to Kubernetes)
- FAIL-002 → FAIL-001 (Both Black Friday incidents)
- FAIL-003 → FAIL-001 (Both resource exhaustion patterns)
- FAIL-005 → FAIL-001 (Both scaling issues)

#### INFORMS (6 relationships)
How failures inform meeting decisions:
- MEET-005 → FAIL-001 through FAIL-006 (All failures inform incident response process)

#### MOTIVATES (1 relationship)
Failures that motivate new decisions:
- FAIL-001 → ADR-008 (Connection exhaustion motivated PgBouncer adoption)

#### EXTENDS (1 relationship)
ADRs that extend previous decisions:
- ADR-008 → ADR-001 (PgBouncer extends PostgreSQL decision)

#### IMPROVES (1 relationship)
Code changes that improve existing decisions:
- SNAP-009 → ADR-001 (Pool size increase improves PostgreSQL setup)

#### ACTION_ITEM (2 relationships)
Code changes resulting from meeting action items:
- SNAP-009 → MEET-002 (Post-mortem action item)
- SNAP-010 → MEET-002 (Post-mortem action item)

#### ADDRESSES (1 relationship)
Meetings that address specific failures:
- MEET-004 → FAIL-001 (Database scaling meeting addresses connection exhaustion)

#### SIMILAR_PATTERN (1 relationship)
Failures that share similar patterns:
- FAIL-006 → FAIL-002 (Both are performance degradation from missing optimizations)

## Key Storylines

### The Black Friday Incident (November 2024)
1. **FAIL-001**: Database connection pool exhaustion during Black Friday
2. **SNAP-009**: Emergency fix to increase pool size
3. **MEET-002**: Post-mortem meeting to analyze both Black Friday failures
4. **ADR-008**: Decision to adopt PgBouncer for better connection management
5. **SNAP-008**: Implementation of PgBouncer
6. **MEET-004**: Database scaling strategy session

### The Cache Stampede Crisis (December 2024)
1. **ADR-002**: Original Redis caching decision
2. **FAIL-002**: Cache stampede from synchronized TTLs
3. **SNAP-010**: Fix with jittered TTLs
4. **MEET-002**: Post-mortem review

### The LiveView Memory Leak (December 2024)
1. **ADR-003**: Adoption of Phoenix LiveView
2. **SNAP-003**: Initial LiveView implementation
3. **FAIL-003**: Memory leak from PubSub subscriptions
4. **SNAP-011**: Fix with proper cleanup

### The GraphQL Performance Issue (January 2025)
1. **ADR-007**: GraphQL API adoption
2. **SNAP-007**: Initial GraphQL implementation
3. **FAIL-006**: N+1 query problem
4. **SNAP-014**: Fix with Dataloader

## Running the Seeds

To populate your database with this seed data:

```bash
# Reset and seed the database
mix ecto.reset

# Or just run seeds (preserves existing data)
mix run priv/repo/seeds.exs
```

The seeding process:
1. Clears all existing data (relationships, snapshots, meetings, failures, ADRs)
2. Generates embeddings for each knowledge item using the EmbeddingService
3. Inserts 8 ADRs, 6 failures, 5 meetings, and 14 snapshots
4. Creates 44 relationship edges connecting the knowledge graph
5. Prints a summary of what was seeded

## Querying the Knowledge Graph

Example queries to explore relationships:

```elixir
# Find all failures caused by a specific ADR
alias ContextEngineering.Repo
import Ecto.Query

from(r in "relationships",
  where: r.to_id == "ADR-002" and 
         r.to_type == "adr" and 
         r.relationship_type == "caused_by",
  select: {r.from_id, r.from_type}
)
|> Repo.all()

# Find all code changes that fix failures
from(r in "relationships",
  where: r.from_type == "snapshot" and 
         r.to_type == "failure" and 
         r.relationship_type == "fixes",
  select: {r.from_id, r.to_id}
)
|> Repo.all()

# Find all meetings that reference a specific failure
from(r in "relationships",
  where: r.to_id == "FAIL-001" and 
         r.relationship_type == "references",
  select: r.from_id
)
|> Repo.all()
```

## Example Queries

Here are some practical queries you can run to explore the knowledge graph:

### Find All Failures Related to Black Friday

```elixir
alias ContextEngineering.Repo
alias ContextEngineering.Contexts.Failures.Failure
import Ecto.Query

# Get failures with "black-friday" tag
from(f in Failure,
  where: "black-friday" in f.tags,
  select: {f.id, f.title, f.severity}
)
|> Repo.all()
```

### Find ADRs and Their Implementation Status

```elixir
# Get ADRs with their implementing snapshots
from(a in "adrs",
  left_join: r in "relationships",
  on: r.to_id == a.id and r.to_type == "adr" and r.relationship_type == "implements",
  left_join: s in "snapshots",
  on: s.id == r.from_id,
  select: {a.id, a.title, s.id, s.commit_hash}
)
|> Repo.all()
```

### Find Failures That Led to New ADRs

```elixir
# Failures that motivated architectural decisions
from(r in "relationships",
  where: r.relationship_type == "motivates" and r.to_type == "adr",
  join: f in "failures", on: f.id == r.from_id,
  join: a in "adrs", on: a.id == r.to_id,
  select: {f.title, a.title}
)
|> Repo.all()
```

### Find All Fixes for Critical Failures

```elixir
# Get critical failures and their fixes
from(f in Failure,
  where: f.severity == "critical",
  left_join: r in "relationships",
  on: r.to_id == f.id and r.relationship_type == "fixes",
  left_join: s in "snapshots",
  on: s.id == r.from_id,
  select: {f.id, f.title, s.id, s.message}
)
|> Repo.all()
```

### Find Knowledge Items by Semantic Similarity

```elixir
# Find items similar to "database connection issues"
alias ContextEngineering.Services.EmbeddingService
alias ContextEngineering.Knowledge

{:ok, embedding} = EmbeddingService.generate_embedding("database connection issues")
Knowledge.search_similar(embedding, limit: 5)
```

### Trace the Impact of a Decision

```elixir
# Find all items connected to ADR-002 (Redis caching)
from(r in "relationships",
  where: r.to_id == "ADR-002" or r.from_id == "ADR-002",
  select: {r.from_id, r.from_type, r.relationship_type, r.to_id, r.to_type}
)
|> Repo.all()
```

### Find Post-Mortem Action Items

```elixir
# Get snapshots created as action items from post-mortem meetings
from(r in "relationships",
  where: r.relationship_type == "action_item",
  join: s in "snapshots", on: s.id == r.from_id,
  join: m in "meetings", on: m.id == r.to_id,
  select: {m.meeting_title, s.message, s.date}
)
|> Repo.all()
```

### Analyze Failure Patterns

```elixir
# Group failures by pattern
from(f in Failure,
  group_by: f.pattern,
  select: {f.pattern, count(f.id)}
)
|> Repo.all()
```

## Benefits of This Seed Data

1. **Realistic Scenarios**: Based on actual patterns seen in production systems
2. **Rich Relationships**: 44 connections create meaningful knowledge graph
3. **Temporal Progression**: Data spans one year showing evolution of decisions
4. **Multiple Patterns**: Covers different failure types and architectural decisions
5. **Testing Semantic Search**: Embeddings enable testing of similarity searches
6. **Debugging Assistance**: Helps identify relationship patterns and query optimization needs
7. **Query Examples**: Provides practical examples for exploring the knowledge graph
8. **Storyline Tracking**: Shows how decisions evolve from failures and meetings
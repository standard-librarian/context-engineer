# Context Engineering

> **Organizational memory for AI-powered development teams**

Context Engineering is a Phoenix/Elixir application that captures, stores, and serves organizational knowledge to AI coding assistants. It enables AI agents (Cursor, GitHub Copilot, Claude) to answer questions like "Why did we choose PostgreSQL?" or "What failures have we had with authentication?" by querying a semantic knowledge base.

##  What Problem Does This Solve?

When working on a team, important context is scattered everywhere:
- Architecture decisions buried in old PRs
- Incident post-mortems lost in Slack threads
- Meeting notes scattered across docs
- No context for new developers or AI assistants

**Context Engineering solves this by:**
- Storing decisions (ADRs), failures, meetings, and code snapshots
- Enabling semantic search (meaning-based, not keyword matching)
- Providing a simple API for AI assistants to query context
- Building a knowledge graph showing how items relate
- Auto-decaying old, unused information

##  Quick Start

### Prerequisites

- Elixir 1.15+ and Erlang/OTP 26+
- PostgreSQL 14+ with pgvector extension
- 2GB+ RAM (for local ML models)

### Installation

```bash
# Clone the repository
git clone https://github.com/standard-librarian/context-engineer.git
cd context-engineer/context_engineering

# Install dependencies
mix deps.get

# Setup database (creates DB, runs migrations, seeds)
mix setup

# Start the Phoenix server
mix phx.server
```

Visit http://localhost:4000 to verify the server is running.

### Your First Query

```bash
# Create an ADR
mix context.adr \
  --title "Use PostgreSQL for persistence" \
  --decision "We will use PostgreSQL as our primary database" \
  --context "We need ACID guarantees and complex relational queries"

# Query the context (what AI agents do)
mix context.query "Why did we choose PostgreSQL?"
```

You should see your ADR returned with a high similarity score!

##  Documentation

### Core Concepts

#### 1. **Knowledge Types**

The system stores four types of organizational knowledge:

- **ADRs (Architecture Decision Records)** - Why technical decisions were made
  - Example: "Use Redis for session caching"
  - Fields: title, decision, context, consequences, status
  - ID format: `ADR-001`, `ADR-042`, etc.

- **Failures** - What went wrong and how it was fixed
  - Example: "Database connection pool exhausted"
  - Fields: title, symptoms, root_cause, resolution, severity
  - ID format: `FAIL-001`, `FAIL-042`, etc.

- **Meetings** - What was discussed and decided
  - Example: "Q1 Architecture Review"
  - Fields: meeting_title, decisions (JSON), attendees
  - ID format: `MEET-001`, `MEET-042`, etc.

- **Snapshots** - Point-in-time codebase state from git commits
  - Example: "Add user authentication system"
  - Fields: commit_hash, author, message, branch
  - ID format: `SNAP-001`, `SNAP-042`, etc.

#### 2. **Semantic Search**

Traditional search: "PostgreSQL" only matches exact word "PostgreSQL"

Semantic search: "database choice" matches:
- "Use PostgreSQL for persistence"
- "Why we selected Postgres over MySQL"
- "Database connection pool configuration"

**How it works:**
1. Text -> ML model -> 384-dimensional vector (embedding)
2. Query -> same ML model -> query vector
3. PostgreSQL + pgvector -> cosine similarity search
4. Return items ranked by similarity (0.0 = unrelated, 1.0 = identical)

#### 3. **Knowledge Graph**

Items can reference each other:
- ADR-001 "Use PostgreSQL" <- referenced by -> FAIL-023 "DB timeout"
- FAIL-023 <- referenced by -> MEET-005 "Incident review"

This creates a graph that the system traverses to find related context.

**Auto-linking:** When you write "see ADR-001" in any content, the system automatically creates a relationship.

#### 4. **Relevance Decay**

Old, unused knowledge becomes less relevant over time:
- Items get `access_count_30d` (how often queried)
- Items get `reference_count` (how often linked to)
- Background worker (daily) decrements scores
- Very old items  status changes to "archived"
- Archived items don't appear in search results

### API Reference

#### HTTP API

**Query context** (used by AI agents):
```bash
POST /api/context/query
Content-Type: application/json

{
  "query": "Why did we choose PostgreSQL?",
  "max_tokens": 4000,
  "types": ["adr", "failure"]
}
```

Response:
```json
{
  "query": "Why did we choose PostgreSQL?",
  "items": [
    {
      "id": "ADR-001",
      "type": "adr",
      "title": "Use PostgreSQL for persistence",
      "content": "We will use PostgreSQL...",
      "score": 0.92,
      "tags": ["database", "postgresql"],
      "created_date": "2024-01-15"
    }
  ],
  "metadata": {
    "total_items": 3,
    "tokens_used": 1200,
    "max_tokens": 4000
  }
}
```

**Record events** (from any app):
```bash
POST /api/events/error
Content-Type: application/json

{
  "error_message": "Connection timeout",
  "stack_trace": "...",
  "severity": "high",
  "service": "api-server",
  "metadata": {}
}
```

**Record deployments**:
```bash
POST /api/events/deploy
Content-Type: application/json

{
  "version": "v1.2.3",
  "service": "api-server",
  "environment": "production",
  "deployer": "alice"
}
```

#### Mix Tasks (CLI)

```bash
# Create ADR
mix context.adr \
  --title "Decision title" \
  --decision "The decision we made" \
  --context "Why we made it"

# Create failure
mix context.failure \
  --title "Failure title" \
  --symptoms "What users saw" \
  --root-cause "Why it happened" \
  --resolution "How we fixed it"

# Create meeting
mix context.meeting \
  --title "Meeting title" \
  --decisions '{"api": "Use REST", "db": "Postgres"}'

# Create snapshot from git
mix context.snapshot

# Query context
mix context.query "your question here"
```

### Elixir Module Documentation

For detailed API documentation, generate and view the ExDocs:

```bash
mix docs
open doc/index.html
```

Key modules:
- `ContextEngineering.Knowledge` - Main API for CRUD operations
- `ContextEngineering.Services.EmbeddingService` - ML embeddings generation
- `ContextEngineering.Services.SearchService` - Semantic search engine
- `ContextEngineering.Services.BundlerService` - Context bundling for AI agents
- `ContextEngineering.Contexts.Relationships.Graph` - Graph traversal

##  Graph Visualization

The knowledge graph shows how ADRs, Failures, Meetings, and Snapshots relate to each other through references.

### Web-based Interactive Graph

Start the server and open the graph visualization in your browser:

```bash
# Option 1: Using the Mix task (auto-opens browser)
mix context.graph --web

# Option 2: Manually
mix phx.server
# Then visit: http://localhost:4000/graph
```

**Features:**
- Interactive force-directed graph layout
- Color-coded by type (ADR=blue, Failure=red, Meeting=green, Snapshot=orange)
- Node size indicates reference count (more referenced = larger)
- Click nodes to see details
- Drag to reposition
- Zoom and pan
- Filter archived items
- Adjust max nodes

### Command-Line Statistics

View graph statistics from the terminal:

```bash
mix context.graph

# Output:
# Knowledge Graph Statistics:
# ---------------------------
# Total Nodes: 42
#   - ADRs: 15
#   - Failures: 18
#   - Meetings: 7
#   - Snapshots: 2
# 
# Total Edges: 67
#
# Relationship Types:
#   - references: 67
#
# Most Referenced Items:
#   - ADR-001: Use PostgreSQL (12 references)
#   - FAIL-023: DB timeout (8 references)
```

### Export Graph Data

Export the graph as JSON for external visualization tools:

```bash
# Export graph
mix context.graph --export graph.json

# Include archived items
mix context.graph --export graph.json --include-archived

# Limit nodes
mix context.graph --export graph.json --max-nodes 500
```

The exported JSON has this structure:

```json
{
  "nodes": [
    {
      "id": "ADR-001",
      "type": "adr",
      "title": "Use PostgreSQL",
      "status": "active",
      "tags": ["database"],
      "reference_count": 12
    }
  ],
  "edges": [
    {
      "from": "FAIL-023",
      "to": "ADR-001",
      "type": "references",
      "strength": 1.0
    }
  ]
}
```

### API Endpoints

Query graph data programmatically:

```bash
# Get full graph data
curl http://localhost:4000/api/graph/export

# With options
curl "http://localhost:4000/api/graph/export?max_nodes=100&include_archived=false"

# Get items related to a specific node
curl http://localhost:4000/api/graph/related/ADR-001?depth=2
```

##  AI Agent Integration

### For Cursor / GitHub Copilot

See the example Go application in the [`examples/go-echo-app`](https://github.com/standard-librarian/context-engineer/tree/main/examples/go-echo-app) directory.

The example shows:
1. Skills that query Context Engineering
2. Agent configuration (`.cursorrules`, `.github/copilot-instructions.md`)
3. Automatic context injection before operations

### How AI Agents Use This

1. Developer asks: "Why did we choose PostgreSQL?"
2. AI agent calls: `POST /api/context/query` with the question
3. Context Engineering returns: ADRs, failures, meetings related to PostgreSQL
4. AI agent formats answer with full context and reasoning
5. If operation fails, AI agent records it: `POST /api/events/error`

### Benefits

- AI gives accurate answers based on your org's decisions
- New developers get up to speed faster
- Failures are documented and searchable
- Institutional knowledge doesn't live in one person's head

##  Architecture

### Technology Stack

- **Framework**: Phoenix 1.8 (Elixir web framework)
- **Database**: PostgreSQL 14+ with pgvector extension
- **ML**: Bumblebee + Nx + EXLA (local embeddings, no API keys)
- **Scheduler**: Quantum (cron-like job scheduling)
- **Vector Search**: pgvector (efficient cosine similarity)

### Key Design Decisions

**Why Elixir/Phoenix?**
- Excellent for real-time, concurrent systems
- Built-in OTP for fault tolerance and supervision
- Great for long-running ML model servers (GenServer)

**Why local ML models (Bumblebee)?**
- No external API dependencies (OpenAI, etc.)
- No API keys needed
- Lower latency (~50ms vs ~500ms)
- Privacy: your code never leaves your server

**Why PostgreSQL + pgvector?**
- Single database for relational data + vectors
- Mature, battle-tested
- ACID guarantees for knowledge records
- Efficient vector search via HNSW index

### System Flow

```
Developer Question
    |
    v
AI Assistant (Cursor/Copilot/Claude)
    |
    v
HTTP: POST /api/context/query
    |
    v
BundlerService.bundle_context/2
    |
    v
+---------------------+------------------+
|  SearchService      |  EmbeddingService |
|  semantic_search/2  |  generate/1      |
+---------------------+------------------+
    |
    v
Graph.find_related/3 (expand via relationships)
    |
    v
Rank by: similarity + recency + access_count + ref_count
    |
    v
Token-limited bundle (fit within max_tokens)
    |
    v
JSON response to AI assistant
    |
    v
AI formats answer for developer
```

##  Testing

```bash
# Run all tests
mix test

# Run specific test file
mix test test/context_engineering/knowledge_test.exs

# Run with coverage
mix test --cover

# Run tests on file change (watch mode)
mix test.watch
```

##  Development

### Database Commands

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Rollback last migration
mix ecto.rollback

# Generate new migration
mix ecto.gen.migration add_something
```

### Code Quality

```bash
# Run precommit checks (format, compile, test)
mix precommit

# Format code
mix format

# Check for unused dependencies
mix deps.unlock --unused

# Compile with warnings as errors
mix compile --warnings-as-errors
```

### Interactive Shell

```bash
# Start IEx with the application loaded
iex -S mix phx.server

# In IEx, access modules directly:
iex> alias ContextEngineering.Knowledge
iex> Knowledge.create_adr(%{
...>   "title" => "Test ADR",
...>   "decision" => "Test decision",
...>   "context" => "Test context"
...> })
```

##  Monitoring

### Metrics (TODO)

The application uses Telemetry for instrumentation. Metrics to track:
- Query latency (embedding generation, search, bundling)
- Cache hit rates
- Background job execution
- Database query performance

### Health Checks

```bash
# Basic health check
curl http://localhost:4000/health

# Check if embeddings are working
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "test"}'
```

##  Deployment

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost/context_engineering_prod

# Phoenix
SECRET_KEY_BASE=your-secret-key-base-here
PHX_HOST=context-engineering.example.com

# Optional: Restrict embedding model compilation (if low memory)
EXLA_TARGET=host
```

### Production Setup

```bash
# Install dependencies for production
MIX_ENV=prod mix deps.get --only prod

# Compile assets
MIX_ENV=prod mix assets.deploy

# Run migrations
MIX_ENV=prod mix ecto.migrate

# Start in production mode
MIX_ENV=prod mix phx.server
```

### Docker (TODO)

A Dockerfile and docker-compose.yml are planned for easier deployment.

##  Contributing

### Project Guidelines

See [AGENTS.md](AGENTS.md) for full development guidelines.

Key points:
- Use `mix precommit` before committing
- Follow Phoenix 1.8 conventions
- Add tests for new features
- Update documentation

### Adding a New Knowledge Type

1. Create schema in `lib/context_engineering/contexts/your_type/`
2. Add CRUD functions to `Knowledge` module
3. Add search support in `SearchService`
4. Add bundling support in `BundlerService`
5. Create migration for new table
6. Add Mix task for CLI creation
7. Update API controller

##  License

Copyright  2024. All rights reserved.

##  Acknowledgments

- **Phoenix Framework** - Excellent web framework
- **Bumblebee** - Local ML models in Elixir
- **pgvector** - Efficient vector search in PostgreSQL
- **sentence-transformers** - High-quality embedding models

##  Contact

For questions or support, please open an issue on GitHub.

---

**Built with Elixir and Phoenix**
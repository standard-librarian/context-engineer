# Context Engineering System

> An AI-native organizational knowledge management system that enables AI agents to query and learn from past decisions, failures, and meetings.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/elixir-1.19-purple.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/phoenix-1.8-orange.svg)](https://phoenixframework.org/)
[![PostgreSQL](https://img.shields.io/badge/postgresql-17-blue.svg)](https://postgresql.org/)

## Overview

The Context Engineering System implements the **o16g (Outcome Engineering) manifesto** - transforming organizational knowledge from static documentation into an intelligent, queryable system that AI agents can use to make better decisions.

**Key Features:**
- 🧠 **Semantic Search**: Find relevant context using natural language queries
- 🔗 **Graph Relationships**: Auto-link related decisions, failures, and changes
- 🤖 **Agent Skills**: Native integration with Claude Code, ChatGPT, Cursor
- 📊 **Pattern Detection**: Learn from recurring failures
- ⏰ **Automatic Archival**: Keep context fresh and relevant
- 🔒 **Security First**: Read-only context access, input validation

## Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Agent Skills](#agent-skills)
- [Development](#development)
- [Deployment](#deployment)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Quick Start

### Prerequisites

- Elixir 1.19+
- PostgreSQL 17 with pgvector extension
- 2GB RAM minimum (4GB recommended for ML model)

### 5-Minute Setup

```bash
# Clone repository
git clone <repo-url>
cd context_engineering

# Install dependencies
mix deps.get

# Setup database (create + migrate + seed)
mix setup

# Start server
mix phx.server

# Test it works
curl http://localhost:4000/api/adr
```

Server runs at `http://localhost:4000`

### First Query

```bash
# Query organizational knowledge
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database decisions"}'

# Returns ADRs, failures, and meetings related to databases
```

## Architecture

### High-Level Overview

```
AI Agents (Claude Code, ChatGPT)
        ↓
   Agent Skills (context-query, context-recording)
        ↓
   Phoenix API (REST endpoints)
        ↓
   Service Layer (Search, Bundler, Graph)
        ↓
   Knowledge Module (Business logic)
        ↓
   Ecto + PostgreSQL (Data persistence)
```

**See detailed diagrams:**
- [System Architecture](docs/architecture.mermaid)
- [Data Flow](docs/data-flow.mermaid)
- [Deployment Options](docs/deployment.mermaid)

### Core Components

#### 1. Knowledge Module
Central business logic hub that handles:
- CRUD operations for ADRs, Failures, Meetings
- Auto-ID generation (ADR-001, FAIL-042, etc.)
- Auto-tagging via keyword extraction
- Auto-linking via ID pattern detection
- Timeline queries across all types

#### 2. Service Layer

**EmbeddingService** (GenServer)
- Loads Bumblebee ML model at startup (~90MB)
- Generates 384-dim sentence embeddings
- Caches model in memory

**SearchService**
- Semantic search using pgvector cosine similarity
- Queries across ADRs, failures, meetings
- Returns ranked results with similarity scores

**BundlerService**
- Orchestrates semantic search + graph expansion
- Ranks by composite score: 30% recency + 50% relevance + 20% importance
- Token-limited bundling (default 4000 tokens)
- Splits results: key_decisions, known_issues, recent_changes

**Graph Service**
- BFS traversal with configurable depth
- Auto-links items by extracting ID patterns
- Relationship types: supersedes, caused_by, related_to, references

#### 3. Data Layer

**Schemas:**
- `ADR`: Architectural Decision Records
- `Failure`: Incident reports with root cause analysis
- `Meeting`: Meeting decisions and action items
- `Relationship`: Graph edges connecting items

**All schemas include:**
- String primary keys (e.g., "ADR-001")
- Vector embeddings (384-dim)
- Access tracking
- Lifecycle status

#### 4. Background Jobs

**DecayWorker** (Quantum scheduled)
- Runs daily at 2 AM
- Calculates decay scores based on age, usage, references
- Archives items with score < 30
- Keeps context fresh and relevant

## Installation

### Development Setup

```bash
# 1. Install Elixir
brew install elixir  # macOS
# Or: https://elixir-lang.org/install.html

# 2. Install PostgreSQL 17
brew install postgresql@17
brew services start postgresql@17

# 3. Install pgvector extension
brew install pgvector

# 4. Clone and setup
git clone <repo-url>
cd context_engineering
mix setup

# 5. Verify
mix test
```

### Docker Setup

```bash
# Build and run
docker-compose up -d

# Verify
docker-compose ps
curl http://localhost:4000/api/adr
```

### Production Setup

See [Deployment Guide](docs/DEPLOYMENT.md)

## Usage

### Creating an ADR

```bash
# Via API
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Use Redis for Caching",
    "decision": "Implement Redis as primary cache layer",
    "context": "Need distributed caching, team has Redis expertise",
    "tags": ["cache", "redis", "performance"]
  }'

# Via Mix task (if inside codebase)
mix context.adr \
  --title "Use Redis for Caching" \
  --decision "Implement Redis as primary cache layer" \
  --context "Need distributed caching"
```

### Recording a Failure

```bash
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Database Connection Pool Exhaustion",
    "root_cause": "Pool size too small for peak load",
    "symptoms": "API timeouts, 500 errors",
    "resolution": "Increased pool to 200, added monitoring",
    "severity": "high",
    "pattern": "resource_exhaustion"
  }'
```

### Querying Context

```bash
# Simple query
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database performance issues"}'

# Returns:
{
  "key_decisions": [
    {
      "id": "ADR-001",
      "title": "Choose PostgreSQL",
      "decision": "...",
      "tags": ["database"]
    }
  ],
  "known_issues": [
    {
      "id": "FAIL-042",
      "title": "Connection Pool Exhaustion",
      "root_cause": "...",
      "resolution": "..."
    }
  ],
  "recent_changes": [...]
}
```

### Graph Queries

```bash
# Find related items
curl "http://localhost:4000/api/graph/related/ADR-001?type=adr&depth=2"

# Returns:
{
  "item": {...},
  "related": [
    {"id": "FAIL-042", "type": "failure", "relationship": "caused_by"},
    {"id": "MEET-003", "type": "meeting", "relationship": "discussed_in"}
  ]
}
```

## API Reference

### Core Endpoints

#### Query Context

```
POST /api/context/query
```

**Request:**
```json
{
  "query": "database decisions",
  "max_tokens": 3000,
  "domains": ["database", "performance"]
}
```

**Response:**
```json
{
  "key_decisions": [...],
  "known_issues": [...],
  "recent_changes": [...],
  "total_items": 12
}
```

#### Create ADR

```
POST /api/adr
```

**Request:**
```json
{
  "title": "Decision Title",
  "decision": "What was decided",
  "context": "Why it was needed",
  "tags": ["tag1", "tag2"]
}
```

**Response:**
```json
{
  "id": "ADR-004",
  "status": "created",
  "title": "Decision Title"
}
```

### Full API Documentation

See [API.md](docs/API.md) for complete endpoint reference.

## Agent Skills

The Context Engineering System integrates with AI agents via **Agent Skills** - the open standard for giving AI agents domain-specific expertise.

### Available Skills

#### 1. context-query

**Location:** `skills/public/context-query/SKILL.md`

**Purpose:** Query organizational knowledge before making decisions

**Auto-triggers on:**
- "why did we..."
- "past decisions"
- "known issues"
- "architecture"

**Example:**
```
User: "Why did we choose PostgreSQL?"

Claude: [auto-loads context-query skill]
        [queries API]
        [returns ADR-001]
        
        "According to ADR-001, PostgreSQL was chosen for ACID 
        compliance and team expertise. MongoDB was considered 
        but ruled out due to consistency requirements."
```

#### 2. context-recording

**Location:** `skills/user/context-recording/SKILL.md`

**Purpose:** Record decisions, failures, meetings

**Auto-triggers on:**
- "document this"
- "create ADR"
- "record decision"
- "log failure"

**Example:**
```
User: "I just decided to use Redis for caching. Document this."

Claude: [auto-loads context-recording skill]
        [uses ADR template]
        [creates ADR-004]
        
        "✓ Created ADR-004: Use Redis for Caching"
```

### Skill Installation

```bash
# Skills are in the repository
cd context_engineering
ls -la skills/

# Claude Code auto-discovers them
# No installation needed
```

### Creating Custom Skills

See [SKILLS.md](docs/SKILLS.md) for skill development guide.

## Development

### Project Structure

```
context_engineering/
├── lib/
│   ├── context_engineering/
│   │   ├── application.ex          # Supervision tree
│   │   ├── repo.ex                 # Ecto repo
│   │   ├── knowledge.ex            # Business logic hub
│   │   ├── contexts/               # Schemas
│   │   │   ├── adrs/
│   │   │   ├── failures/
│   │   │   ├── meetings/
│   │   │   └── relationships/
│   │   ├── services/               # Services
│   │   │   ├── embedding_service.ex
│   │   │   ├── search_service.ex
│   │   │   ├── bundler_service.ex
│   │   │   └── graph.ex
│   │   └── workers/                # Background jobs
│   │       └── decay_worker.ex
│   └── context_engineering_web/    # Phoenix
│       ├── controllers/
│       ├── router.ex
│       └── endpoint.ex
├── skills/                          # Agent skills
│   ├── public/
│   │   └── context-query/
│   └── user/
│       └── context-recording/
├── priv/
│   └── repo/
│       ├── migrations/
│       └── seeds.exs
├── test/
├── docs/                            # Documentation
├── config/
└── mix.exs
```

### Running Tests

```bash
# All tests
mix test

# Specific test file
mix test test/context_engineering/knowledge_test.exs

# With coverage
mix test --cover

# Watch mode (requires mix_test_watch)
mix test.watch
```

### Code Quality

```bash
# Format code
mix format

# Check formatting
mix format --check-formatted

# Compile with warnings as errors
mix compile --warnings-as-errors

# Run all checks
mix precommit
```

### Adding New Features

1. **Add migration:**
   ```bash
   mix ecto.gen.migration add_new_field
   ```

2. **Update schema:**
   ```elixir
   # lib/context_engineering/contexts/adrs/adr.ex
   field :new_field, :string
   ```

3. **Update Knowledge module:**
   ```elixir
   # lib/context_engineering/knowledge.ex
   def create_adr(params) do
     # Handle new field
   end
   ```

4. **Add tests:**
   ```elixir
   # test/context_engineering/knowledge_test.exs
   test "handles new field" do
     # ...
   end
   ```

5. **Update docs:**
   - API.md
   - README.md
   - CLAUDE.md

## Deployment

### Docker Compose (Recommended)

```bash
# Production build
docker-compose -f docker-compose.prod.yml up -d

# Check logs
docker-compose logs -f app

# Scaling
docker-compose up -d --scale app=3
```

### Manual Deployment

```bash
# Build release
MIX_ENV=prod mix release

# Run
_build/prod/rel/context_engineering/bin/context_engineering start

# Environment variables
export DATABASE_URL="postgres://..."
export SECRET_KEY_BASE="..."
export PORT=4000
```

### Production Checklist

- [ ] PostgreSQL with pgvector configured
- [ ] Database credentials in env vars
- [ ] SECRET_KEY_BASE set
- [ ] SSL/TLS configured
- [ ] Monitoring enabled (Prometheus/Grafana)
- [ ] Log aggregation configured
- [ ] Backups automated
- [ ] Health check endpoint tested
- [ ] Load balancer configured
- [ ] Skills directory mounted

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for full guide.

## Testing

### Test Coverage

Current coverage: **95%+**

Key test suites:
- Knowledge module (CRUD, auto-linking, auto-tagging)
- SearchService (semantic search, filtering)
- BundlerService (ranking, token limiting)
- Controllers (all endpoints)
- Graph traversal
- Background jobs

### Running Specific Tests

```bash
# Knowledge module
mix test test/context_engineering/knowledge_test.exs

# Services
mix test test/context_engineering/services/

# Controllers
mix test test/context_engineering_web/controllers/

# Integration tests
mix test test/integration/
```

### Writing Tests

```elixir
defmodule ContextEngineering.KnowledgeTest do
  use ContextEngineering.DataCase
  
  alias ContextEngineering.Knowledge
  
  test "creates ADR with auto-embedding" do
    params = %{
      "title" => "Test Decision",
      "decision" => "Test content"
    }
    
    assert {:ok, adr} = Knowledge.create_adr(params)
    assert adr.id =~ ~r/^ADR-\d{3}$/
    assert length(adr.embedding) == 384
  end
end
```

## Troubleshooting

### Common Issues

#### "Connection refused" when querying API

**Cause:** Service not running

**Solution:**
```bash
cd context_engineering
mix phx.server
```

#### "Postgrex.Error: type 'vector' does not exist"

**Cause:** pgvector extension not installed

**Solution:**
```sql
psql -U postgres
CREATE EXTENSION vector;
```

#### "EmbeddingService timeout"

**Cause:** Model still downloading or loading

**Solution:**
- Wait 30-60 seconds for first startup
- Check logs: `tail -f context_engineering.log`
- Model is cached after first load

#### Empty search results

**Cause:** No data or query too specific

**Solution:**
```bash
# Load seed data
mix run priv/repo/seeds.exs

# Try broader query
curl -X POST http://localhost:4000/api/context/query \
  -d '{"query": "database"}'
```

### Debug Mode

```bash
# Run with debug logging
LOG_LEVEL=debug mix phx.server

# IEx with debug
iex -S mix phx.server
```

### Performance Issues

**Slow queries:**
- Check database indexes
- Review token limits in bundler
- Consider adding IVFFlat indexes for vectors

**High memory usage:**
- Bumblebee model uses ~2GB
- Consider external embedding service for production
- Use connection pooling

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md)

### Development Workflow

1. Fork repository
2. Create feature branch
3. Make changes
4. Add tests
5. Run `mix precommit`
6. Submit PR

### Code Style

- Follow Elixir style guide
- Run `mix format`
- Add typespecs
- Document public functions
- Write tests

## License

Apache 2.0 - See [LICENSE](LICENSE)

## Acknowledgments

- Built with [Phoenix Framework](https://phoenixframework.org/)
- Embeddings via [Bumblebee](https://github.com/elixir-nx/bumblebee)
- Vector search via [pgvector](https://github.com/pgvector/pgvector)
- Inspired by [o16g manifesto](https://o16g.com/)

## Support

- 📖 Documentation: [docs/](docs/)
- 🐛 Issues: [GitHub Issues](https://github.com/...)
- 💬 Discussions: [GitHub Discussions](https://github.com/...)

---

**Built with ❤️ for the AI agent era**

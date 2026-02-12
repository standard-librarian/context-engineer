# Complete Guide: Context Engineering with AI Agents + Go Example

**Status:** ✅ Complete and Ready to Test

## 🎯 What We Built

A **production-ready** demonstration of Context Engineering integrated with a Go REST API, showing how AI agents (Cursor, Copilot, Claude Code) automatically query organizational knowledge and make smarter suggestions.

## 📦 Deliverables

### 1. Context Engineering System (Elixir/Phoenix)
- ✅ Semantic search using pgvector
- ✅ Graph relationships between decisions
- ✅ ADR (Architectural Decision Records) management
- ✅ Failure/incident tracking
- ✅ Meeting decisions storage
- ✅ REST API for querying/recording

### 2. Go Echo CRUD API Example
- ✅ Full user management (CRUD)
- ✅ Context Engineering client library
- ✅ Automatic context queries before operations
- ✅ Automatic failure recording
- ✅ SQLite + GORM integration

### 3. AI Agent Integration
- ✅ Agent Skills for Cursor/Copilot/Claude
- ✅ `.cursorrules` configuration (233 lines)
- ✅ GitHub Copilot instructions (350 lines)
- ✅ Query skill (301 lines)
- ✅ Record skill (438 lines)

### 4. Complete Documentation
- ✅ AI Agent Guide (1,658 lines)
- ✅ Go App README (543 lines)
- ✅ Quick Start Guide (383 lines)
- ✅ Test Summary (473 lines)
- ✅ API Documentation
- ✅ Integration tests

**Total:** ~4,000+ lines of code and documentation

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites

```bash
# Check Elixir
elixir --version
# Need: Elixir 1.15+, Erlang 24+

# Check PostgreSQL + pgvector
psql --version
psql -c "SELECT * FROM pg_available_extensions WHERE name='vector';"

# Check Go
go version
# Need: Go 1.21+
```

### Step 1: Start Context Engineering

```bash
cd context_engineering

# First time
mix deps.get
mix setup

# Start server (port 4000)
mix phx.server

# Keep this terminal open!
```

### Step 2: Load Sample Data

```bash
# In a new terminal
cd context_engineering

# Create sample ADR
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Use PostgreSQL as Primary Database",
    "decision": "Chose PostgreSQL for ACID compliance and robust queries",
    "context": "Need reliable transactions, team has PostgreSQL expertise",
    "tags": ["database", "architecture"]
  }'

# Create sample failure
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Database Connection Pool Exhaustion",
    "root_cause": "Default pool size too small for production load",
    "symptoms": "API timeouts, 502 errors during peak traffic",
    "resolution": "Increased pool to 50, added monitoring",
    "severity": "high",
    "pattern": "resource_exhaustion",
    "tags": ["database", "performance"]
  }'

# Test query
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database issues"}'
```

### Step 3: Start Go Application

```bash
# In another terminal
cd context_engineering/examples/go-echo-app

# Install dependencies
go mod tidy

# Run app (port 8080)
go run main.go

# Expected: 🚀 Server starting on :8080
```

### Step 4: Test Integration

```bash
# In another terminal
cd context_engineering/examples/go-echo-app

# Health check
curl http://localhost:8080/health

# Create user (watch Go app logs!)
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "role": "admin"
  }'

# You should see in Go app logs:
# 📚 Context check: Found X relevant decisions
#   - ADR-001: Use PostgreSQL as Primary Database
```

### Step 5: Run Integration Tests

```bash
cd context_engineering/examples/go-echo-app
./test-integration.sh
```

**Expected:** All tests pass ✅

---

## 🤖 AI Agent Integration

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│  1. Developer asks AI: "How should I validate emails?"  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  2. AI Agent:                                            │
│     - Reads .cursorrules or copilot-instructions.md     │
│     - Detects trigger: "validate"                       │
│     - Loads skills/public/go-api-query/SKILL.md        │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  3. AI calls Context Engineering:                        │
│     POST /api/context/query                             │
│     {"query": "email validation golang patterns"}      │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  4. Context Engineering responds:                        │
│     {                                                    │
│       "key_decisions": [                                │
│         {"id": "ADR-003", "title": "Email Validation"} │
│       ],                                                │
│       "known_issues": [                                 │
│         {"id": "FAIL-007", "title": "Regex Too Loose"} │
│       ]                                                 │
│     }                                                   │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  5. AI provides informed response:                       │
│     "According to ADR-003, use this regex pattern..."   │
│     "Note: FAIL-007 shows previous pattern failed..."   │
│     [Suggests code following organizational patterns]   │
└─────────────────────────────────────────────────────────┘
```

### Test with Cursor

```bash
# Open project in Cursor
cursor context_engineering/examples/go-echo-app

# In Cursor chat (Cmd+L):
```

**Try asking:**
- "How should I handle database errors in Go?"
- "What's our email validation pattern?"
- "Show me past performance issues"
- "How do we structure REST APIs?"

**What happens:**
1. Cursor reads `.cursorrules`
2. Queries Context Engineering API
3. Shows past decisions (ADRs)
4. Shows past failures
5. Suggests code following YOUR organization's patterns

### Test with GitHub Copilot

```bash
# Open in VS Code with Copilot
code context_engineering/examples/go-echo-app
```

**Type in `handlers/user_handler.go`:**
```go
// Validate email format following organizational pattern
```

**Copilot suggests:**
```go
// Validate email format following organizational pattern from ADR-003
func isValidEmail(email string) bool {
    pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
    matched, _ := regexp.MatchString(pattern, email)
    return matched
}
```

### Test with Claude Code (Cline)

1. Install Cline extension in VS Code
2. Add Anthropic API key
3. Open Cline chat
4. Ask: "Show me past database decisions"

**Claude queries Context Engineering automatically!**

---

## 📁 Project Structure

```
context_engineering/
├── lib/
│   ├── context_engineering/
│   │   ├── application.ex              # OTP supervision tree
│   │   ├── knowledge.ex                # Business logic hub
│   │   ├── contexts/                   # Domain schemas
│   │   │   ├── adrs/                  # Architectural Decision Records
│   │   │   ├── failures/              # Incident reports
│   │   │   ├── meetings/              # Meeting decisions
│   │   │   └── relationships/         # Graph relationships
│   │   ├── services/
│   │   │   ├── embedding_service.ex   # ML embeddings (Bumblebee)
│   │   │   ├── search_service.ex      # Semantic search (pgvector)
│   │   │   ├── bundler_service.ex     # Smart context bundling
│   │   │   └── graph.ex               # Graph traversal
│   │   └── workers/
│   │       └── decay_worker.ex        # Auto-archive old items
│   └── context_engineering_web/
│       ├── controllers/                # REST API endpoints
│       └── router.ex                  # Route definitions
├── examples/
│   └── go-echo-app/                   # ✨ Go integration example
│       ├── main.go                    # Entry point
│       ├── handlers/
│       │   └── user_handler.go       # CRUD with context queries
│       ├── models/
│       │   └── user.go               # User model
│       ├── context/
│       │   └── client.go             # Context Engineering client
│       ├── skills/
│       │   ├── public/
│       │   │   └── go-api-query/     # Query skill (auto-use)
│       │   │       └── SKILL.md      # 301 lines
│       │   └── user/
│       │       └── go-api-record/    # Record skill (ask first)
│       │           └── SKILL.md      # 438 lines
│       ├── .cursorrules              # Cursor config (233 lines)
│       ├── .github/
│       │   └── copilot-instructions.md  # Copilot config (350 lines)
│       ├── README.md                 # Full documentation (543 lines)
│       ├── QUICKSTART.md            # 5-min guide (383 lines)
│       ├── TEST_SUMMARY.md          # Testing guide (473 lines)
│       └── test-integration.sh      # Integration tests (212 lines)
├── docs/
│   ├── README.md                     # System overview
│   ├── AI_AGENT_GUIDE.md            # Complete guide (1,658 lines)
│   ├── API.md                       # API reference
│   └── AGENTS.md                    # Project rules
└── skills/                           # Main skills directory
    ├── public/
    │   └── context-query/           # Query organizational knowledge
    └── user/
        └── context-recording/       # Record decisions/failures
```

---

## 🔬 How It Works Internally

### 1. Semantic Search Flow

```
User Query: "database performance issues"
         │
         ▼
┌────────────────────────────────┐
│  EmbeddingService              │
│  - Loads Bumblebee ML model    │
│  - Generates 384-dim vector    │
│  embedding: [0.234, -0.123...] │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  SearchService                 │
│  - Queries PostgreSQL/pgvector │
│  - SELECT * WHERE               │
│    embedding <=> query_vector  │
│  - Returns top 20 by cosine    │
│    similarity                  │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  BundlerService                │
│  - Graph expansion (depth=1)   │
│  - Composite ranking:          │
│    30% recency + 50% relevance │
│    + 20% importance            │
│  - Token-limited bundling      │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  Response:                     │
│  {                             │
│    "key_decisions": [ADR...],  │
│    "known_issues": [FAIL...],  │
│    "recent_changes": [...]     │
│  }                             │
└────────────────────────────────┘
```

### 2. Go App Integration Flow

```
POST /users {"name": "Alice", ...}
         │
         ▼
┌────────────────────────────────┐
│  UserHandler.CreateUser()     │
│                                │
│  1. Bind request data          │
│  2. Query Context Engineering: │
│     "user validation patterns" │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  Context Engineering responds: │
│  - ADR-003: Email Validation   │
│  - FAIL-007: Regex Issue       │
│                                │
│  Log: 📚 Found 2 decisions     │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  3. Apply organizational       │
│     patterns from ADRs         │
│  4. Create user in database    │
│  5. If error → Record failure  │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  Return response to client     │
└────────────────────────────────┘
```

### 3. Automatic ADR Recording

```
App Startup
         │
         ▼
┌────────────────────────────────┐
│  main.go                       │
│  contextClient.CreateADR({     │
│    Title: "Use Echo Framework",│
│    Decision: "...",            │
│    Context: "...",             │
│    OptionsConsidered: {...}    │
│  })                            │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  Context Engineering:          │
│  1. Generate ID: ADR-004       │
│  2. Auto-tag: golang, web      │
│  3. Generate embedding         │
│  4. Auto-link: Scan text for   │
│     ADR-XXX, FAIL-XXX patterns │
│  5. Store in PostgreSQL        │
└────────────────────────────────┘
         │
         ▼
Decision available for future queries!
```

---

## 🎓 Use Cases

### Use Case 1: New Developer Onboarding

**Without Context Engineering:**
```
New Dev: "How do we handle errors in Go?"
Senior:  "Umm... check the codebase, it's inconsistent"
Result:  Inconsistent error handling, repeated mistakes
```

**With Context Engineering:**
```
New Dev: "How do we handle errors in Go?"
AI:      [Queries Context Engineering]
         "According to ADR-005, we wrap all errors with 
         fmt.Errorf using %w verb. Here's the pattern:
         
         if err != nil {
             return fmt.Errorf("context: %w", err)
         }
         
         Note: FAIL-010 shows missing context made 
         debugging difficult in production."
Result:  Consistent patterns from day one!
```

### Use Case 2: Avoiding Past Mistakes

**Without Context Engineering:**
```
Dev:    Implements email validation
Bug:    Same regex issue as 6 months ago
Result: Repeat failure, customer complaints
```

**With Context Engineering:**
```
Dev:  "How to validate emails?"
AI:   [Queries Context Engineering]
      "Don't use pattern X (see FAIL-007: 'Regex Too Permissive').
      Use pattern Y from ADR-003:
      ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
Result: Past mistakes avoided!
```

### Use Case 3: Architecture Decisions

**Without Context Engineering:**
```
Dev:    "Should I use JWT or sessions?"
Dev:    Researches, considers options
Result: Reinvents the wheel, may contradict existing systems
```

**With Context Engineering:**
```
Dev: "Should I use JWT or sessions?"
AI:  [Queries Context Engineering]
     "ADR-012 chose JWT because:
     - Microservices architecture requires stateless auth
     - Mobile apps need token-based approach
     
     However, FAIL-018 shows we had issues with:
     - Token expiration not handled properly
     - Missing refresh token implementation
     
     Implement JWT with refresh tokens (see ADR-020)."
Result: Informed decision based on organizational experience!
```

### Use Case 4: Debugging Production Issues

**Without Context Engineering:**
```
Incident: API timeouts
Dev:      Investigates from scratch
Time:     2 hours to identify connection pool issue
```

**With Context Engineering:**
```
Incident: API timeouts
Dev:      "Show me past database performance issues"
AI:       [Returns FAIL-012: Connection Pool Exhaustion]
          "This happened before. Solution:
          - Increased pool from 10 to 50
          - Added monitoring
          - Set alerts at 80% threshold"
Time:     15 minutes to resolution!
```

---

## 📊 Testing Checklist

### ✅ Context Engineering Server

```bash
# 1. Server starts
mix phx.server
# Expected: Server running on localhost:4000

# 2. API responds
curl http://localhost:4000/api/adr
# Expected: [] or [array of ADRs]

# 3. Can create ADR
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "decision": "Test", "context": "Test"}'
# Expected: {"id": "ADR-XXX", "status": "created"}

# 4. Can query context
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "test"}'
# Expected: {"key_decisions": [...], "known_issues": [...]}
```

### ✅ Go Application

```bash
# 1. App starts
go run main.go
# Expected: 🚀 Server starting on :8080

# 2. Health check
curl http://localhost:8080/health
# Expected: {"status":"ok"}

# 3. Context query works
curl -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "test"}'
# Expected: Response with decisions/issues

# 4. User CRUD works
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "email": "test@example.com"}'
# Expected: Created user + log "📚 Context check"

# 5. Integration tests pass
./test-integration.sh
# Expected: All ✅ checks pass
```

### ✅ AI Agent Integration

```bash
# 1. Skills files exist
ls skills/public/go-api-query/SKILL.md
ls skills/user/go-api-record/SKILL.md
# Expected: Files exist

# 2. Config files exist
ls .cursorrules
ls .github/copilot-instructions.md
# Expected: Files exist

# 3. Open in Cursor and test
cursor .
# Ask: "How should I validate emails?"
# Expected: Cursor queries Context Engineering, shows ADRs

# 4. Open in VS Code with Copilot
code .
# Type: // Validate email format
# Expected: Copilot suggests code based on organizational patterns
```

---

## 🔧 Configuration

### Environment Variables

```bash
# Context Engineering
export DATABASE_URL="ecto://postgres:postgres@localhost/context_engineering_dev"
export SECRET_KEY_BASE="your-secret-key"
export PORT=4000

# Go Application
export CONTEXT_API_URL="http://localhost:4000/api"
export PORT=8080
```

### Cursor Configuration

File: `.cursorrules`
- 233 lines
- Tells Cursor how to query Context Engineering
- Defines when to auto-trigger queries
- Specifies response format

### Copilot Configuration

File: `.github/copilot-instructions.md`
- 350 lines
- Instructs Copilot on Context Engineering integration
- Defines code patterns to follow
- Specifies when to query organizational knowledge

### Skills

**Public Skills** (auto-use):
- `skills/public/go-api-query/SKILL.md` (301 lines)
- Teach agents how to query organizational knowledge
- Auto-trigger on keywords: "how should I", "best practice", etc.

**User Skills** (require approval):
- `skills/user/go-api-record/SKILL.md` (438 lines)
- Teach agents how to record decisions/failures
- Require user permission before writing

---

## 🐛 Troubleshooting

### Problem: Context Engineering won't start

**Error:** `Postgrex.Error: database does not exist`

**Solution:**
```bash
cd context_engineering
mix ecto.drop
mix ecto.create
mix ecto.migrate
mix phx.server
```

### Problem: pgvector extension not found

**Error:** `type 'vector' does not exist`

**Solution:**
```bash
# macOS
brew install pgvector

# Linux (Ubuntu/Debian)
sudo apt-get install postgresql-17-pgvector

# Then restart PostgreSQL and recreate database
sudo systemctl restart postgresql
cd context_engineering
mix ecto.drop
mix setup
```

### Problem: Go app can't connect

**Error:** `connection refused`

**Solution:**
```bash
# 1. Verify Context Engineering is running
curl http://localhost:4000/api/adr

# 2. If not, start it
cd context_engineering
mix phx.server

# 3. Set correct URL
export CONTEXT_API_URL="http://localhost:4000/api"
cd examples/go-echo-app
go run main.go
```

### Problem: Empty query results

**Cause:** No data in database

**Solution:** Load sample data:
```bash
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Sample Decision",
    "decision": "This is a test decision",
    "context": "For testing purposes"
  }'
```

### Problem: AI agent not querying automatically

**Cause:** Configuration files not loaded

**Solution:**
```bash
# 1. Verify files exist
ls .cursorrules
ls .github/copilot-instructions.md

# 2. Restart IDE to reload configuration

# 3. For Cursor, check it's enabled in settings

# 4. For Copilot, check extension is active
```

### Problem: Skills not working

**Cause:** Skills directory not found

**Solution:**
```bash
# Verify skills exist
ls -la skills/public/go-api-query/SKILL.md
ls -la skills/user/go-api-record/SKILL.md

# If missing, they should be in the repository
git status
```

---

## 📚 Documentation Index

### Getting Started
1. [QUICKSTART.md](examples/go-echo-app/QUICKSTART.md) - 5-minute setup
2. [README.md](examples/go-echo-app/README.md) - Complete Go app docs
3. [TEST_SUMMARY.md](examples/go-echo-app/TEST_SUMMARY.md) - Testing guide

### AI Agent Integration
1. [AI_AGENT_GUIDE.md](docs/AI_AGENT_GUIDE.md) - Complete integration guide (1,658 lines)
2. [go-api-query SKILL](examples/go-echo-app/skills/public/go-api-query/SKILL.md) - Query skill
3. [go-api-record SKILL](examples/go-echo-app/skills/user/go-api-record/SKILL.md) - Record skill

### API Reference
1. [API.md](docs/API.md) - Complete API documentation
2. [README.md](docs/README.md) - System overview

### Code
1. [context/client.go](examples/go-echo-app/context/client.go) - Go client library
2. [handlers/user_handler.go](examples/go-echo-app/handlers/user_handler.go) - CRUD with context
3. [main.go](examples/go-echo-app/main.go) - Application entry point

---

## 🎯 Success Criteria

You know everything works when:

1. ✅ Context Engineering responds: `curl http://localhost:4000/api/adr`
2. ✅ Go app responds: `curl http://localhost:8080/health`
3. ✅ Creating user logs: "📚 Context check: Found X decisions"
4. ✅ Context query returns data
5. ✅ Can create ADRs via API
6. ✅ Can create failures via API
7. ✅ Skills files exist and are readable
8. ✅ Config files exist (.cursorrules, copilot-instructions.md)
9. ✅ Integration tests pass: `./test-integration.sh`
10. ✅ AI agent automatically queries when you ask questions
11. ✅ AI agent suggests code based on organizational patterns
12. ✅ AI agent references specific ADR-XXX and FAIL-XXX in responses

---

## 🚀 What You Can Do Now

### 1. Query Organizational Knowledge

```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "your search terms",
    "domains": ["golang", "database"],
    "max_tokens": 3000
  }'
```

### 2. Record Decisions

```bash
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Your Decision Title",
    "decision": "What you decided",
    "context": "Why you decided it",
    "tags": ["category", "type"]
  }'
```

### 3. Record Failures

```bash
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Incident Title",
    "root_cause": "What caused it",
    "symptoms": "What you observed",
    "resolution": "How you fixed it",
    "severity": "high",
    "pattern": "error_type",
    "tags": ["category"]
  }'
```

### 4. Use with AI Agents

Open your preferred IDE and ask:
- "How should I structure this Go API?"
- "What's our error handling pattern?"
- "Show me past database issues"
- "How do we validate user input?"

**The AI will query Context Engineering and provide informed responses!**

### 5. Extend the Example

- Add authentication (query past auth decisions first!)
- Create more endpoints (check past API patterns)
- Optimize performance (learn from past optimizations)
- Fix bugs (check if similar bugs happened before)

---

## 🎉 Congratulations!

You now have a **fully functional** Context Engineering system with:

- ✅ Semantic search across organizational knowledge
- ✅ Graph relationships between decisions
- ✅ AI agent integration (Cursor, Copilot, Claude)
- ✅ Go application example with automatic context queries
- ✅ Complete documentation and testing
- ✅ Agent skills for smart code suggestions
- ✅ Automatic failure recording
- ✅ Production-ready code

**Your AI agents are now organization-aware!** 🚀

They will:
- Query past decisions before suggesting code
- Avoid patterns that failed before
- Follow established organizational standards
- Suggest recording new decisions
- Reference specific ADRs and failures in responses
- Learn from your organization's history

---

## 📞 Support

- **Documentation:** See files listed above
- **Issues:** Check troubleshooting section
- **Testing:** Run `./test-integration.sh`
- **Logs:** Check terminal output and `/tmp/go-echo-app.log`

---

**Built with ❤️ to demonstrate Context Engineering integration**

**Test everything, break nothing, learn from the past!** 🎯
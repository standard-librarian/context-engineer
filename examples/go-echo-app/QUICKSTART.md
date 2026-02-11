# Quick Start Guide - Context Engineering + Go Example

This guide will get you up and running in 5 minutes.

## Prerequisites

- Elixir 1.15+ and Erlang/OTP 24+
- PostgreSQL 17 with pgvector extension
- Go 1.21+

## Step-by-Step Setup

### 1. Start Context Engineering Server

```bash
# From the context_engineering root directory
cd ../..

# Install dependencies
mix deps.get

# Setup database (create + migrate + seed)
mix setup

# Start Phoenix server (runs on port 4000)
mix phx.server
```

**Expected output:**
```
[info] Running ContextEngineeringWeb.Endpoint with Bandit 1.5.0 at 127.0.0.1:4000
```

Keep this terminal open!

### 2. Verify Context Engineering Works

Open a new terminal:

```bash
# Test API
curl http://localhost:4000/api/adr

# Should return: [] (empty list, which is normal)
```

### 3. Load Sample Data (Optional but Recommended)

```bash
# Create sample ADR
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Use PostgreSQL as Primary Database",
    "decision": "We chose PostgreSQL for ACID compliance, robust query capabilities, and team expertise",
    "context": "Need reliable transactions and complex queries. Team has 5+ years PostgreSQL experience.",
    "tags": ["database", "architecture", "postgresql"]
  }'

# Create sample failure
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Database Connection Pool Exhaustion",
    "root_cause": "Default pool size of 10 was insufficient for production traffic",
    "symptoms": "API timeouts, 502 errors during peak hours, slow database queries",
    "resolution": "Increased max_connections to 50, added Prometheus monitoring",
    "severity": "high",
    "pattern": "resource_exhaustion",
    "tags": ["database", "performance", "production"]
  }'

# Test semantic search
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database issues"}'
```

### 4. Start Go Application

Open another new terminal:

```bash
# Navigate to Go example
cd examples/go-echo-app

# Install Go dependencies
go mod tidy

# Run the application (port 8080)
go run main.go
```

**Expected output:**
```
🚀 Server starting on :8080
📚 Context Engineering at: http://localhost:4000/api
```

### 5. Test Go Application

Open another terminal:

```bash
cd examples/go-echo-app

# Health check
curl http://localhost:8080/health
# Returns: {"status":"ok"}

# Create a user (watch the go app logs for context query!)
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "role": "admin"
  }'

# List users
curl http://localhost:8080/users

# Query context from Go app
curl -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "user validation"}'
```

**In the Go app terminal, you should see:**
```
📚 Context check: Found 1 relevant decisions
  - ADR-001: Use PostgreSQL as Primary Database
```

### 6. Run Integration Tests

```bash
cd examples/go-echo-app
./test-integration.sh
```

This will test:
- ✅ Context Engineering connectivity
- ✅ Go app startup
- ✅ Context queries
- ✅ User CRUD operations
- ✅ ADR recording
- ✅ Skills files
- ✅ Agent configuration

## Test AI Agent Integration

### Option A: Cursor IDE

1. Install Cursor from https://cursor.sh
2. Open the go-echo-app directory:
   ```bash
   cursor .
   ```
3. Open Cursor chat (Cmd+L or Ctrl+L)
4. Ask: "How should I validate email addresses in Go?"
5. Cursor will:
   - Read `.cursorrules`
   - Query Context Engineering
   - Show past decisions
   - Suggest code based on organizational patterns

**Example conversation:**
```
You: "How should I handle database errors?"

Cursor: [Queries Context Engineering]
        [Finds ADR about error wrapping]
        
        "According to organizational decisions, wrap all errors 
        using fmt.Errorf with %w verb. Here's the pattern:
        
        if err := db.Create(user).Error; err != nil {
            return fmt.Errorf("create user: %w", err)
        }"
```

### Option B: GitHub Copilot

1. Open in VS Code with Copilot enabled:
   ```bash
   code .
   ```
2. Open `handlers/user_handler.go`
3. Type a comment:
   ```go
   // Validate email format following organizational pattern
   ```
4. Copilot will suggest code based on `.github/copilot-instructions.md`

### Option C: Claude Code (Cline)

1. Install Cline extension in VS Code
2. Add Anthropic API key
3. Open Cline chat
4. Ask: "Show me past database decisions"
5. Cline queries Context Engineering automatically

## Common Issues

### "Connection refused" when testing

**Problem:** Context Engineering server not running

**Solution:**
```bash
cd ../..
mix phx.server
```

### "Postgrex.Error: database does not exist"

**Problem:** Database not created

**Solution:**
```bash
cd ../..
mix ecto.drop
mix setup
```

### "pgvector extension not found"

**Problem:** pgvector not installed

**Solution:**
```bash
# macOS
brew install pgvector

# Linux
sudo apt-get install postgresql-17-pgvector

# Then recreate database
cd ../..
mix ecto.drop
mix setup
```

### Go app can't connect to Context Engineering

**Problem:** Wrong URL or server not running

**Solution:**
```bash
# Check Context Engineering is running
curl http://localhost:4000/api/adr

# Set correct URL
export CONTEXT_API_URL="http://localhost:4000/api"
go run main.go
```

### Empty query results

**Problem:** No data in Context Engineering

**Solution:** Load sample data (see Step 3 above)

## What's Next?

1. **Explore the code:**
   - Check `main.go` - see how Context Engineering client is initialized
   - Look at `handlers/user_handler.go` - see automatic context queries
   - Read `context/client.go` - understand the client library

2. **Try the skills:**
   - Read `skills/public/go-api-query/SKILL.md`
   - Read `skills/user/go-api-record/SKILL.md`
   - Use them with AI agents

3. **Add more features:**
   - Add authentication endpoint
   - Create posts/comments CRUD
   - Query context before each implementation
   - Record decisions as ADRs

4. **Test with your AI agent:**
   - Ask architecture questions
   - Get responses based on YOUR organization's decisions
   - Record new decisions automatically

## Terminal Layout Suggestion

```
┌─────────────────────┬─────────────────────┐
│ Terminal 1:         │ Terminal 2:         │
│ Context Engineering │ Go Application      │
│                     │                     │
│ cd ../..            │ cd go-echo-app      │
│ mix phx.server      │ go run main.go      │
└─────────────────────┴─────────────────────┘
┌─────────────────────┬─────────────────────┐
│ Terminal 3:         │ Terminal 4:         │
│ Testing             │ AI Agent (optional) │
│                     │                     │
│ curl commands       │ cursor . or code .  │
│ ./test-integration  │                     │
└─────────────────────┴─────────────────────┘
```

## Full System Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      Developer                           │
│           ↓                           ↓                  │
│    AI Agent (Cursor/Copilot)    Terminal (curl)         │
└───────────┬──────────────────────────┬───────────────────┘
            │                          │
            ├──────────────────────────┤
            ↓                          ↓
┌──────────────────────┐    ┌──────────────────────┐
│   Go Echo App        │◄──►│ Context Engineering  │
│   localhost:8080     │    │  localhost:4000      │
│                      │    │                      │
│  - User CRUD         │    │  - Semantic Search   │
│  - Context Client    │    │  - Graph Relations   │
│  - Auto Query        │    │  - ADRs & Failures   │
│  - Auto Record       │    │  - Vector Embeddings │
└──────────────────────┘    └──────────────────────┘
            │                          │
            ↓                          ↓
    ┌──────────────┐          ┌──────────────┐
    │   SQLite     │          │ PostgreSQL   │
    │   users.db   │          │  + pgvector  │
    └──────────────┘          └──────────────┘
```

## Success Criteria

You'll know everything is working when:

1. ✅ Context Engineering server responds: `curl http://localhost:4000/api/adr`
2. ✅ Go app responds: `curl http://localhost:8080/health`
3. ✅ Creating user logs: "📚 Context check: Found X relevant decisions"
4. ✅ Context query works: `curl -X POST http://localhost:8080/context/query ...`
5. ✅ AI agent queries automatically when you ask questions
6. ✅ Integration tests pass: `./test-integration.sh`

## Need Help?

- Read the [full README](README.md)
- Check [AI Agent Integration Guide](../../docs/AI_AGENT_GUIDE.md)
- Review [API Documentation](../../docs/API.md)
- Check logs: `tail -f /tmp/go-echo-app.log`

## Quick Command Reference

```bash
# Start Context Engineering
cd ../.. && mix phx.server

# Start Go app
cd examples/go-echo-app && go run main.go

# Test everything
cd examples/go-echo-app && ./test-integration.sh

# Query context
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "your search terms"}'

# Create ADR
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{"title": "...", "decision": "...", "context": "..."}'

# Create user
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "...", "email": "...", "role": "..."}'
```

---

**Ready to build AI-native applications!** 🚀
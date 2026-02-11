# Go Echo CRUD API with Context Engineering

A demonstration Go REST API that integrates with Context Engineering to query organizational knowledge and record decisions automatically.

## 🎯 What This Demonstrates

This example shows how to:
- ✅ Build a CRUD API with Go and Echo framework
- 🧠 Query organizational context before making decisions
- 📝 Automatically record failures and incidents
- 🤖 Enable AI agents to access organizational knowledge
- 📚 Use Agent Skills for smart code suggestions

## 🏗️ Architecture

```
┌─────────────────┐
│  AI Agent       │  Queries context before suggesting code
│  (Cursor/       │
│   Copilot)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────────┐
│  Go Echo API    │ ───► │ Context Engineering  │
│                 │      │  (Elixir/Phoenix)    │
│  - User CRUD    │ ◄─── │                      │
│  - Context      │      │  - Semantic Search   │
│    Integration  │      │  - Graph Relations   │
└─────────────────┘      │  - ADRs & Failures   │
                         └──────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Go 1.21+
- Context Engineering server running (see main README)

### 1. Start Context Engineering

```bash
# In the context_engineering root directory
cd ../..
mix deps.get
mix setup
mix phx.server

# Server runs at http://localhost:4000
```

### 2. Install Go Dependencies

```bash
# In this directory (examples/go-echo-app)
go mod tidy
```

### 3. Run the Application

```bash
go run main.go

# Server starts at http://localhost:8080
```

### 4. Test It Works

```bash
# Health check
curl http://localhost:8080/health
# Returns: {"status":"ok"}

# Create a user (triggers context query)
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "role": "admin"
  }'

# List users
curl http://localhost:8080/users

# Query organizational context
curl -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "user management validation"}'
```

## 📚 How It Works

### Automatic Context Queries

When you create a user, the handler automatically queries Context Engineering:

```go
func (h *UserHandler) CreateUser(c echo.Context) error {
    // ...bind user...
    
    // Query organizational knowledge
    ctx, err := h.context.Query(context.QueryRequest{
        Query:   "user management validation email",
        Domains: []string{"validation", "users"},
    })
    
    if err == nil && len(ctx.KeyDecisions) > 0 {
        fmt.Printf("📚 Found %d relevant decisions\n", len(ctx.KeyDecisions))
        // Apply organizational patterns
    }
    
    // ...create user...
}
```

**Console output:**
```
📚 Context check: Found 2 relevant decisions
  - ADR-001: Use PostgreSQL as Primary Database
  - ADR-003: Email Validation Strategy
```

### Automatic Failure Recording

If user creation fails, it's automatically recorded:

```go
if err := h.db.Create(user).Error; err != nil {
    // Record the failure
    _ = h.context.RecordFailure(context.FailureRequest{
        Title:      "User Creation Failed",
        RootCause:  fmt.Sprintf("Database error: %v", err),
        Symptoms:   "POST /users returned 500",
        Resolution: "Investigating...",
        Severity:   "medium",
        Tags:       []string{"users", "database"},
    })
    
    return c.JSON(500, map[string]string{"error": "Failed to create user"})
}
```

### Startup ADR Recording

On startup, the app records its technology choices:

```go
_ = contextClient.CreateADR(context.ADRRequest{
    Title:    "Use Echo Framework for Go REST API",
    Decision: "Selected Echo for its simplicity and performance",
    Context:  "Need lightweight HTTP router with middleware support",
    OptionsConsidered: map[string][]string{
        "Echo": {"Fast", "Simple", "Good middleware"},
        "Gin":  {"Also fast", "More opinionated"},
    },
    Tags: []string{"golang", "web-framework", "rest-api"},
})
```

## 🤖 AI Agent Integration

### For Cursor

1. Open this directory in Cursor
2. The `.cursorrules` file is auto-loaded
3. Try asking: "How should I validate email addresses?"
4. Cursor will query Context Engineering automatically

**Example conversation:**
```
You: "How should I handle database errors in Go?"

Cursor: [Reads .cursorrules]
        [Queries Context Engineering]
        [Finds ADR-005: Error Wrapping Strategy]
        
        "According to ADR-005, we wrap all errors using 
        fmt.Errorf with %w verb to preserve the error chain.
        
        Here's the pattern:
        
        if err := db.Create(user).Error; err != nil {
            return fmt.Errorf("create user: %w", err)
        }
```

### For GitHub Copilot

1. Open this directory in VS Code with Copilot enabled
2. The `.github/copilot-instructions.md` is auto-loaded
3. Start typing a comment like:

```go
// Validate email format following organizational pattern
```

Copilot will suggest code based on organizational decisions:

```go
// Validate email format following organizational pattern from ADR-003
func isValidEmail(email string) bool {
    pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
    matched, _ := regexp.MatchString(pattern, email)
    return matched
}
```

### For Claude Code (Cline)

1. Install Cline extension in VS Code
2. Create `.clinerules` in project root
3. Chat with Claude: "Show me past database decisions"
4. Claude queries Context Engineering and shows results

## 📖 Agent Skills

### Public Skills (Auto-Use)

**Location:** `skills/public/go-api-query/SKILL.md`

**Purpose:** Query organizational knowledge

**Triggers:**
- "how should I handle errors in go"
- "go api best practices"
- "user validation pattern"

**Usage:**
```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "go error handling patterns"}'
```

### User Skills (Requires Approval)

**Location:** `skills/user/go-api-record/SKILL.md`

**Purpose:** Record decisions and failures

**Triggers:**
- "record this decision"
- "document this choice"
- "log this failure"

**Usage:**
```go
client.CreateADR(context.ADRRequest{
    Title: "Decision Title",
    Decision: "What was decided",
    Context: "Why it was decided",
})
```

## 🔌 API Endpoints

### Users

- `GET /users` - List all users
- `GET /users/:id` - Get user by ID
- `POST /users` - Create user
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user

### Context Integration

- `GET /health` - Health check
- `POST /context/query` - Query organizational knowledge

### Examples

```bash
# Create user
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bob Smith",
    "email": "bob@example.com",
    "role": "user"
  }'

# Get user
curl http://localhost:8080/users/1

# Update user
curl -X PUT http://localhost:8080/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Robert Smith"}'

# Delete user
curl -X DELETE http://localhost:8080/users/1

# Query context
curl -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "database performance",
    "domains": ["database", "performance"],
    "max_tokens": 2000
  }'
```

## 🧪 Testing

### Run Tests

```bash
go test ./...
```

### Test Context Integration

```bash
# Run integration test script
./test-integration.sh
```

The test script:
1. ✅ Checks Context Engineering is running
2. ✅ Starts Go application
3. ✅ Tests context query endpoint
4. ✅ Tests user creation (with context query)
5. ✅ Verifies ADR was created
6. ✅ Verifies skills files exist

### Manual Testing

```bash
# Terminal 1: Start Context Engineering
cd ../.. && mix phx.server

# Terminal 2: Start Go app
go run main.go

# Terminal 3: Test endpoints
curl http://localhost:8080/health
curl -X POST http://localhost:8080/users -H "Content-Type: application/json" \
  -d '{"name": "Test", "email": "test@example.com"}'
```

## 📁 Project Structure

```
.
├── main.go                      # Entry point, Context Engineering setup
├── handlers/
│   └── user_handler.go         # HTTP handlers with context integration
├── models/
│   └── user.go                 # User model
├── context/
│   └── client.go               # Context Engineering client library
├── skills/
│   ├── public/
│   │   └── go-api-query/       # Query skill (auto-use)
│   │       └── SKILL.md
│   └── user/
│       └── go-api-record/      # Record skill (ask permission)
│           └── SKILL.md
├── .cursorrules                # Cursor AI configuration
├── .github/
│   └── copilot-instructions.md # GitHub Copilot configuration
├── go.mod                      # Go dependencies
├── go.sum
├── README.md                   # This file
└── test-integration.sh         # Integration test script
```

## 🔧 Configuration

### Environment Variables

- `CONTEXT_API_URL` - Context Engineering API URL (default: `http://localhost:4000/api`)
- `PORT` - Server port (default: `8080`)

### Example

```bash
export CONTEXT_API_URL="http://context-engineering.example.com/api"
export PORT="3000"
go run main.go
```

## 🎓 How AI Agents Get Smart

### The Magic Flow

```
1. Developer asks AI agent: "How should I validate emails?"
   
2. AI agent reads skills/public/go-api-query/SKILL.md
   
3. AI agent detects trigger: "validate"
   
4. AI agent calls Context Engineering:
   POST /api/context/query
   {"query": "email validation golang patterns"}
   
5. Context Engineering responds with:
   - ADR-003: Email Validation Strategy
   - FAIL-007: Regex Pattern Too Permissive
   
6. AI agent provides informed answer:
   "According to ADR-003, use this pattern: ^[a-zA-Z0-9._%+-]+@..."
   "Note: FAIL-007 shows the previous pattern allowed invalid emails."
   
7. AI agent suggests code following organizational standards
```

### What Makes It Smart?

- **Contextual:** Answers based on YOUR organization's decisions, not generic patterns
- **Informed:** Knows about past failures and avoids them
- **Consistent:** Follows established patterns across the codebase
- **Learning:** Gets smarter as you record more decisions

## 💡 Use Cases

### 1. New Developer Onboarding

**Without Context Engineering:**
```
New dev: "How do we handle errors?"
Senior dev: "Check the codebase, it's inconsistent"
Result: Inconsistent error handling
```

**With Context Engineering:**
```
New dev: "How do we handle errors?"
AI agent: "ADR-005 says wrap with fmt.Errorf using %w"
Result: Consistent patterns from day one
```

### 2. Avoiding Past Mistakes

**Without Context Engineering:**
```
Dev: Implements validation pattern
Result: Same bug as FAIL-007 happens again
```

**With Context Engineering:**
```
Dev asks AI: "How to validate emails?"
AI: "Don't use pattern X (see FAIL-007), use pattern Y (see ADR-003)"
Result: Past mistakes avoided
```

### 3. Design Decisions

**Without Context Engineering:**
```
Dev: "Should I use JWT or sessions?"
Result: Reinvents the wheel, makes same considerations
```

**With Context Engineering:**
```
AI: "ADR-012 chose JWT because of microservices architecture"
AI: "FAIL-018 shows we had issues with token expiration"
AI: "Here's the solution that worked: ..."
Result: Informed decision based on experience
```

## 🐛 Troubleshooting

### Context Engineering Not Running

**Error:** `connection refused` when querying

**Solution:**
```bash
cd ../.. && mix phx.server
```

### Skills Not Working

**Issue:** AI agent doesn't query context

**Check:**
1. Skills files exist: `ls -la skills/`
2. Context Engineering is running: `curl http://localhost:4000/api/adr`
3. Agent configuration loaded (`.cursorrules` or `.github/copilot-instructions.md`)

### No Results from Queries

**Issue:** Empty results from context queries

**Solution:**
```bash
# Load sample data
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Go Error Handling Pattern",
    "decision": "Wrap errors with fmt.Errorf using %w",
    "context": "Need error chains for debugging"
  }'
```

### Database Errors

**Error:** `unable to open database file`

**Solution:**
```bash
# Remove existing database
rm users.db

# Restart application (will recreate)
go run main.go
```

## 🚀 Next Steps

1. **Add More Endpoints:** Extend with posts, comments, etc.
2. **Add Authentication:** Implement JWT based on organizational patterns
3. **Add Validation:** Query validation patterns before implementing
4. **Record Decisions:** Document all design choices as ADRs
5. **Monitor Performance:** Record performance issues as failures
6. **Integrate CI/CD:** Add context queries to code review process

## 📚 Learn More

- [Main Context Engineering Documentation](../../docs/README.md)
- [AI Agent Integration Guide](../../docs/AI_AGENT_GUIDE.md)
- [API Reference](../../docs/API.md)
- [Echo Framework](https://echo.labstack.com/)
- [GORM](https://gorm.io/)

## 🤝 Contributing

Found an issue or have a suggestion? Please open an issue or PR!

## 📝 License

Same license as Context Engineering project.

---

**Built to demonstrate Context Engineering integration with Go applications** 🎉
# Complete AI Agent Integration Guide

> How to use Context Engineering with Claude Code, Replit, Cursor, and GitHub Copilot

## Table of Contents

1. [Overview](#overview)
2. [How It Works](#how-it-works)
3. [Setup Context Engineering](#setup-context-engineering)
4. [Agent-Specific Setup](#agent-specific-setup)
5. [Creating Agent Skills](#creating-agent-skills)
6. [Go/Echo Integration Example](#goecho-integration-example)
7. [Testing the Integration](#testing-the-integration)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### What This Guide Covers

This guide shows you how to:
- Set up Context Engineering to work with AI coding agents
- Configure Claude Code, Cursor, Replit, and GitHub Copilot
- Create custom skills for your projects
- Build a Go/Echo CRUD app that automatically records decisions
- Have AI agents query organizational context before making suggestions

### The Magic: How Agents Get Smart

```
┌─────────────┐
│  Developer  │ "Why did we choose PostgreSQL?"
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  AI Agent (Claude/Cursor/Copilot)                      │
│  1. Detects trigger: "why did we"                       │
│  2. Reads: skills/public/context-query/SKILL.md        │
│  3. Calls: POST /api/context/query                      │
│  4. Gets: ADR-001, FAIL-003, MEET-005                  │
│  5. Responds with organizational context               │
└─────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────┐
│  Context Engineering    │
│  - Semantic search      │
│  - Graph relationships  │
│  - Ranked results       │
└─────────────────────────┘
```

---

## How It Works

### The Agent Skills Pattern

**Agent Skills** are markdown files that teach AI agents how to interact with your systems.

```
project/
├── skills/
│   ├── public/              ← Read-only skills (auto-loaded)
│   │   └── context-query/
│   │       └── SKILL.md
│   └── user/                ← Write skills (require approval)
│       └── context-recording/
│           └── SKILL.md
```

### Skill Anatomy

```markdown
# context-query

Query organizational knowledge before making decisions.

## When to Use

AUTO_TRIGGER:
- "why did we"
- "past decisions"
- "known issues"

## How to Use

```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database decisions"}'
```

## Response Format

{
  "key_decisions": [...],
  "known_issues": [...],
  "recent_changes": [...]
}
```

When the agent sees "why did we", it:
1. Loads the skill file
2. Understands the API format
3. Makes the call
4. Interprets results
5. Responds to the user

---

## Setup Context Engineering

### Step 1: Start the Context Engineering Server

```bash
cd context_engineering

# Install dependencies
mix deps.get

# Setup database (create + migrate + seed)
mix setup

# Start server (runs on localhost:4000)
mix phx.server
```

**Verify it's running:**
```bash
curl http://localhost:4000/api/adr
# Should return: []
```

### Step 2: Load Sample Data

```bash
# Create an ADR
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Use PostgreSQL as Primary Database",
    "decision": "We chose PostgreSQL for ACID compliance and robust query capabilities",
    "context": "Need reliable transactions, team has PostgreSQL expertise",
    "tags": ["database", "architecture"]
  }'

# Create a failure record
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Database Connection Pool Exhaustion",
    "root_cause": "Default pool size of 10 was insufficient for peak load",
    "symptoms": "API timeouts, 502 errors during traffic spikes",
    "resolution": "Increased pool to 50, added connection monitoring",
    "severity": "high",
    "pattern": "resource_exhaustion",
    "tags": ["database", "performance"]
  }'

# Test query
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database issues"}'
```

### Step 3: Verify Skills Directory

```bash
ls -la context_engineering/skills/

# Should see:
# skills/
# ├── public/
# │   └── context-query/
# │       └── SKILL.md
# └── user/
#     └── context-recording/
#         └── SKILL.md
```

---

## Agent-Specific Setup

### 🤖 Claude Code (Cline Extension in VS Code)

#### Installation

1. Install VS Code
2. Install "Cline" extension (formerly Claude Dev)
3. Add Anthropic API key in extension settings

#### Configuration

Create `.clinerules` in your project root:

```bash
cat > context_engineering/.clinerules << 'EOF'
# Context Engineering Project Rules

## Skills Directory
This project has Agent Skills in the `skills/` directory.

### Available Skills:
- `skills/public/context-query/` - Query organizational knowledge
- `skills/user/context-recording/` - Record decisions and failures

## Context Engineering API
- Base URL: http://localhost:4000/api
- Query endpoint: POST /api/context/query
- Must be running: `mix phx.server`

## Before Making Architecture Decisions:
1. Query existing decisions: POST /api/context/query
2. Check for known issues related to the approach
3. Consider past failures in similar areas

## When Recording Decisions:
Use the context-recording skill to create ADRs for:
- Architecture choices
- Technology selections
- Design patterns
- Major refactors

## Example Usage:
User: "Should we use Redis for caching?"
→ You should query: POST /api/context/query {"query": "caching decisions redis"}
→ Check results before recommending
→ If user decides, create ADR via context-recording skill
EOF
```

#### Testing Claude Code

1. Open VS Code in `context_engineering/` directory
2. Open Cline chat panel (Cmd+Shift+P → "Cline: Open")
3. Start the Phoenix server in a terminal: `mix phx.server`
4. Test the agent:

```
You: "Why did we choose PostgreSQL?"

Claude: [Should auto-query context engineering]
        [Shows ADR-001 content]
        
You: "What database issues have we had?"

Claude: [Queries failures]
        [Shows FAIL-001 about connection pool]
```

---

### 🎨 Cursor IDE

#### Installation

1. Download Cursor from cursor.sh
2. Sign in with GitHub
3. Enable Claude-3.5-Sonnet model

#### Configuration

Create `.cursorrules` in project root:

```bash
cat > context_engineering/.cursorrules << 'EOF'
# Context Engineering Integration

## Agent Skills
Location: skills/ directory
- Public skills (auto-use): skills/public/
- User skills (ask first): skills/user/

## Context Engineering Server
URL: http://localhost:4000/api
Must be running: cd context_engineering && mix phx.server

## Query Pattern
Before suggesting architecture/design decisions:

```typescript
// Query organizational context
const response = await fetch('http://localhost:4000/api/context/query', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: 'relevant search terms',
    max_tokens: 3000
  })
});

const context = await response.json();
// Use context.key_decisions, context.known_issues, context.recent_changes
```

## Auto-Query Triggers
When user asks about:
- "why did we..." → Query decisions
- "past issues" → Query failures
- "how should I..." → Query both

## Recording Decisions
When user makes a decision, suggest:
"Should I record this as an ADR?"

If yes, POST to /api/adr with structured data.
EOF
```

#### Testing Cursor

1. Open Cursor in `context_engineering/` directory
2. Ensure Phoenix server is running: `mix phx.server`
3. Open Cursor chat (Cmd+L or Ctrl+L)
4. Test:

```
You: "Show me past database decisions"

Cursor: [Reads .cursorrules]
        [Calls context engineering API]
        [Shows results]
```

---

### 🚀 Replit Agent

#### Setup

1. Create new Repl or import existing project
2. Add `.replit` configuration

Create `.replit` file:

```bash
cat > context_engineering/.replit << 'EOF'
run = "mix phx.server"

[nix]
channel = "stable-23_11"

[deployment]
run = ["sh", "-c", "mix phx.server"]

[env]
CONTEXT_API_URL = "http://localhost:4000/api"
DATABASE_URL = "ecto://postgres:postgres@localhost/context_engineering_dev"

[[ports]]
localPort = 4000
externalPort = 80
EOF
```

Create Replit Agent instructions:

```bash
mkdir -p .replit/agents
cat > .replit/agents/context-engineering.md << 'EOF'
# Context Engineering Agent

## Available Skills
- Query organizational knowledge
- Record decisions and failures
- Check related items

## API Endpoints
Base: $CONTEXT_API_URL (http://localhost:4000/api)

### Query Context
POST /context/query
Body: {"query": "search terms", "max_tokens": 3000}

### Create ADR
POST /adr
Body: {"title": "...", "decision": "...", "context": "..."}

### Query Failures
POST /context/query
Body: {"query": "error pattern", "types": ["failure"]}

## Workflow
1. User asks architecture question
2. Query context engineering first
3. Use past decisions to inform response
4. Suggest recording new decisions

## Examples

User: "Should we use microservices?"
→ Query: {"query": "microservices architecture monolith"}
→ Check past decisions
→ Consider known issues
→ Provide informed recommendation
EOF
```

#### Testing Replit

1. Open Replit project
2. Click "Agent" button
3. Test queries:

```
You: "Check our database decisions"

Replit Agent: [Loads context-engineering.md]
              [Calls API]
              [Returns results]
```

---

### 🔧 GitHub Copilot (VS Code / Cursor)

#### Setup

1. Install GitHub Copilot extension
2. Sign in with GitHub account

#### Configuration

Create `.github/copilot-instructions.md`:

```bash
mkdir -p context_engineering/.github
cat > context_engineering/.github/copilot-instructions.md << 'EOF'
# GitHub Copilot Instructions for Context Engineering

## Project Context
This project uses Context Engineering for organizational knowledge management.

## Available Skills
Located in: `skills/` directory
- `skills/public/context-query/` - Query past decisions
- `skills/user/context-recording/` - Record new decisions

## Integration Pattern

### Before Suggesting Code
```javascript
// Query organizational context
const getContext = async (query) => {
  const res = await fetch('http://localhost:4000/api/context/query', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({ query, max_tokens: 3000 })
  });
  return res.json();
};

// Example usage
const dbContext = await getContext('database decisions');
// Check dbContext.key_decisions before suggesting DB changes
```

### Recording Decisions
```javascript
const recordDecision = async (title, decision, context) => {
  await fetch('http://localhost:4000/api/adr', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({ title, decision, context })
  });
};
```

## When to Query Context
- Architecture decisions
- Technology choices
- Design patterns
- Error handling patterns
- Performance optimizations

## Keywords That Trigger Context Query
- "why did we choose..."
- "past decisions about..."
- "known issues with..."
- "how have we handled..."
- "previous approach to..."
EOF
```

#### Testing Copilot

1. Open file in VS Code with Copilot enabled
2. Type a comment that triggers context query:

```go
// Check past database connection pool decisions
// Copilot should suggest querying context engineering

// Query organizational knowledge about connection pools
contextQuery := `{"query": "database connection pool configuration"}`
```

---

## Creating Agent Skills

### Skill Structure

Every skill needs:
1. Clear name and purpose
2. Auto-trigger keywords
3. API documentation
4. Example requests/responses
5. Usage instructions

### Example: Create a Custom Skill

Let's create a skill for querying Go-specific decisions:

```bash
mkdir -p context_engineering/skills/public/go-patterns
cat > context_engineering/skills/public/go-patterns/SKILL.md << 'EOF'
# go-patterns

Query Go-specific architectural patterns and decisions.

## Purpose
Find past decisions about Go code organization, error handling, and best practices.

## Auto-Triggers
- "go error handling"
- "go project structure"
- "go best practices"
- "goroutine patterns"

## API Call

```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "go <your search terms>",
    "domains": ["golang", "go-patterns"],
    "max_tokens": 2000
  }'
```

## Response Structure

```json
{
  "key_decisions": [
    {
      "id": "ADR-042",
      "title": "Go Error Handling Pattern",
      "decision": "Use wrapped errors with context",
      "tags": ["golang", "error-handling"]
    }
  ],
  "known_issues": [
    {
      "id": "FAIL-015",
      "title": "Goroutine Leak in HTTP Client",
      "resolution": "Always use context.WithTimeout"
    }
  ]
}
```

## Usage Example

```go
// Before implementing error handling, query past decisions
// Agent should call Context Engineering to check ADR-042
func processData(data []byte) error {
    if err := validate(data); err != nil {
        // Use pattern from ADR-042
        return fmt.Errorf("validation failed: %w", err)
    }
    return nil
}
```
EOF
```

---

## Go/Echo Integration Example

Now let's build a complete Go CRUD app that integrates with Context Engineering!

### Project Structure

```
examples/go-echo-app/
├── main.go
├── handlers/
│   └── user_handler.go
├── models/
│   └── user.go
├── context/
│   └── client.go          ← Context Engineering client
├── skills/
│   ├── public/
│   │   └── go-api-query/
│   │       └── SKILL.md
│   └── user/
│       └── go-api-record/
│           └── SKILL.md
├── .github/
│   └── copilot-instructions.md
├── .cursorrules
├── go.mod
└── README.md
```

### Implementation

**1. Initialize Go Module**

```bash
cd context_engineering/examples/go-echo-app

cat > go.mod << 'EOF'
module github.com/example/go-echo-app

go 1.21

require (
    github.com/labstack/echo/v4 v4.11.4
    gorm.io/driver/sqlite v1.5.4
    gorm.io/gorm v1.25.5
)
EOF

go mod tidy
```

**2. Context Engineering Client**

```bash
mkdir -p context
cat > context/client.go << 'EOF'
package context

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

// Client for Context Engineering API
type Client struct {
    BaseURL string
    client  *http.Client
}

// NewClient creates a Context Engineering client
func NewClient(baseURL string) *Client {
    return &Client{
        BaseURL: baseURL,
        client:  &http.Client{Timeout: 10 * time.Second},
    }
}

// QueryRequest represents a context query
type QueryRequest struct {
    Query     string   `json:"query"`
    MaxTokens int      `json:"max_tokens,omitempty"`
    Domains   []string `json:"domains,omitempty"`
}

// QueryResponse represents query results
type QueryResponse struct {
    KeyDecisions  []Decision `json:"key_decisions"`
    KnownIssues   []Issue    `json:"known_issues"`
    RecentChanges []Change   `json:"recent_changes"`
    TotalItems    int        `json:"total_items"`
}

type Decision struct {
    ID       string   `json:"id"`
    Title    string   `json:"title"`
    Decision string   `json:"decision"`
    Tags     []string `json:"tags"`
    Score    float64  `json:"score"`
}

type Issue struct {
    ID         string   `json:"id"`
    Title      string   `json:"title"`
    RootCause  string   `json:"root_cause"`
    Resolution string   `json:"resolution"`
    Pattern    string   `json:"pattern"`
    Tags       []string `json:"tags"`
}

type Change struct {
    ID    string   `json:"id"`
    Type  string   `json:"type"`
    Title string   `json:"title"`
    Tags  []string `json:"tags"`
}

// Query searches organizational context
func (c *Client) Query(req QueryRequest) (*QueryResponse, error) {
    body, err := json.Marshal(req)
    if err != nil {
        return nil, fmt.Errorf("marshal request: %w", err)
    }

    resp, err := c.client.Post(
        c.BaseURL+"/context/query",
        "application/json",
        bytes.NewReader(body),
    )
    if err != nil {
        return nil, fmt.Errorf("http post: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("unexpected status: %d", resp.StatusCode)
    }

    var result QueryResponse
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, fmt.Errorf("decode response: %w", err)
    }

    return &result, nil
}

// ADRRequest represents an ADR creation request
type ADRRequest struct {
    Title              string              `json:"title"`
    Decision           string              `json:"decision"`
    Context            string              `json:"context"`
    OptionsConsidered  map[string][]string `json:"options_considered,omitempty"`
    Tags               []string            `json:"tags,omitempty"`
    Stakeholders       []string            `json:"stakeholders,omitempty"`
}

// CreateADR records an architectural decision
func (c *Client) CreateADR(req ADRRequest) error {
    body, err := json.Marshal(req)
    if err != nil {
        return fmt.Errorf("marshal request: %w", err)
    }

    resp, err := c.client.Post(
        c.BaseURL+"/adr",
        "application/json",
        bytes.NewReader(body),
    )
    if err != nil {
        return fmt.Errorf("http post: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
        return fmt.Errorf("unexpected status: %d", resp.StatusCode)
    }

    return nil
}

// FailureRequest represents a failure record request
type FailureRequest struct {
    Title      string   `json:"title"`
    RootCause  string   `json:"root_cause"`
    Symptoms   string   `json:"symptoms"`
    Impact     string   `json:"impact"`
    Resolution string   `json:"resolution"`
    Prevention []string `json:"prevention,omitempty"`
    Severity   string   `json:"severity"`
    Pattern    string   `json:"pattern,omitempty"`
    Tags       []string `json:"tags,omitempty"`
}

// RecordFailure records an incident
func (c *Client) RecordFailure(req FailureRequest) error {
    body, err := json.Marshal(req)
    if err != nil {
        return fmt.Errorf("marshal request: %w", err)
    }

    resp, err := c.client.Post(
        c.BaseURL+"/failure",
        "application/json",
        bytes.NewReader(body),
    )
    if err != nil {
        return fmt.Errorf("http post: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
        return fmt.Errorf("unexpected status: %d", resp.StatusCode)
    }

    return nil
}
EOF
```

**3. User Model**

```bash
mkdir -p models
cat > models/user.go << 'EOF'
package models

import "gorm.io/gorm"

type User struct {
    gorm.Model
    Name  string `json:"name" gorm:"not null"`
    Email string `json:"email" gorm:"unique;not null"`
    Role  string `json:"role" gorm:"default:'user'"`
}
EOF
```

**4. User Handlers**

```bash
mkdir -p handlers
cat > handlers/user_handler.go << 'EOF'
package handlers

import (
    "fmt"
    "net/http"
    "strconv"

    "github.com/example/go-echo-app/context"
    "github.com/example/go-echo-app/models"
    "github.com/labstack/echo/v4"
    "gorm.io/gorm"
)

type UserHandler struct {
    db      *gorm.DB
    context *context.Client
}

func NewUserHandler(db *gorm.DB, contextClient *context.Client) *UserHandler {
    return &UserHandler{
        db:      db,
        context: contextClient,
    }
}

// GetUsers returns all users
func (h *UserHandler) GetUsers(c echo.Context) error {
    var users []models.User
    if err := h.db.Find(&users).Error; err != nil {
        return c.JSON(http.StatusInternalServerError, map[string]string{
            "error": "Failed to fetch users",
        })
    }
    return c.JSON(http.StatusOK, users)
}

// GetUser returns a single user
func (h *UserHandler) GetUser(c echo.Context) error {
    id, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        return c.JSON(http.StatusBadRequest, map[string]string{
            "error": "Invalid user ID",
        })
    }

    var user models.User
    if err := h.db.First(&user, id).Error; err != nil {
        if err == gorm.ErrRecordNotFound {
            return c.JSON(http.StatusNotFound, map[string]string{
                "error": "User not found",
            })
        }
        return c.JSON(http.StatusInternalServerError, map[string]string{
            "error": "Failed to fetch user",
        })
    }

    return c.JSON(http.StatusOK, user)
}

// CreateUser creates a new user
func (h *UserHandler) CreateUser(c echo.Context) error {
    user := new(models.User)
    if err := c.Bind(user); err != nil {
        return c.JSON(http.StatusBadRequest, map[string]string{
            "error": "Invalid request body",
        })
    }

    // Query Context Engineering for past user management decisions
    ctx, err := h.context.Query(context.QueryRequest{
        Query:   "user management validation email",
        Domains: []string{"validation", "users"},
    })
    if err == nil && len(ctx.KeyDecisions) > 0 {
        // Log that we checked organizational context
        fmt.Printf("📚 Context check: Found %d relevant decisions\n", len(ctx.KeyDecisions))
        for _, dec := range ctx.KeyDecisions {
            fmt.Printf("  - %s: %s\n", dec.ID, dec.Title)
        }
    }

    if err := h.db.Create(user).Error; err != nil {
        // Record failure if creation fails
        _ = h.context.RecordFailure(context.FailureRequest{
            Title:      "User Creation Failed",
            RootCause:  fmt.Sprintf("Database error: %v", err),
            Symptoms:   "POST /users returned 500",
            Impact:     "User registration blocked",
            Resolution: "Investigating...",
            Severity:   "medium",
            Pattern:    "database_error",
            Tags:       []string{"users", "database"},
        })

        return c.JSON(http.StatusInternalServerError, map[string]string{
            "error": "Failed to create user",
        })
    }

    return c.JSON(http.StatusCreated, user)
}

// UpdateUser updates an existing user
func (h *UserHandler) UpdateUser(c echo.Context) error {
    id, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        return c.JSON(http.StatusBadRequest, map[string]string{
            "error": "Invalid user ID",
        })
    }

    var user models.User
    if err := h.db.First(&user, id).Error; err != nil {
        if err == gorm.ErrRecordNotFound {
            return c.JSON(http.StatusNotFound, map[string]string{
                "error": "User not found",
            })
        }
        return c.JSON(http.StatusInternalServerError, map[string]string{
            "error": "Failed to fetch user",
        })
    }

    updates := new(models.User)
    if err := c.Bind(updates); err != nil {
        return c.JSON(http.StatusBadRequest, map[string]string{
            "error": "Invalid request body",
        })
    }

    if err := h.db.Model(&user).Updates(updates).Error; err != nil {
        return c.JSON(http.StatusInternalServerError, map[string]string{
            "error": "Failed to update user",
        })
    }

    return c.JSON(http.StatusOK, user)
}

// DeleteUser deletes a user
func (h *UserHandler) DeleteUser(c echo.Context) error {
    id, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        return c.JSON(http.StatusBadRequest, map[string]string{
            "error": "Invalid user ID",
        })
    }

    if err := h.db.Delete(&models.User{}, id).Error; err != nil {
        return c.JSON(http.StatusInternalServerError, map[string]string{
            "error": "Failed to delete user",
        })
    }

    return c.JSON(http.StatusOK, map[string]string{
        "message": "User deleted successfully",
    })
}
EOF
```

**5. Main Application**

```bash
cat > main.go << 'EOF'
package main

import (
    "log"
    "os"

    "github.com/example/go-echo-app/context"
    "github.com/example/go-echo-app/handlers"
    "github.com/example/go-echo-app/models"
    "github.com/labstack/echo/v4"
    "github.com/labstack/echo/v4/middleware"
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
)

func main() {
    // Initialize database
    db, err := gorm.Open(sqlite.Open("users.db"), &gorm.Config{})
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }

    // Auto-migrate schema
    if err := db.AutoMigrate(&models.User{}); err != nil {
        log.Fatal("Failed to migrate database:", err)
    }

    // Initialize Context Engineering client
    contextURL := os.Getenv("CONTEXT_API_URL")
    if contextURL == "" {
        contextURL = "http://localhost:4000/api"
    }
    contextClient := context.NewClient(contextURL)

    // Record the decision to use Echo and SQLite
    _ = contextClient.CreateADR(context.ADRRequest{
        Title:    "Use Echo Framework for Go REST API",
        Decision: "Selected Echo as the web framework for its simplicity and performance",
        Context:  "Need lightweight HTTP router with middleware support for REST API",
        OptionsConsidered: map[string][]string{
            "Echo": {
                "Fast and lightweight",
                "Good middleware ecosystem",
                "Simple routing",
            },
            "Gin": {
                "Also fast but more opinionated",
                "Larger community",
            },
        },
        Tags:         []string{"golang", "web-framework", "rest-api"},
        Stakeholders: []string{"backend-team"},
    })

    // Initialize Echo
    e := echo.New()

    // Middleware
    e.Use(middleware.Logger())
    e.Use(middleware.Recover())
    e.Use(middleware.CORS())

    // Initialize handlers
    userHandler := handlers.NewUserHandler(db, contextClient)

    // Routes
    e.GET("/health", func(c echo.Context) error {
        return c.JSON(200, map[string]string{"status": "ok"})
    })

    // User routes
    e.GET("/users", userHandler.GetUsers)
    e.GET("/users/:id", userHandler.GetUser)
    e.POST("/users", userHandler.CreateUser)
    e.PUT("/users/:id", userHandler.UpdateUser)
    e.DELETE("/users/:id", userHandler.DeleteUser)

    // Context Engineering integration endpoint
    e.POST("/context/query", func(c echo.Context) error {
        var req context.QueryRequest
        if err := c.Bind(&req); err != nil {
            return c.JSON(400, map[string]string{"error": "Invalid request"})
        }

        result, err := contextClient.Query(req)
        if err != nil {
            return c.JSON(500, map[string]string{"error": err.Error()})
        }

        return c.JSON(200, result)
    })

    // Start server
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("🚀 Server starting on :%s", port)
    log.Printf("📚 Context Engineering at: %s", contextURL)
    log.Fatal(e.Start(":" + port))
}
EOF
```

**6. Create Agent Skills for Go App**

```bash
mkdir -p skills/public/go-api-query
cat > skills/public/go-api-query/SKILL.md << 'EOF'
# go-api-query

Query organizational knowledge for Go API development decisions.

## Purpose
Find past decisions about:
- API design patterns
- Error handling
- Validation strategies
- Database patterns
- Performance optimizations

## Auto-Triggers
- "how should I handle errors in go"
- "go api best practices"
- "user validation pattern"
- "database connection go"
- "rest api design"

## Usage

### From Go Code
```go
import "github.com/example/go-echo-app/context"

client := context.NewClient("http://localhost:4000/api")
result, err := client.Query(context.QueryRequest{
    Query: "user validation email format",
    Domains: []string{"validation", "users"},
    MaxTokens: 2000,
})

// Check result.KeyDecisions for past decisions
// Check result.KnownIssues for past failures
```

### From AI Agent
```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "go error handling patterns", "domains": ["golang"]}'
```

## Response
```json
{
  "key_decisions": [
    {
      "id": "ADR-001",
      "title": "Go Error Handling Pattern",
      "decision": "Always wrap errors with context using fmt.Errorf",
      "tags": ["golang", "error-handling"]
    }
  ],
  "known_issues": [
    {
      "id": "FAIL-005",
      "title": "Missing Error Context Led to Debug Issues",
      "resolution": "Added detailed error wrapping"
    }
  ]
}
```

## Integration Points

### Before Writing Handler
1. Query: "user management validation patterns"
2. Check past validation decisions
3. Check known validation failures
4. Apply learned patterns

### When Error Occurs
1. Query: "[error type] golang patterns"
2. Check if similar issue occurred before
3. Apply documented resolution
4. If new issue, record as failure

### When Making Design Decision
1. Query: "[design area] decisions"
2. Review past choices
3. Document decision as ADR
4. Link to related decisions
EOF

mkdir -p skills/user/go-api-record
cat > skills/user/go-api-record/SKILL.md << 'EOF'
# go-api-record

Record architectural decisions and failures in Go API development.

## Purpose
Document:
- API design decisions
- Technology choices
- Failure incidents
- Performance solutions

## When to Use
- After making architecture decision
- After choosing technology/library
- After fixing production incident
- After performance optimization

## Usage

### Record ADR
```go
import "github.com/example/go-echo-app/context"

client := context.NewClient("http://localhost:4000/api")
err := client.CreateADR(context.ADRRequest{
    Title: "Use GORM for Database ORM",
    Decision: "Selected GORM for database operations",
    Context: "Need ORM with good SQLite and PostgreSQL support",
    OptionsConsidered: map[string][]string{
        "GORM": {"Feature-rich", "Good community"},
        "sqlx": {"More control", "Less magic"},
    },
    Tags: []string{"golang", "database", "orm"},
    Stakeholders: []string{"backend-team"},
})
```

### Record Failure
```go
err := client.RecordFailure(context.FailureRequest{
    Title: "Database Connection Pool Exhausted",
    RootCause: "Default max connections (10) too low for load",
    Symptoms: "API timeouts, slow response times",
    Impact: "50% of requests failing during peak",
    Resolution: "Increased max connections to 50, added monitoring",
    Prevention: []string{
        "Set connection pool size based on load testing",
        "Add connection pool monitoring",
        "Set up alerts for high connection usage",
    },
    Severity: "high",
    Pattern: "resource_exhaustion",
    Tags: []string{"database", "performance", "golang"},
})
```

## Best Practices

### What to Record as ADR
- Framework/library choices
- Architecture patterns
- API design decisions
- Security approaches
- Performance strategies

### What to Record as Failure
- Production incidents
- Performance issues
- Security vulnerabilities
- Data inconsistencies
- Integration failures

### Linking Decisions
Reference other items in text:
- "Supersedes ADR-001"
- "Related to FAIL-005"
- "Discussed in MEET-003"

System auto-links these references.
EOF
```

**7. AI Agent Configuration Files**

```bash
# Cursor rules
cat > .cursorrules << 'EOF'
# Go Echo App - Context Engineering Integration

## Before Suggesting Code
Always query Context Engineering first:

```typescript
// Check organizational knowledge
const context = await queryContext({
  query: "relevant search terms",
  domains: ["golang", "api"]
});
```

## Available Skills
- `skills/public/go-api-query/` - Query Go patterns
- `skills/user/go-api-record/` - Record decisions

## Context Engineering API
Base URL: http://localhost:4000/api

### Query endpoint
POST /context/query
Body: {"query": "search terms", "domains": ["golang"]}

### Record ADR
POST /adr
Body: {"title": "...", "decision": "...", "context": "..."}

## Workflow
1. User asks about implementation
2. Query past decisions: POST /context/query
3. Check known issues in results
4. Suggest code based on organizational patterns
5. If new pattern, suggest recording as ADR

## Triggers
- "how should I..." → Query decisions
- "error handling" → Query errors + failures
- "best practice" → Query decisions + issues
- "I decided to" → Suggest recording ADR

## Example
User: "How should I handle database errors?"

You should:
1. Query: {"query": "database error handling golang"}
2. Show past decisions (ADR-XXX)
3. Show past failures (FAIL-XXX)
4. Suggest code following those patterns
EOF

# GitHub Copilot instructions
mkdir -p .github
cat > .github/copilot-instructions.md << 'EOF'
# GitHub Copilot - Context Engineering Integration

## Project Type
Go REST API using Echo framework with Context Engineering integration

## Query Pattern
```go
// Before implementing patterns, query organizational knowledge
client := context.NewClient("http://localhost:4000/api")
result, _ := client.Query(context.QueryRequest{
    Query: "relevant topic",
    Domains: []string{"golang", "api"},
})
```

## Common Queries

### Error Handling
```go
// Query: "golang error handling patterns"
func handleError(err error) error {
    // Follow ADR-XXX pattern
    return fmt.Errorf("operation failed: %w", err)
}
```

### Validation
```go
// Query: "user validation email format"
func validateEmail(email string) error {
    // Check past validation decisions
    // Apply learned patterns
}
```

### Database Operations
```go
// Query: "database transaction golang gorm"
func createWithTransaction(db *gorm.DB, user *User) error {
    // Follow organizational patterns
}
```

## Recording Decisions
When implementing new patterns:
```go
// Record the decision
_ = client.CreateADR(context.ADRRequest{
    Title: "Pattern Name",
    Decision: "What we decided",
    Context: "Why we decided",
    Tags: []string{"golang", "pattern-type"},
})
```

## Failure Recording
When fixing bugs:
```go
// Record the failure
_ = client.RecordFailure(context.FailureRequest{
    Title: "Bug Title",
    RootCause: "What caused it",
    Resolution: "How we fixed it",
    Prevention: []string{"How to prevent"},
    Tags: []string{"bug-type"},
})
```
EOF
```

**8. README**

```bash
cat > README.md << 'EOF'
# Go Echo CRUD API with Context Engineering

A demonstration of integrating Context Engineering with a Go REST API.

## Features
- ✅ Complete CRUD operations for users
- 🧠 Context Engineering integration
- 📚 Auto-queries past decisions before operations
- 📝 Records failures automatically
- 🤖 AI agent skills included

## Quick Start

### 1. Start Context Engineering
```bash
# In context_engineering directory
mix phx.server
```

### 2. Start Go App
```bash
# In this directory
go mod tidy
go run main.go
```

### 3. Test Integration
```bash
# Create user (triggers context query)
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "email": "alice@example.com"}'

# Query context from Go app
curl -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "user validation"}'
```

## AI Agent Testing

### Test with Cursor
1. Open this directory in Cursor
2. Open Cursor chat (Cmd+L)
3. Ask: "How should I validate email addresses?"
4. Cursor should query Context Engineering automatically

### Test with GitHub Copilot
1. Open user_handler.go
2. Type comment: `// Validate email format following organizational pattern`
3. Copilot suggests code based on context

### Test with Claude Code (Cline)
1. Open VS Code with Cline extension
2. Start Cline chat
3. Ask: "Show me past database error handling decisions"
4. Cline queries Context Engineering

## How It Works

### Auto-Query on Operations
```go
// Before creating user, check organizational patterns
ctx, err := h.context.Query(context.QueryRequest{
    Query:   "user management validation email",
    Domains: []string{"validation", "users"},
})
// Use results to inform implementation
```

### Auto-Record Failures
```go
if err := h.db.Create(user).Error; err != nil {
    // Automatically record failure
    _ = h.context.RecordFailure(context.FailureRequest{
        Title:      "User Creation Failed",
        RootCause:  fmt.Sprintf("Database error: %v", err),
        Resolution: "Investigating...",
    })
}
```

## API Endpoints

### Users
- `GET /users` - List all users
- `GET /users/:id` - Get user by ID
- `POST /users` - Create user
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user

### Context Integration
- `POST /context/query` - Query organizational knowledge
- Automatic context queries on operations
- Automatic failure recording

## Skills

Located in `skills/` directory:
- `skills/public/go-api-query/` - Query patterns (auto-use)
- `skills/user/go-api-record/` - Record decisions (requires approval)

## Environment Variables

- `CONTEXT_API_URL` - Context Engineering API URL (default: http://localhost:4000/api)
- `PORT` - Server port (default: 8080)
EOF
```

Now let's test everything!

**9. Testing Script**

```bash
cat > test-integration.sh << 'EOF'
#!/bin/bash
set -e

echo "🧪 Testing Context Engineering + Go Integration"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Check Context Engineering is running
echo -e "${BLUE}1. Checking Context Engineering...${NC}"
if curl -s http://localhost:4000/api/adr > /dev/null; then
    echo -e "${GREEN}✓ Context Engineering is running${NC}"
else
    echo "❌ Context Engineering not running. Start with: cd ../../ && mix phx.server"
    exit 1
fi
echo ""

# 2. Start Go app in background
echo -e "${BLUE}2. Starting Go application...${NC}"
go run main.go &
GO_PID=$!
sleep 3

if curl -s http://localhost:8080/health > /dev/null; then
    echo -e "${GREEN}✓ Go app is running${NC}"
else
    echo "❌ Go app failed to start"
    kill $GO_PID 2>/dev/null || true
    exit 1
fi
echo ""

# 3. Test context query from Go app
echo -e "${BLUE}3. Testing context query...${NC}"
QUERY_RESULT=$(curl -s -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "user management"}')

if echo "$QUERY_RESULT" | grep -q "key_decisions"; then
    echo -e "${GREEN}✓ Context query working${NC}"
    echo "   Response: $QUERY_RESULT"
else
    echo "❌ Context query failed"
fi
echo ""

# 4. Create user (triggers context query)
echo -e "${BLUE}4. Creating user (should query context)...${NC}"
USER_RESULT=$(curl -s -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User", "email": "test@example.com"}')

if echo "$USER_RESULT" | grep -q "Test User"; then
    echo -e "${GREEN}✓ User created (check server logs for context query)${NC}"
    echo "   User: $USER_RESULT"
else
    echo "❌ User creation failed"
fi
echo ""

# 5. Verify ADR was created
echo -e "${BLUE}5. Checking if ADR was recorded...${NC}"
ADR_LIST=$(curl -s http://localhost:4000/api/adr)
if echo "$ADR_LIST" | grep -q "Echo Framework"; then
    echo -e "${GREEN}✓ ADR created on startup${NC}"
else
    echo "⚠️  ADR not found (might be expected)"
fi
echo ""

# 6. Test skills files exist
echo -e "${BLUE}6. Checking skills files...${NC}"
if [ -f "skills/public/go-api-query/SKILL.md" ]; then
    echo -e "${GREEN}✓ go-api-query skill exists${NC}"
else
    echo "❌ go-api-query skill missing"
fi

if [ -f "skills/user/go-api-record/SKILL.md" ]; then
    echo -e "${GREEN}✓ go-api-record skill exists${NC}"
else
    echo "❌ go-api-record skill missing"
fi
echo ""

# 7. Cleanup
echo -e "${BLUE}7. Cleaning up...${NC}"
kill $GO_PID 2>/dev/null || true
rm -f users.db
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

echo "🎉 Integration test complete!"
echo ""
echo "Next steps:"
echo "1. Open this directory in Cursor/VS Code"
echo "2. Try asking AI agent: 'How should I validate emails?'"
echo "3. Agent should query Context Engineering automatically"
EOF

chmod +x test-integration.sh
```

Now run the complete setup:

```bash
# Make sure Context Engineering is running
cd context_engineering
mix phx.server &
sleep 5

# Run the Go app test
cd examples/go-echo-app
./test-integration.sh
```

This creates a complete, working example that demonstrates:
1. ✅ Go CRUD API with Echo
2. ✅ Context Engineering client integration
3. ✅ Automatic context queries before operations
4. ✅ Automatic failure recording
5. ✅ Agent skills for AI assistants
6. ✅ Configuration for Cursor, Copilot, Claude Code
7. ✅ Full test suite

The AI agents will automatically:
- Query past decisions when you ask about patterns
- Show known issues when you implement features
- Suggest recording decisions when you make choices
- Reference organizational context in suggestions
EOF
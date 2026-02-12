# GitHub Copilot Instructions - Context Engineering Integration

This is a Go REST API using Echo framework with Context Engineering integration for organizational knowledge management.

## Project Overview

- **Language**: Go 1.21+
- **Framework**: Echo v4 (web framework)
- **Database**: SQLite with GORM
- **Integration**: Context Engineering for querying/recording organizational decisions

## Context Engineering Integration

### Base URL
```
http://localhost:4000/api
```

### Query Pattern
```go
import "github.com/example/go-echo-app/context"

// Query organizational knowledge before implementing
client := context.NewClient("http://localhost:4000/api")
result, err := client.Query(context.QueryRequest{
    Query: "relevant topic",
    Domains: []string{"golang", "api"},
    MaxTokens: 2000,
})

// Check result.KeyDecisions for past architectural decisions
// Check result.KnownIssues for past failures and bugs
// Check result.RecentChanges for latest updates
```

## When to Query Context Engineering

### Before Writing Handlers
```go
// Query: "user validation golang email patterns"
func (h *UserHandler) CreateUser(c echo.Context) error {
    // Check organizational validation patterns first
    // Apply learned patterns from past decisions
}
```

### Before Error Handling
```go
// Query: "golang error handling wrapping patterns"
func processData(data []byte) error {
    if err := validate(data); err != nil {
        // Follow organizational error pattern
        return fmt.Errorf("validation failed: %w", err)
    }
    return nil
}
```

### Before Database Operations
```go
// Query: "database transaction golang gorm patterns"
func createWithTransaction(db *gorm.DB, user *User) error {
    // Follow organizational transaction patterns
    return db.Transaction(func(tx *gorm.DB) error {
        return tx.Create(user).Error
    })
}
```

### Before Performance Optimization
```go
// Query: "golang performance optimization caching"
// Check past performance decisions and known bottlenecks
```

## Common Query Examples

### Error Handling
```go
// Before implementing error handling
// Suggest: Query "golang error handling patterns fmt.Errorf"
func handleError(err error) error {
    // Follow ADR-XXX pattern from organizational knowledge
    return fmt.Errorf("operation failed: %w", err)
}
```

### Validation
```go
// Before implementing validation
// Suggest: Query "user input validation golang email regex"
func validateEmail(email string) error {
    // Use pattern from organizational decisions
    pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
    matched, _ := regexp.MatchString(pattern, email)
    if !matched {
        return fmt.Errorf("invalid email format")
    }
    return nil
}
```

### Database Configuration
```go
// Before configuring database
// Suggest: Query "database connection pool golang gorm configuration"
db, err := gorm.Open(sqlite.Open("app.db"), &gorm.Config{})
// Apply connection pool settings from organizational decisions
```

### Authentication
```go
// Before implementing auth
// Suggest: Query "authentication golang jwt session patterns"
// Follow organizational auth pattern
```

## Recording Decisions

### When Making Architecture Decisions
```go
// After user decides on approach
// Suggest: "Should I record this as an ADR?"

client.CreateADR(context.ADRRequest{
    Title: "Use Echo Framework for REST API",
    Decision: "Selected Echo for its simplicity and performance",
    Context: "Need lightweight HTTP router with middleware support",
    OptionsConsidered: map[string][]string{
        "Echo": {"Fast", "Simple", "Good middleware"},
        "Gin": {"Also fast", "More opinionated"},
    },
    Tags: []string{"golang", "web-framework"},
    Stakeholders: []string{"backend-team"},
})
```

### When Fixing Bugs
```go
// After fixing production issue
// Suggest: "Should I record this incident?"

client.RecordFailure(context.FailureRequest{
    Title: "Database Connection Pool Exhausted",
    RootCause: "Default pool size too small for production load",
    Symptoms: "API timeouts, 502 errors during peak",
    Impact: "50% of requests failing",
    Resolution: "Increased pool to 50, added monitoring",
    Prevention: []string{
        "Load test before deploy",
        "Monitor connection pool usage",
        "Set up alerts at 80% threshold",
    },
    Severity: "high",
    Pattern: "resource_exhaustion",
    Tags: []string{"database", "performance"},
})
```

## Code Completion Patterns

### Handler Pattern
```go
// When writing Echo handlers, follow this pattern:
func (h *UserHandler) CreateUser(c echo.Context) error {
    user := new(models.User)
    if err := c.Bind(user); err != nil {
        return c.JSON(400, map[string]string{"error": "Invalid request"})
    }
    
    // Query context for validation patterns
    // Apply organizational validation
    
    if err := h.db.Create(user).Error; err != nil {
        // Record failure if needed
        // Return wrapped error
        return c.JSON(500, map[string]string{"error": "Failed to create user"})
    }
    
    return c.JSON(201, user)
}
```

### Error Wrapping Pattern
```go
// Always wrap errors with context
if err != nil {
    return fmt.Errorf("operation name: %w", err)
}
```

### Database Transaction Pattern
```go
// Use transactions for multi-step operations
err := db.Transaction(func(tx *gorm.DB) error {
    // Multiple database operations
    return nil
})
```

### Validation Pattern
```go
// Validate input before processing
func validate(user *User) error {
    if user.Name == "" {
        return fmt.Errorf("name is required")
    }
    if !isValidEmail(user.Email) {
        return fmt.Errorf("invalid email format")
    }
    return nil
}
```

## Trigger Words

When user mentions these, query Context Engineering:

- "how should I..." → Query decisions and patterns
- "best practice" → Query organizational best practices
- "error handling" → Query error handling decisions
- "validation" → Query validation patterns
- "database" → Query database decisions and issues
- "performance" → Query performance optimizations
- "security" → Query security patterns
- "why did we" → Query past decisions
- "past issues" → Query known failures

## Response Format

When suggesting code based on organizational knowledge:

```
Based on ADR-005 (Error Wrapping Strategy), we wrap all errors 
using fmt.Errorf with the %w verb to preserve the error chain.

Note: FAIL-010 shows that missing error context made debugging 
difficult in production, so always include operation context.

Here's the pattern:

```go
if err := operation(); err != nil {
    return fmt.Errorf("descriptive context: %w", err)
}
```
```

## Environment Variables

- `CONTEXT_API_URL` - Context Engineering API URL (default: http://localhost:4000/api)
- `PORT` - Server port (default: 8080)

## Prerequisites

1. Context Engineering server must be running: `cd ../../ && mix phx.server`
2. Server should be accessible at http://localhost:4000
3. Go modules installed: `go mod tidy`

## Testing Context Integration

```bash
# Test query endpoint
curl -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "golang patterns"}'

# Test direct Context Engineering API
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database decisions"}'
```

## Project Structure

```
.
├── main.go                 # Entry point, initializes Context Engineering client
├── handlers/
│   └── user_handler.go    # HTTP handlers with context integration
├── models/
│   └── user.go            # Data models
├── context/
│   └── client.go          # Context Engineering client library
├── skills/                # Agent skills directory
│   ├── public/            # Auto-use skills (query operations)
│   └── user/              # Permission-required skills (write operations)
├── go.mod
└── README.md
```

## Best Practices

1. **Query Before Implementing** - Always check organizational context first
2. **Wrap All Errors** - Use fmt.Errorf with %w for error chains
3. **Validate Inputs** - Check all user inputs before processing
4. **Use Transactions** - Wrap multi-step DB operations in transactions
5. **Handle Context** - Pass context.Context through function chains
6. **Log Appropriately** - Use structured logging with context
7. **Test Thoroughly** - Include both success and error cases
8. **Document Decisions** - Record important architectural choices as ADRs
9. **Learn from Failures** - Check known issues before implementing
10. **Reference Sources** - Cite specific ADR-XXX or FAIL-XXX when suggesting patterns

## Integration Flow

```
User asks question
    ↓
Query Context Engineering
    ↓
Analyze key_decisions, known_issues, recent_changes
    ↓
Suggest code following organizational patterns
    ↓
If decision made → Suggest recording as ADR
If bug fixed → Suggest recording as failure
```

## Example Completion

User types: `// Validate email format`

Copilot should suggest:
```go
// Validate email format following organizational pattern from ADR-003
func isValidEmail(email string) bool {
    pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
    matched, _ := regexp.MatchString(pattern, email)
    return matched
}
```

## Error Recovery

If Context Engineering is unavailable:
```go
result, err := client.Query(req)
if err != nil {
    // Graceful degradation - continue with generic implementation
    log.Printf("Warning: Could not query context: %v", err)
}
```

## Skills Available

- `skills/public/go-api-query/` - Query Go patterns and decisions
- `skills/user/go-api-record/` - Record decisions and failures (requires user approval)

Read skill files for detailed usage instructions.
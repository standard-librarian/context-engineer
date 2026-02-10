# go-api-query

Query organizational knowledge for Go API development decisions.

## Purpose
Find past decisions about:
- API design patterns
- Error handling strategies
- Validation approaches
- Database patterns
- Performance optimizations
- Go best practices

## Auto-Triggers
- "how should I handle errors in go"
- "go api best practices"
- "user validation pattern"
- "database connection go"
- "rest api design"
- "golang error handling"
- "go project structure"
- "gorm best practices"

## Usage

### From AI Agent (Auto-use)
```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "go error handling patterns",
    "domains": ["golang", "api"],
    "max_tokens": 2000
  }'
```

### From Go Code
```go
import "github.com/example/go-echo-app/context"

client := context.NewClient("http://localhost:4000/api")
result, err := client.Query(context.QueryRequest{
    Query: "user validation email format",
    Domains: []string{"validation", "users"},
    MaxTokens: 2000,
})

if err == nil {
    // Check result.KeyDecisions for past architectural decisions
    for _, decision := range result.KeyDecisions {
        fmt.Printf("Found decision: %s - %s\n", decision.ID, decision.Title)
    }
    
    // Check result.KnownIssues for past failures
    for _, issue := range result.KnownIssues {
        fmt.Printf("Known issue: %s - %s\n", issue.ID, issue.Title)
    }
}
```

## Response Format

```json
{
  "key_decisions": [
    {
      "id": "ADR-001",
      "title": "Go Error Handling Pattern",
      "decision": "Always wrap errors with context using fmt.Errorf with %w verb",
      "tags": ["golang", "error-handling"],
      "score": 0.89
    }
  ],
  "known_issues": [
    {
      "id": "FAIL-005",
      "title": "Missing Error Context Led to Debug Issues",
      "root_cause": "Errors were returned without wrapping",
      "resolution": "Added detailed error wrapping throughout codebase",
      "pattern": "missing_context"
    }
  ],
  "recent_changes": [
    {
      "id": "MEET-002",
      "type": "meeting",
      "title": "Go Code Review Standards",
      "tags": ["golang", "standards"]
    }
  ],
  "total_items": 3
}
```

## Integration Points

### Before Writing Handler
1. Query: "user management validation patterns go"
2. Review past validation decisions (ADRs)
3. Check known validation failures
4. Apply learned patterns to implementation

**Example:**
```go
// AI Agent should query: "user email validation golang"
func (h *UserHandler) CreateUser(c echo.Context) error {
    user := new(models.User)
    if err := c.Bind(user); err != nil {
        return c.JSON(400, map[string]string{"error": "Invalid request"})
    }
    
    // Apply pattern from ADR-003: Email Validation
    if !isValidEmail(user.Email) {
        return c.JSON(400, map[string]string{"error": "Invalid email format"})
    }
    
    // Create user...
}
```

### When Error Occurs
1. Query: "[error type] golang patterns resolution"
2. Check if similar issue occurred before
3. Apply documented resolution
4. If new issue, record as failure

**Example:**
```go
// AI Agent should query: "database connection timeout golang"
func connectDB() (*gorm.DB, error) {
    db, err := gorm.Open(sqlite.Open("app.db"), &gorm.Config{})
    if err != nil {
        // Check past similar failures
        // Apply resolution from FAIL-008: Database Connection Timeout
        return nil, fmt.Errorf("database connection failed: %w", err)
    }
    return db, nil
}
```

### When Making Design Decision
1. Query: "[design area] decisions golang"
2. Review past architectural choices
3. Check for related failures
4. Make informed decision
5. Document decision as ADR (use go-api-record skill)

**Example:**
```go
// Before choosing validation library
// AI Agent should query: "validation library golang decisions"
// Check ADR-015: Validation Approach
// Then suggest appropriate library based on past decisions
```

## Common Query Patterns

### Error Handling
**Query:** `"golang error handling wrapping patterns"`
**Use when:** Implementing error handling in handlers or services
**Expected results:** ADRs about error patterns, failures from missing error context

### Database Operations
**Query:** `"database transaction golang gorm patterns"`
**Use when:** Implementing database operations
**Expected results:** ADRs about transaction handling, failures from race conditions

### Validation
**Query:** `"user input validation golang email phone"`
**Use when:** Implementing input validation
**Expected results:** ADRs about validation strategies, failures from injection attacks

### API Design
**Query:** `"rest api endpoint design golang echo"`
**Use when:** Designing new endpoints
**Expected results:** ADRs about API structure, failures from breaking changes

### Performance
**Query:** `"api performance optimization golang caching"`
**Use when:** Optimizing performance
**Expected results:** ADRs about caching strategies, failures from N+1 queries

## Workflow for AI Agents

When user asks: **"How should I implement user authentication?"**

1. **Query organizational context:**
   ```bash
   POST /api/context/query
   {"query": "user authentication golang jwt session", "domains": ["golang", "security"]}
   ```

2. **Analyze results:**
   - Check `key_decisions` for authentication ADRs
   - Check `known_issues` for past auth failures
   - Check `recent_changes` for latest auth updates

3. **Provide informed response:**
   ```
   Based on ADR-012, the team chose JWT tokens over sessions because:
   - Stateless authentication required for microservices
   - Mobile app needs token-based auth
   
   However, FAIL-018 shows we had issues with:
   - Token expiration not being handled properly
   - Missing refresh token implementation
   
   I recommend implementing JWT with refresh tokens and proper
   expiration handling, following the patterns in ADR-012.
   ```

4. **Suggest recording decision:**
   "After implementing this, should I record it as an ADR?"

## Best Practices for AI Agents

### Always Query Before Suggesting
❌ Don't: Immediately suggest generic Go patterns
✅ Do: Query organizational context first, then suggest based on past decisions

### Reference Specific Items
❌ Don't: "You should use error wrapping"
✅ Do: "According to ADR-005, we wrap errors using fmt.Errorf with %w verb"

### Consider Known Issues
❌ Don't: Suggest patterns that failed before
✅ Do: "FAIL-010 shows this pattern caused issues. Use ADR-020 approach instead"

### Link Related Context
✅ "This relates to ADR-008 (database patterns) and FAIL-015 (connection issues)"

## Environment Variables

- `CONTEXT_API_URL` - Context Engineering API URL (default: http://localhost:4000/api)

## Prerequisites

- Context Engineering server must be running
- Go application must have context client initialized
- Network connectivity to Context Engineering API

## Error Handling

If Context Engineering is unavailable:
```go
result, err := contextClient.Query(req)
if err != nil {
    // Continue without context (graceful degradation)
    log.Printf("Warning: Could not query context: %v", err)
    // Proceed with generic implementation
}
```

## Examples

### Full Query Flow
```go
// 1. User asks AI agent: "How do I validate emails?"

// 2. AI agent queries context:
result, _ := contextClient.Query(context.QueryRequest{
    Query: "email validation golang regex patterns",
    Domains: []string{"validation", "golang"},
})

// 3. AI agent analyzes results:
// - Found ADR-003: Email Validation Strategy
// - Found FAIL-007: Regex Pattern Too Permissive

// 4. AI agent responds:
// "According to ADR-003, we use this regex pattern:
//  ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
//  
//  Note: FAIL-007 shows the previous pattern allowed invalid emails.
//  The current pattern was updated to be more strict."

// 5. AI agent provides code:
func isValidEmail(email string) bool {
    pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
    matched, _ := regexp.MatchString(pattern, email)
    return matched
}
```

## Testing

Verify the skill works:

```bash
# Test from command line
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "golang patterns"}'

# Expected: Returns key_decisions, known_issues, recent_changes

# Test from AI agent
# In your AI agent chat:
# "Show me past Go error handling decisions"
# Agent should auto-trigger this skill and return relevant ADRs
```

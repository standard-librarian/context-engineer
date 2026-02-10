# go-api-record

Record architectural decisions and failures in Go API development.

## Purpose
Document:
- API design decisions
- Technology choices
- Framework selections
- Failure incidents
- Performance solutions
- Security implementations

## When to Use
- After making architecture decision
- After choosing technology/library
- After fixing production incident
- After performance optimization
- After security implementation
- When establishing new patterns

## Auto-Triggers
- "record this decision"
- "document this choice"
- "create adr for"
- "log this failure"
- "record incident"

⚠️ **User Approval Required**: This skill writes data, so AI agents should ask permission first.

## Usage

### Record ADR (Architectural Decision Record)

```go
import "github.com/example/go-echo-app/context"

client := context.NewClient("http://localhost:4000/api")
err := client.CreateADR(context.ADRRequest{
    Title: "Use GORM for Database ORM",
    Decision: "Selected GORM as our database ORM for Go applications",
    Context: "Need ORM with good SQLite and PostgreSQL support, migrations, and associations",
    OptionsConsidered: map[string][]string{
        "GORM": {
            "Feature-rich with associations",
            "Good community and documentation",
            "Built-in migrations",
        },
        "sqlx": {
            "More control over queries",
            "Less magic, more explicit",
            "Lightweight",
        },
        "Ent": {
            "Type-safe code generation",
            "Graph-based approach",
            "Learning curve",
        },
    },
    Tags: []string{"golang", "database", "orm"},
    Stakeholders: []string{"backend-team", "devops"},
})
```

### Record Failure

```go
err := client.RecordFailure(context.FailureRequest{
    Title: "Database Connection Pool Exhausted",
    RootCause: "Default max connections (10) too low for production load",
    Symptoms: "API timeouts, slow response times, 502 errors during peak traffic",
    Impact: "50% of requests failing during peak hours, customer complaints",
    Resolution: "Increased max connections to 50, added connection pool monitoring",
    Prevention: []string{
        "Set connection pool size based on load testing results",
        "Add Prometheus metrics for connection pool usage",
        "Set up alerts for high connection usage (>80%)",
        "Document connection pool sizing in runbook",
    },
    Severity: "high", // low, medium, high, critical
    Pattern: "resource_exhaustion",
    Tags: []string{"database", "performance", "golang", "production"},
})
```

### From AI Agent (cURL)

```bash
# Record ADR
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Use Echo Framework for REST API",
    "decision": "Selected Echo as our Go web framework",
    "context": "Need lightweight HTTP router with middleware support",
    "options_considered": {
      "Echo": ["Fast", "Simple routing", "Good middleware"],
      "Gin": ["Also fast", "More opinionated", "Larger community"]
    },
    "tags": ["golang", "web-framework", "rest-api"]
  }'

# Record Failure
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Goroutine Leak in HTTP Client",
    "root_cause": "Missing context timeout on HTTP requests",
    "symptoms": "Memory usage growing over time, goroutine count increasing",
    "resolution": "Added context.WithTimeout to all HTTP client calls",
    "severity": "medium",
    "pattern": "resource_leak",
    "tags": ["golang", "concurrency", "http-client"]
  }'
```

## What to Record as ADR

### Framework/Library Choices
```
Title: "Use Viper for Configuration Management"
Decision: Why this library was chosen
Context: What problem it solves
Options: What alternatives were considered
```

### Architecture Patterns
```
Title: "Repository Pattern for Data Access"
Decision: How we structure data access
Context: Need for testability and separation of concerns
```

### API Design Decisions
```
Title: "RESTful API Design with JSON:API Spec"
Decision: Follow JSON:API specification
Context: Need consistent API structure across services
```

### Error Handling Strategies
```
Title: "Error Wrapping with Contextual Information"
Decision: Always wrap errors with fmt.Errorf and %w verb
Context: Need better error tracing in production
```

### Security Approaches
```
Title: "JWT-Based Authentication"
Decision: Use JWT tokens for API authentication
Context: Need stateless auth for microservices
```

### Performance Strategies
```
Title: "Redis Caching for User Sessions"
Decision: Cache user sessions in Redis
Context: Database queries became bottleneck
```

## What to Record as Failure

### Production Incidents
```
Title: "API Gateway Timeout During Deploy"
Root Cause: Rolling restart caused connection drops
Symptoms: 504 errors, customer complaints
Resolution: Implemented graceful shutdown with connection draining
```

### Performance Issues
```
Title: "N+1 Query Problem in User Endpoints"
Root Cause: Missing eager loading in GORM queries
Symptoms: Slow response times (>2s), high database load
Resolution: Added Preload() to fetch associations in single query
```

### Security Vulnerabilities
```
Title: "SQL Injection in Search Endpoint"
Root Cause: String concatenation used for SQL query
Symptoms: Detected in security audit
Resolution: Migrated to parameterized queries with GORM
Prevention: Added SAST tool to CI/CD pipeline
```

### Data Inconsistencies
```
Title: "Race Condition in Order Processing"
Root Cause: Missing transaction isolation for concurrent updates
Symptoms: Orders processed twice, duplicate charges
Resolution: Implemented database transactions with proper locking
```

### Integration Failures
```
Title: "Payment Gateway Timeout"
Root Cause: No timeout set on HTTP client
Symptoms: Requests hanging indefinitely
Resolution: Added 10s timeout to all external API calls
```

## Linking Decisions

Reference other items in text to auto-create relationships:

```go
Decision: "This supersedes ADR-001 which chose MongoDB"
Context: "Related to FAIL-005 which exposed scaling issues"
```

System automatically creates graph relationships:
- `ADR-002` --[supersedes]--> `ADR-001`
- `ADR-002` --[references]--> `FAIL-005`

## Best Practices

### ADR Title Format
✅ "Use [Technology] for [Purpose]"
✅ "[Action] [Component] with [Approach]"
❌ "Database stuff"
❌ "Update"

### Decision Content
Include:
- **What** was decided
- **Why** it was decided
- **What** alternatives were considered
- **What** the expected outcome is

### Failure Content
Include:
- **What** went wrong
- **Why** it went wrong (root cause)
- **How** it was fixed (resolution)
- **How** to prevent it (prevention steps)
- **Pattern** for similar issues

### Severity Levels
- `critical`: System down, data loss, security breach
- `high`: Major feature broken, significant user impact
- `medium`: Minor feature broken, workaround available
- `low`: Cosmetic issue, no user impact

### Common Patterns
- `resource_exhaustion`: Connection pools, memory, CPU
- `resource_leak`: Goroutines, file handles, connections
- `race_condition`: Concurrent access without locking
- `missing_validation`: Input not validated
- `configuration_error`: Wrong settings or missing config
- `external_dependency`: Third-party service issues

## Response Format

### ADR Creation
```json
{
  "id": "ADR-004",
  "status": "created",
  "title": "Use Echo Framework for REST API",
  "tags": ["golang", "web-framework"],
  "relationships_created": ["references:ADR-001"]
}
```

### Failure Recording
```json
{
  "id": "FAIL-012",
  "status": "created",
  "title": "Database Connection Pool Exhausted",
  "pattern": "resource_exhaustion",
  "relationships_created": ["references:ADR-003"]
}
```

## Examples

### Example 1: Record Technology Choice

User: "I decided to use Echo framework for our REST API"

AI Agent: "I'll record this as an ADR. Let me create it:

```go
client.CreateADR(context.ADRRequest{
    Title: "Use Echo Framework for Go REST API",
    Decision: "Selected Echo as the web framework for its simplicity and performance",
    Context: "Need lightweight HTTP router with middleware support for REST API",
    OptionsConsidered: map[string][]string{
        "Echo": {"Fast", "Simple", "Good middleware ecosystem"},
        "Gin": {"Also fast", "More opinionated", "Larger community"},
        "Chi": {"Minimal", "Standard library based", "Less features"},
    },
    Tags: []string{"golang", "web-framework", "rest-api"},
})
```

Created ADR-004."

### Example 2: Record Production Incident

User: "We had an incident where the API ran out of database connections"

AI Agent: "I'll record this incident. Let me document it:

```go
client.RecordFailure(context.FailureRequest{
    Title: "Database Connection Pool Exhausted During Peak Load",
    RootCause: "Default max_connections of 10 was insufficient for production traffic",
    Symptoms: "502 errors, API timeouts, slow database queries, connection refused errors",
    Impact: "API unavailable for 15 minutes, affecting 500+ users during peak hours",
    Resolution: "Increased max_connections to 50, added connection pool monitoring with Prometheus",
    Prevention: []string{
        "Load test with realistic traffic before production deploy",
        "Monitor connection pool usage with alerts at 80% threshold",
        "Document connection pool sizing based on expected QPS",
        "Implement circuit breaker for database calls",
    },
    Severity: "high",
    Pattern: "resource_exhaustion",
    Tags: []string{"database", "performance", "production", "incident"},
})
```

Recorded as FAIL-012."

### Example 3: Record Code Pattern Decision

User: "I've decided all our error handling should wrap errors with context"

AI Agent: "Great practice! Let me record this:

```go
client.CreateADR(context.ADRRequest{
    Title: "Error Wrapping Strategy with Context",
    Decision: "Always wrap errors using fmt.Errorf with %w verb to preserve error chain",
    Context: "Need better error tracing in production for debugging. Generic errors make troubleshooting difficult",
    OptionsConsidered: map[string][]string{
        "fmt.Errorf with %w": {
            "Preserves error chain",
            "Standard library",
            "Error.Is and Error.As support",
        },
        "pkg/errors": {
            "Stack traces",
            "External dependency",
            "Deprecated in favor of stdlib",
        },
        "No wrapping": {
            "Simple",
            "Loses context",
            "Hard to debug",
        },
    },
    Tags: []string{"golang", "error-handling", "best-practices"},
    Stakeholders: []string{"backend-team"},
})
```

Recorded as ADR-005."

## AI Agent Workflow

### When User Makes Decision

1. **Detect decision**: User says "I decided to..." or "We're using..."
2. **Ask permission**: "Should I record this as an ADR?"
3. **Gather details**: Ask about context, alternatives considered
4. **Create ADR**: Call Context Engineering API
5. **Confirm**: "Recorded as ADR-XXX"

### When User Reports Failure

1. **Detect failure**: User says "we had an issue" or "bug in production"
2. **Ask permission**: "Should I record this incident?"
3. **Gather details**: Root cause, symptoms, resolution, prevention
4. **Create failure record**: Call Context Engineering API
5. **Confirm**: "Recorded as FAIL-XXX"

### When User Fixes Bug

1. **During fix discussion**: User explains what went wrong
2. **After fix**: "Should I document this for future reference?"
3. **Create failure record**: With detailed resolution steps
4. **Link to code**: Reference PRs or commits if available

## Environment Variables

- `CONTEXT_API_URL` - Context Engineering API (default: http://localhost:4000/api)

## Prerequisites

- Context Engineering server running
- User permission to write data
- Network connectivity to API

## Testing

```bash
# Test ADR creation
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Decision",
    "decision": "Test content",
    "context": "Testing the integration"
  }'

# Expected: {"id": "ADR-XXX", "status": "created", ...}

# Test failure recording
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Failure",
    "root_cause": "Test cause",
    "symptoms": "Test symptoms",
    "resolution": "Test resolution",
    "severity": "low"
  }'

# Expected: {"id": "FAIL-XXX", "status": "created", ...}
```

## Error Handling

If recording fails:
```go
if err := client.CreateADR(req); err != nil {
    log.Printf("Warning: Could not record ADR: %v", err)
    // Continue execution - recording is non-critical
}
```

Recording should be non-blocking and gracefully degrade if Context Engineering is unavailable.
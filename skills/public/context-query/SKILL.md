---
name: context-query
description: Query the Context Engineering System for organizational knowledge including ADRs (architectural decisions), failure incidents, meeting decisions, and git snapshots. Use this skill when you need to understand past decisions, known issues, or recent changes before implementing features or making decisions.
triggers:
  - past decisions
  - why did we
  - known issues
  - architecture
  - architectural decision
  - ADR
  - failure
  - bug history
  - what have we tried
  - database
  - authentication
  - API design
  - error
  - fix
  - resolution
  - how to resolve
  - remediate
version: 1.1.0
---

# Context Engineering Query Skill

## Purpose

Query organizational knowledge stored in the Context Engineering System. Provides access to:
- **ADRs**: Why architectural choices were made
- **Failures**: Known bugs, incidents, and their resolutions
- **Meetings**: Planning sessions, retrospectives, architecture reviews
- **Snapshots**: Git commits and deployment records

## When to Use

- Before implementing new features — check for existing ADRs
- When encountering errors — search for similar past failures
- When debugging — find known patterns and resolutions
- When asking "why was this done this way?" — query decisions
- During architecture reviews — get full domain context

## API Reference

The Context Engineering Service runs at `http://localhost:4000`.

### Main Query (Semantic Search)

```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "your natural language question", "max_tokens": 3000}'
```

Response:
```json
{
  "query_id": "qry_abc123def456",
  "key_decisions": [
    {"id": "ADR-001", "type": "adr", "title": "Choose PostgreSQL", "content": "...", "tags": [...]}
  ],
  "known_issues": [
    {"id": "FAIL-001", "type": "failure", "title": "Connection Pool Exhaustion", "content": "...", "tags": [...]}
  ],
  "recent_changes": [
    {"id": "MEET-001", "type": "meeting", "title": "Architecture Review", "content": "...", "tags": [...]}
  ],
  "total_items": 3
}
```

**Important:** Save the `query_id` from the response — it's required for submitting feedback.

### List by Type

```bash
# List ADRs (filter by status: active, superseded, archived)
curl http://localhost:4000/api/adr
curl http://localhost:4000/api/adr?status=active

# List failures (filter by status: investigating, resolved, recurring)
curl http://localhost:4000/api/failure
curl http://localhost:4000/api/failure?status=resolved

# List meetings
curl http://localhost:4000/api/meeting

# Get specific item with related graph items
curl http://localhost:4000/api/adr/ADR-001
curl http://localhost:4000/api/failure/FAIL-001
curl http://localhost:4000/api/meeting/MEET-001
```

### Domain Filtering

```bash
curl http://localhost:4000/api/context/domain/database
curl http://localhost:4000/api/context/domain/security
```

### Timeline

```bash
curl "http://localhost:4000/api/context/timeline?from=2026-01-01&to=2026-12-31"
```

### Recent Items

```bash
curl http://localhost:4000/api/context/recent
curl "http://localhost:4000/api/context/recent?limit=5"
```

### Graph Traversal

```bash
# Find items related to ADR-001 within 2 hops
curl "http://localhost:4000/api/graph/related/ADR-001?type=adr&depth=2"
```

## Feedback Loop Protocol

After querying and using context, submit feedback to improve future results.

### Submit Feedback

```bash
curl -X POST http://localhost:4000/api/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "qry_abc123def456",
    "query_text": "database connection pooling",
    "overall_rating": 4,
    "items_helpful": ["ADR-001", "FAIL-001"],
    "items_not_helpful": ["MEET-003"],
    "items_used": ["ADR-001"],
    "missing_context": "Need more info on connection string formats",
    "agent_id": "claude-3-opus",
    "session_id": "sess_xyz789",
    "metadata": {"task_type": "debugging", "domain": "database"}
  }'
```

Response:
```json
{
  "status": "recorded",
  "feedback_id": "fb_001"
}
```

**Fields:**
- `query_id` (required): The ID returned from your context query
- `query_text` (optional): Original query for reference
- `overall_rating` (optional): 1-5 scale, overall helpfulness
- `items_helpful` (optional): Array of item IDs that were useful
- `items_not_helpful` (optional): Array of item IDs that weren't relevant
- `items_used` (optional): Array of item IDs actually referenced in your work
- `missing_context` (optional): Text describing what was missing
- `agent_id` (optional): Identifier for the AI agent
- `session_id` (optional): Session identifier for correlation
- `metadata` (optional): Additional key-value pairs

### Feedback Statistics

```bash
curl http://localhost:4000/api/feedback/stats
```

Response:
```json
{
  "total_feedback": 150,
  "avg_rating": 3.8,
  "top_missing_context": ["Redis configuration", "Docker networking"],
  "most_helpful_items": [{"id": "ADR-001", "count": 42}]
}
```

### When to Submit Feedback

- After using context to complete a task (successful or not)
- Mark items that were actually used/referenced in your implementation
- Rate overall helpfulness (1 = not helpful, 5 = exactly what needed)
- Note missing context that would have been valuable
- Helps improve ranking and retrieval for future queries

## Auto-Remediation API

Find matching resolved failures when encountering errors. This searches for similar past incidents with known resolutions.

### Request

```bash
curl -X POST http://localhost:4000/api/remediate \
  -H "Content-Type: application/json" \
  -d '{
    "error_message": "connection refused to database on port 5432",
    "stack_trace": "java.sql.SQLException: Connection refused\n\tat Database.connect(Database.java:42)",
    "pattern": "connection_error"
  }'
```

**Fields:**
- `error_message` (required): The error text or exception message
- `stack_trace` (optional): Full stack trace for better matching
- `pattern` (optional): Pre-classified pattern (database_error, connection_error, etc.)

### Response

```json
{
  "matches": [
    {
      "id": "FAIL-001",
      "title": "Database Connection Pool Exhaustion",
      "similarity": 0.89,
      "resolution": "Increased pool size to 200, added connection timeout monitoring",
      "prevention": "Configure pool sizing based on expected concurrent connections",
      "pattern": "resource_exhaustion",
      "related_adrs": ["ADR-003"]
    }
  ],
  "total_matches": 1
}
```

### When to Call

- Encountering runtime errors or exceptions
- Test failures in CI/CD pipelines
- Unexpected behavior or performance degradation
- Before escalating to human intervention
- During incident response

### Go/Echo Integration

```go
func FindRemediation(errorMessage, stackTrace string) (*RemediationResponse, error) {
    payload, _ := json.Marshal(map[string]interface{}{
        "error_message": errorMessage,
        "stack_trace":   stackTrace,
    })

    resp, err := http.Post("http://localhost:4000/api/remediate",
        "application/json", bytes.NewBuffer(payload))
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var result RemediationResponse
    json.NewDecoder(resp.Body).Decode(&result)
    return &result, nil
}

// Usage in error handling
if err := db.Connect(); err != nil {
    remediation, _ := FindRemediation(err.Error(), "")
    if len(remediation.Matches) > 0 {
        log.Printf("Known issue: %s. Resolution: %s",
            remediation.Matches[0].Title,
            remediation.Matches[0].Resolution)
    }
}
```

### Python Integration

```python
def find_remediation(error_message, stack_trace=None):
    payload = {'error_message': error_message}
    if stack_trace:
        payload['stack_trace'] = stack_trace
    resp = requests.post('http://localhost:4000/api/remediate', json=payload)
    return resp.json() if resp.ok else None

# Usage
try:
    db.connect()
except Exception as e:
    remediation = find_remediation(str(e))
    if remediation and remediation['matches']:
        print(f"Resolution: {remediation['matches'][0]['resolution']}")
```

## Debate Contribution Protocol

After using context, you may optionally contribute to debates about specific resources.

### When to Contribute

- You have a substantive opinion about a resource's accuracy or usefulness
- You noticed the resource is outdated or missing critical context
- You disagree with a decision documented in an ADR
- A failure's resolution was incomplete or could be improved

### How to Contribute

Include `debate_contributions` in your feedback:

```json
{
  "query_id": "uuid-from-query-response",
  "overall_rating": 4,
  "debate_contributions": [
    {
      "resource_id": "ADR-001",
      "stance": "agree",
      "argument": "This ADR accurately captured our PostgreSQL decision and has prevented multiple revisits."
    }
  ]
}
```

### Stance Options

- `agree` - Resource is accurate and useful
- `disagree` - Resource has issues that should be addressed
- `neutral` - Observations without strong opinion
- `question` - Seeking clarification on the resource

### Retrieving Resources with Debate Details

**Include debates in context bundle:**

```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "...", "include_debates": true}'
```

Response includes debate summary in each item:

```json
{
  "key_decisions": [
    {
      "id": "ADR-001",
      "title": "Use PostgreSQL",
      "debate": {
        "status": "judged",
        "message_count": 4,
        "judgment": {
          "score": 4,
          "summary": "Agents agree this ADR is accurate but could use updated context...",
          "suggested_action": "review"
        }
      }
    }
  ]
}
```

**Get specific resource with debate:**

```bash
curl http://localhost:4000/api/adr/ADR-001
```

Returns resource with `debate` field if debate exists.

**Query debate directly:**

```bash
curl "http://localhost:4000/api/debate/by-resource?resource_id=ADR-001&resource_type=adr"
```

### Debate Lifecycle

1. Agents contribute arguments via feedback
2. At 3+ messages, a judge agent evaluates
3. Judge produces: score (1-5), summary, suggested action
4. Future queries include debate summary for that resource

## Query Patterns

### Architecture Questions
Query: `"database choice PostgreSQL MongoDB"` — returns ADRs about database selection

### Troubleshooting
Query: `"database connection timeout errors"` — returns past failures with resolutions

### Domain Context
Query with domains: `{"query": "auth decisions", "domains": ["security", "authentication"]}`

### Recent Work
Query: `"recent changes deployments"` — returns snapshots and meeting records

## Interpreting Results

**ADRs**: Check `status` (active/superseded). Read `context` for rationale, `options_considered` for alternatives. Reference by ID (e.g. ADR-001) when making related decisions.

**Failures**: Check `pattern` for categorization. Read `resolution` and `prevention` for solutions. Similar patterns across failures indicate systemic issues.

**Graph relationships**: Items reference each other by ID. An ADR's `decision` text mentioning "FAIL-042" means they're auto-linked. Follow the graph to get full context.

## Go/Echo Integration

```go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "bytes"
)

type ContextResponse struct {
    QueryID       string                   `json:"query_id"`
    KeyDecisions  []map[string]interface{} `json:"key_decisions"`
    KnownIssues   []map[string]interface{} `json:"known_issues"`
    RecentChanges []map[string]interface{} `json:"recent_changes"`
    TotalItems    int                      `json:"total_items"`
}

func QueryContext(question string) (*ContextResponse, error) {
    payload, _ := json.Marshal(map[string]interface{}{
        "query":      question,
        "max_tokens": 3000,
    })

    resp, err := http.Post(
        "http://localhost:4000/api/context/query",
        "application/json",
        bytes.NewBuffer(payload),
    )
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var result ContextResponse
    json.NewDecoder(resp.Body).Decode(&result)
    return &result, nil
}

// Echo middleware: query context before handling requests
func ContextMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
    return func(c echo.Context) error {
        // Example: check for known issues before processing
        ctx, _ := QueryContext("known issues " + c.Path())
        if len(ctx.KnownIssues) > 0 {
            c.Logger().Warnf("Known issues for %s: %v", c.Path(), ctx.KnownIssues[0]["title"])
        }
        return next(c)
    }
}
```

## Python Integration

```python
import requests

def query_context(question, max_tokens=3000):
    resp = requests.post('http://localhost:4000/api/context/query',
        json={'query': question, 'max_tokens': max_tokens})
    return resp.json() if resp.ok else None

# Example
context = query_context("database connection pooling")
for adr in context.get('key_decisions', []):
    print(f"- {adr['id']}: {adr['title']}")
for fail in context.get('known_issues', []):
    print(f"- {fail['id']}: {fail['title']}")
```

## Node.js Integration

```javascript
async function queryContext(question) {
    const resp = await fetch('http://localhost:4000/api/context/query', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({query: question, max_tokens: 3000})
    });
    return resp.json();
}
```

## Best Practices

1. **Query before you code** — check for existing decisions and known issues
2. **Use specific queries** — `"database connection pooling decisions"` not `"database"`
3. **Check multiple perspectives** — query both decisions and failures for the same topic
4. **Follow the graph** — if ADR-001 mentions FAIL-042, fetch that failure for full context
5. **Validate freshness** — check `created_date`; old decisions may be superseded

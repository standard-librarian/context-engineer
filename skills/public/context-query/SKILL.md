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
version: 1.0.0
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

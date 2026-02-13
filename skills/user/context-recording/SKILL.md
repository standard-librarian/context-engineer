---
name: context-recording
description: Record architectural decisions (ADRs), failure incidents, meeting decisions, and deployment snapshots in the Context Engineering System. Use this skill when you make decisions, encounter errors, or participate in planning discussions.
triggers:
  - record decision
  - document this
  - create ADR
  - log failure
  - record bug
  - document meeting
  - architecture decision
  - made a decision
version: 1.0.0
---

# Context Recording Skill

## Purpose

Record organizational knowledge in the Context Engineering System so future agents and developers can learn from decisions, failures, and meetings.

## Two Recording Methods

### Method A: Event Endpoints (Recommended for errors/deploys)

Auto-generates IDs, accepts flat payloads. Best for automated capture.

```
POST /api/events/error   — auto-creates FAIL-xxx from error data
POST /api/events/deploy  — auto-creates SNAP-xxx from deployment data
POST /api/events/metric  — auto-creates FAIL-xxx when threshold exceeded
POST /api/logs/stream    — batch log ingestion, auto-creates failures
```

### Method B: CRUD Endpoints (For ADRs, meetings, manual entries)

Requires caller-provided ID and nested params under a type key.

```
POST /api/adr       — body: {"adr": {...}}
POST /api/failure   — body: {"failure": {...}}
POST /api/meeting   — body: {"meeting": {...}}
POST /api/context/snapshot — body: {"commit_hash": "...", ...}
```

## Recording ADRs

Use when making architectural decisions: technology choices, patterns, API contracts, infrastructure.

```bash
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "adr": {
      "id": "ADR-001",
      "title": "Use PostgreSQL for Primary Database",
      "decision": "Use PostgreSQL for all relational data storage",
      "context": "Need ACID compliance, team has PostgreSQL expertise",
      "created_date": "2026-02-13",
      "author": "ai-agent",
      "tags": ["database", "infrastructure"]
    }
  }'
```

Required fields: `id`, `title`, `decision`, `created_date`

Optional fields: `context`, `options_considered` (map), `outcome`, `author`, `stakeholders` (string array), `tags` (string array), `status` (active/superseded/archived)

**Go/Echo example:**

```go
func CreateADR(title, decision, context string, tags []string) error {
    payload, _ := json.Marshal(map[string]interface{}{
        "adr": map[string]interface{}{
            "id":           "ADR-001",  // must be unique
            "title":        title,
            "decision":     decision,
            "context":      context,
            "created_date": time.Now().Format("2006-01-02"),
            "author":       "echo-api",
            "tags":         tags,
        },
    })

    resp, err := http.Post("http://localhost:4000/api/adr",
        "application/json", bytes.NewBuffer(payload))
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    return nil
}
```

## Recording Failures

### Via Event Endpoint (recommended — auto-generates ID)

```bash
curl -X POST http://localhost:4000/api/events/error \
  -H "Content-Type: application/json" \
  -d '{
    "title": "nil pointer dereference in handler",
    "app_name": "echo-api",
    "stack_trace": "panic: runtime error: nil pointer dereference\ngoroutine 1 [running]:\nmain.handler()\n\tserver.go:42",
    "severity": "critical",
    "environment": "production",
    "timestamp": "2026-02-13T10:30:00Z"
  }'
```

The system auto-classifies patterns: `database_error`, `connection_error`, `runtime_panic`, `resource_exhaustion`, `authentication_error`, `server_error`, `not_found`. Severity is auto-classified if omitted.

**Go/Echo error middleware:**

```go
func ErrorCaptureMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
    return func(c echo.Context) error {
        err := next(c)
        if err != nil {
            payload, _ := json.Marshal(map[string]interface{}{
                "title":       err.Error(),
                "stack_trace": fmt.Sprintf("%+v", err),
                "app_name":    "echo-api",
                "environment": os.Getenv("APP_ENV"),
                "severity":    "high",
                "timestamp":   time.Now().Format(time.RFC3339),
                "metadata": map[string]string{
                    "path":   c.Path(),
                    "method": c.Request().Method,
                },
            })

            go http.Post("http://localhost:4000/api/events/error",
                "application/json", bytes.NewBuffer(payload))
        }
        return err
    }
}

// Register in Echo
e := echo.New()
e.Use(ErrorCaptureMiddleware)
```

**Go panic recovery with capture:**

```go
func PanicRecoveryMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
    return func(c echo.Context) error {
        defer func() {
            if r := recover(); r != nil {
                stack := debug.Stack()
                payload, _ := json.Marshal(map[string]interface{}{
                    "title":       fmt.Sprintf("panic: %v", r),
                    "stack_trace": string(stack),
                    "app_name":    "echo-api",
                    "severity":    "critical",
                    "timestamp":   time.Now().Format(time.RFC3339),
                })

                go http.Post("http://localhost:4000/api/events/error",
                    "application/json", bytes.NewBuffer(payload))

                c.JSON(500, map[string]string{"error": "Internal Server Error"})
            }
        }()
        return next(c)
    }
}
```

### Via CRUD Endpoint (when you need a specific ID)

```bash
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "failure": {
      "id": "FAIL-001",
      "title": "Database Connection Pool Exhaustion",
      "root_cause": "Pool size (50) insufficient for peak load",
      "symptoms": "API timeouts, 500 errors",
      "resolution": "Increased pool to 200, added monitoring",
      "incident_date": "2026-02-13",
      "severity": "high",
      "status": "resolved",
      "pattern": "resource_exhaustion",
      "tags": ["database", "performance"]
    }
  }'
```

Required fields: `id`, `title`, `incident_date`, `root_cause`

## Recording Deployments

```bash
curl -X POST http://localhost:4000/api/events/deploy \
  -H "Content-Type: application/json" \
  -d '{
    "app_name": "echo-api",
    "version": "v1.2.3",
    "environment": "production",
    "deployer": "alice@company.com",
    "commit_hash": "abc123def",
    "changes": ["Added health endpoint", "Fixed goroutine leak"]
  }'
```

Creates a SNAP-xxx record with embedding for semantic search.

**Go CI/CD integration:**

```go
func NotifyDeploy(appName, version, commitHash, deployer string, changes []string) {
    payload, _ := json.Marshal(map[string]interface{}{
        "app_name":    appName,
        "version":     version,
        "commit_hash": commitHash,
        "deployer":    deployer,
        "environment": os.Getenv("DEPLOY_ENV"),
        "changes":     changes,
    })

    http.Post("http://localhost:4000/api/events/deploy",
        "application/json", bytes.NewBuffer(payload))
}
```

## Recording Metrics

```bash
curl -X POST http://localhost:4000/api/events/metric \
  -H "Content-Type: application/json" \
  -d '{
    "app_name": "echo-api",
    "metric_name": "api_latency_p99",
    "value": 1500,
    "threshold": 1000,
    "severity": "high"
  }'
```

Only creates a failure record when `value > threshold`. Returns `{"status": "ok"}` otherwise.

**Go metrics reporter:**

```go
func ReportMetric(name string, value, threshold float64) {
    payload, _ := json.Marshal(map[string]interface{}{
        "app_name":    "echo-api",
        "metric_name": name,
        "value":       value,
        "threshold":   threshold,
    })

    http.Post("http://localhost:4000/api/events/metric",
        "application/json", bytes.NewBuffer(payload))
}

// Usage in Echo middleware
func MetricsMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
    return func(c echo.Context) error {
        start := time.Now()
        err := next(c)
        duration := time.Since(start).Milliseconds()

        if duration > 1000 { // Report slow requests
            go ReportMetric("request_duration_ms", float64(duration), 1000)
        }
        return err
    }
}
```

## Log Streaming

Send structured log batches for automatic error extraction:

```bash
curl -X POST http://localhost:4000/api/logs/stream \
  -H "Content-Type: application/json" \
  -d '[
    {"level": "ERROR", "message": "connection refused", "app": "echo-api", "timestamp": "2026-02-13T10:00:00Z"},
    {"level": "INFO", "message": "request completed", "app": "echo-api"},
    {"level": "PANIC", "message": "nil pointer dereference", "app": "echo-api"}
  ]'
```

Only ERROR/CRITICAL/FATAL/PANIC entries create failure records. INFO/DEBUG are accepted but ignored.

## Recording Meetings

```bash
curl -X POST http://localhost:4000/api/meeting \
  -H "Content-Type: application/json" \
  -d '{
    "meeting": {
      "id": "MEET-001",
      "meeting_title": "Q1 Architecture Review",
      "date": "2026-02-13",
      "decisions": {
        "items": [
          {"decision": "Migrate to microservices", "rationale": "Improve deployment independence"}
        ]
      },
      "attendees": ["alice@company.com", "bob@company.com"],
      "tags": ["architecture", "planning"]
    }
  }'
```

Required fields: `id`, `meeting_title`, `date`, `decisions`

## Best Practices

1. **Record immediately** — context is freshest right after a decision or incident
2. **Be specific** — `"Use PostgreSQL for User Data"` not `"Database stuff"`
3. **Link related items** — reference other IDs in text: `"Based on FAIL-042, we..."`
4. **Use event endpoints for automation** — they auto-generate IDs and classify patterns
5. **Use CRUD endpoints for deliberate records** — when you want control over ID and content

## Auto-Generated Features

The system automatically:
- Generates embeddings for semantic search
- Extracts tags from content (database, performance, security, etc.)
- Creates graph relationships when text references other IDs (ADR-001, FAIL-042, etc.)
- Classifies error patterns and severity (for event endpoints)

## Feedback After Resolution

When a failure is resolved, submit feedback to improve future remediation:

1. **Query context** for related failures or ADRs
2. **Record the resolution** by updating the failure with `resolution` and `prevention` fields
3. **Submit feedback** indicating which items helped resolve the issue

```bash
# Update failure with resolution
curl -X PUT http://localhost:4000/api/failure/FAIL-001 \
  -H "Content-Type: application/json" \
  -d '{
    "failure": {
      "status": "resolved",
      "resolution": "Added exponential backoff retry logic",
      "prevention": "Use circuit breaker pattern for external API calls"
    }
  }'

# Submit feedback (if this failure came from a context query)
curl -X POST http://localhost:4000/api/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "query_id": "qry_abc123",
    "overall_rating": 5,
    "items_used": ["FAIL-001", "ADR-003"],
    "agent_id": "my-agent"
  }'
```

This feedback loop helps the system learn which resolutions are most effective and improves ranking for future remediation queries.

## Debates on Recorded Items

Any ADR, Failure, or Meeting you record can be debated. The system automatically creates debate slots when feedback includes debate contributions. Monitor your recorded items for debate activity:

```bash
# Check for debates on your items
curl "http://localhost:4000/api/debate/by-resource?resource_id=ADR-001&resource_type=adr"
```

When an item receives 3+ debate contributions, a judge evaluates and produces:
- Overall score (1-5)
- Summary of the debate
- Suggested action (none, review, update, deprecate)

Use debate feedback to improve your recorded knowledge over time.

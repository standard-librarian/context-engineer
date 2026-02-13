# Failure Template

## Via Event Endpoint (recommended)

Auto-generates ID, classifies pattern and severity.

```json
{
  "title": "[System/Component] [Type of Failure]",
  "app_name": "my-app",
  "stack_trace": "full stack trace here",
  "severity": "low | medium | high | critical",
  "environment": "production",
  "timestamp": "2026-02-13T10:30:00Z"
}
```

```
POST /api/events/error
```

## Via CRUD Endpoint

Full control over all fields.

```json
{
  "failure": {
    "id": "FAIL-001",
    "title": "[System/Component] [Type of Failure]",
    "root_cause": "The actual underlying cause",
    "symptoms": "What users/systems experienced",
    "impact": "Scope of the impact",
    "resolution": "What fixed it",
    "prevention": ["Step 1 to prevent recurrence", "Step 2"],
    "incident_date": "2026-02-13",
    "severity": "high",
    "status": "resolved",
    "pattern": "resource_exhaustion | database_error | connection_error | runtime_panic | authentication_error | server_error",
    "tags": ["system", "component"],
    "author": "ai-agent"
  }
}
```

```
POST /api/failure
PUT  /api/failure/:id
```

## Required Fields (CRUD)

- `id` — Unique ID in format `FAIL-001`
- `title` — Brief description
- `incident_date` — ISO 8601 date
- `root_cause` — The actual cause

## Go Example (Event Endpoint)

```go
payload, _ := json.Marshal(map[string]interface{}{
    "title":       err.Error(),
    "stack_trace": string(debug.Stack()),
    "app_name":    "echo-api",
    "severity":    "high",
    "timestamp":   time.Now().Format(time.RFC3339),
})

http.Post("http://localhost:4000/api/events/error",
    "application/json", bytes.NewBuffer(payload))
```

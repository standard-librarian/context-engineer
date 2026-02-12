# ADR Template

## Payload

```json
{
  "adr": {
    "id": "ADR-001",
    "title": "[Technology/Pattern] for [Purpose]",
    "decision": "We will use [Technology] to [achieve goal]",
    "context": "Problem: [problem]. Constraints: [constraints]. Requirements: [requirements].",
    "options_considered": {
      "option_a": {"pros": "...", "cons": "..."},
      "option_b": {"pros": "...", "cons": "..."}
    },
    "outcome": "To be determined after production use",
    "created_date": "2026-02-13",
    "author": "ai-agent",
    "tags": ["category1", "category2"],
    "status": "active"
  }
}
```

## Required Fields

- `id` — Unique ID in format `ADR-001`
- `title` — Brief description of the decision
- `decision` — What was decided
- `created_date` — ISO 8601 date

## Endpoint

```
POST /api/adr
PUT  /api/adr/:id
```

## Go Example

```go
payload, _ := json.Marshal(map[string]interface{}{
    "adr": map[string]interface{}{
        "id":           "ADR-001",
        "title":        "Use Echo for HTTP Framework",
        "decision":     "Adopt Echo v4 for all Go HTTP services",
        "context":      "Need lightweight, fast HTTP framework with middleware support",
        "created_date": time.Now().Format("2006-01-02"),
        "author":       "team",
        "tags":         []string{"api", "infrastructure"},
    },
})

http.Post("http://localhost:4000/api/adr", "application/json", bytes.NewBuffer(payload))
```

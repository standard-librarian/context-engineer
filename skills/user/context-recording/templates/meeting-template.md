# Meeting Template

## Payload

```json
{
  "meeting": {
    "id": "MEET-001",
    "meeting_title": "[Type] - [Topic]",
    "date": "2026-02-13",
    "decisions": {
      "items": [
        {
          "decision": "What was decided",
          "rationale": "Why this decision was made",
          "action_items": [
            {"task": "Specific task", "owner": "person@company.com", "due": "2026-03-01"}
          ]
        }
      ]
    },
    "attendees": ["person1@company.com", "person2@company.com"],
    "tags": ["planning", "architecture"],
    "status": "active"
  }
}
```

## Required Fields

- `id` — Unique ID in format `MEET-001`
- `meeting_title` — Meeting name
- `date` — ISO 8601 date
- `decisions` — Map of decisions made

## Endpoint

```
POST /api/meeting
PUT  /api/meeting/:id
```

## Go Example

```go
decisions := map[string]interface{}{
    "items": []map[string]interface{}{
        {
            "decision":  "Adopt context engineering for all services",
            "rationale": "Need centralized decision and failure tracking",
        },
    },
}

payload, _ := json.Marshal(map[string]interface{}{
    "meeting": map[string]interface{}{
        "id":            "MEET-001",
        "meeting_title": "Architecture Review",
        "date":          time.Now().Format("2006-01-02"),
        "decisions":     decisions,
        "attendees":     []string{"alice@company.com"},
        "tags":          []string{"architecture"},
    },
})

http.Post("http://localhost:4000/api/meeting", "application/json", bytes.NewBuffer(payload))
```

# API Reference

Complete API documentation for the Context Engineering System.

**Base URL:** `http://localhost:4000/api` (development)

**Content-Type:** `application/json`

**Authentication:** None (add in production)

---

## Table of Contents

- [Context Queries](#context-queries)
- [ADRs](#adrs-architectural-decision-records)
- [Failures](#failures-incident-reports)
- [Meetings](#meetings-decisions)
- [Graph Queries](#graph-queries)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)

---

## Context Queries

### Query Context

Intelligent context retrieval with semantic search and graph expansion.

```
POST /api/context/query
```

**Request Body:**
```json
{
  "query": "database performance issues",
  "max_tokens": 3000,
  "domains": ["database", "performance"]
}
```

**Parameters:**
- `query` (required, string): Natural language question
- `max_tokens` (optional, integer): Max tokens in response (default: 4000)
- `domains` (optional, array): Filter by domain tags

**Response:**
```json
{
  "key_decisions": [
    {
      "id": "ADR-001",
      "type": "adr",
      "title": "Choose PostgreSQL over MongoDB",
      "decision": "Use PostgreSQL as primary database",
      "context": "Need ACID compliance and team expertise",
      "tags": ["database", "infrastructure"],
      "created_date": "2025-06-15",
      "score": 0.89
    }
  ],
  "known_issues": [
    {
      "id": "FAIL-042",
      "type": "failure",
      "title": "Database Connection Pool Exhaustion",
      "root_cause": "Pool size insufficient for peak load",
      "resolution": "Increased pool to 200, added monitoring",
      "pattern": "resource_exhaustion",
      "severity": "high",
      "score": 0.85
    }
  ],
  "recent_changes": [
    {
      "id": "MEET-003",
      "type": "meeting",
      "title": "Q4 Architecture Review",
      "date": "2025-11-01",
      "tags": ["architecture", "planning"]
    }
  ],
  "total_items": 12
}
```

---

### Get Recent Context

Retrieve recently created/updated items.

```
GET /api/context/recent?limit=10
```

**Query Parameters:**
- `limit` (optional, integer): Number of items (default: 10, max: 50)

**Response:**
```json
[
  {
    "id": "ADR-004",
    "type": "adr",
    "title": "Add Redis Caching",
    "created_at": "2026-02-12T10:30:00Z",
    "tags": ["cache", "redis"]
  }
]
```

---

### Get Timeline

Chronological view of all context items in a date range.

```
GET /api/context/timeline?from=2026-01-01&to=2026-02-13
```

**Query Parameters:**
- `from` (required, date): Start date (YYYY-MM-DD)
- `to` (required, date): End date (YYYY-MM-DD)

**Response:**
```json
[
  {
    "id": "ADR-004",
    "type": "adr",
    "title": "Add Redis Caching",
    "created_date": "2026-02-10",
    "tags": ["cache"]
  },
  {
    "id": "FAIL-043",
    "type": "failure",
    "title": "Cache Miss Storm",
    "incident_date": "2026-02-11",
    "severity": "medium"
  }
]
```

---

### Get Domain Context

All items tagged with a specific domain.

```
GET /api/context/domain/:name
```

**Path Parameters:**
- `name` (required, string): Domain tag name

**Example:**
```
GET /api/context/domain/database
```

**Response:**
```json
{
  "domain": "database",
  "items": [
    {
      "id": "ADR-001",
      "type": "adr",
      "title": "Choose PostgreSQL",
      "tags": ["database", "postgresql"]
    },
    {
      "id": "FAIL-042",
      "type": "failure",
      "title": "Connection Pool Exhaustion",
      "tags": ["database", "performance"]
    }
  ],
  "count": 2
}
```

---

### Create Snapshot

Create a snapshot from git commit data.

```
POST /api/context/snapshot
```

**Request Body:**
```json
{
  "commit_hash": "abc123def456",
  "commit_message": "feat: Add caching layer",
  "changed_files": "lib/cache.ex,test/cache_test.exs",
  "author": "alice@company.com",
  "commit_type": "feature",
  "references": "ADR-004,FAIL-043"
}
```

**Parameters:**
- `commit_hash` (required, string): Git commit SHA
- `commit_message` (required, string): Commit message
- `changed_files` (optional, string): Comma-separated file paths
- `author` (required, string): Committer email
- `commit_type` (optional, string): feature|bugfix|migration|test|maintenance
- `references` (optional, string): Comma-separated IDs (ADR-001, FAIL-042)

**Response:**
```json
{
  "id": "MEET-004",
  "status": "created",
  "title": "Code commit: feat: Add caching layer",
  "references": ["ADR-004", "FAIL-043"]
}
```

---

## ADRs (Architectural Decision Records)

### Create ADR

```
POST /api/adr
```

**Request Body:**
```json
{
  "title": "Use Redis for Caching",
  "decision": "Implement Redis as primary cache layer",
  "context": "Need distributed caching for session data. Team has Redis expertise.",
  "options_considered": {
    "redis": {
      "pros": "Fast, distributed, team expertise",
      "cons": "Additional infrastructure"
    },
    "memcached": {
      "pros": "Simple, lightweight",
      "cons": "Limited data structures"
    }
  },
  "tags": ["cache", "redis", "performance"],
  "stakeholders": ["engineering", "devops"]
}
```

**Parameters:**
- `title` (required, string): Brief decision title
- `decision` (required, string): What was decided
- `context` (optional, string): Why decision was needed
- `options_considered` (optional, object): Alternatives evaluated
- `outcome` (optional, string): Results after implementation
- `status` (optional, string): active|superseded|archived (default: active)
- `created_date` (optional, date): Decision date (default: today)
- `supersedes` (optional, array): IDs of superseded ADRs
- `tags` (optional, array): Category tags (auto-extracted if omitted)
- `author` (optional, string): Author email
- `stakeholders` (optional, array): Affected teams

**Response:**
```json
{
  "id": "ADR-004",
  "status": "created",
  "title": "Use Redis for Caching",
  "tags": ["cache", "redis", "performance"],
  "relationships_created": ["ADR-004->FAIL-042"]
}
```

---

### Get ADR

```
GET /api/adr/:id
```

**Path Parameters:**
- `id` (required, string): ADR ID (e.g., "ADR-001")

**Response:**
```json
{
  "id": "ADR-001",
  "title": "Choose PostgreSQL over MongoDB",
  "decision": "Use PostgreSQL as primary database",
  "context": "Need ACID compliance...",
  "options_considered": {...},
  "outcome": "Successfully implemented...",
  "status": "active",
  "created_date": "2025-06-15",
  "supersedes": [],
  "superseded_by": null,
  "tags": ["database", "postgresql"],
  "author": "jane@company.com",
  "stakeholders": ["engineering"],
  "access_count_30d": 45,
  "created_at": "2025-06-15T10:00:00Z",
  "updated_at": "2025-12-01T14:30:00Z",
  "related_items": [
    {
      "id": "FAIL-042",
      "type": "failure",
      "relationship": "caused_by"
    },
    {
      "id": "MEET-003",
      "type": "meeting",
      "relationship": "discussed_in"
    }
  ]
}
```

---

### List ADRs

```
GET /api/adr?status=active&tags=database
```

**Query Parameters:**
- `status` (optional, string): Filter by status (active|superseded|archived)
- `tags` (optional, string): Filter by tag
- `limit` (optional, integer): Items per page (default: 50)
- `offset` (optional, integer): Pagination offset

**Response:**
```json
[
  {
    "id": "ADR-001",
    "title": "Choose PostgreSQL over MongoDB",
    "decision": "Use PostgreSQL as primary database",
    "tags": ["database", "postgresql"],
    "status": "active",
    "created_date": "2025-06-15"
  },
  {
    "id": "ADR-003",
    "title": "Use Redis for Caching",
    "decision": "Implement Redis cache layer",
    "tags": ["cache", "redis"],
    "status": "active",
    "created_date": "2025-09-20"
  }
]
```

---

### Update ADR

```
PUT /api/adr/:id
```

**Path Parameters:**
- `id` (required, string): ADR ID

**Request Body (partial update):**
```json
{
  "outcome": "Successfully implemented. Reduced query time by 40%.",
  "status": "active"
}
```

**Updatable Fields:**
- `decision`, `context`, `options_considered`, `outcome`, `status`, `tags`, `stakeholders`

**Response:**
```json
{
  "id": "ADR-001",
  "status": "updated",
  "updated_fields": ["outcome", "updated_at"]
}
```

---

## Failures (Incident Reports)

### Create Failure

```
POST /api/failure
```

**Request Body:**
```json
{
  "title": "API Gateway Timeout Under Load",
  "root_cause": "Connection pool exhausted during traffic spike",
  "symptoms": "API response times increased to 30s, 500 errors",
  "impact": "15% of users affected for 2 hours",
  "resolution": "Increased pool size to 200, added monitoring",
  "prevention": [
    "Added connection pool metrics",
    "Set up alerts for pool > 80%",
    "Updated load testing scenarios"
  ],
  "severity": "high",
  "pattern": "resource_exhaustion",
  "tags": ["api", "performance", "infrastructure"]
}
```

**Parameters:**
- `title` (required, string): Brief failure description
- `root_cause` (required, string): Actual cause (not symptoms)
- `incident_date` (optional, date): When it occurred (default: today)
- `symptoms` (optional, string): What was observed
- `impact` (optional, string): User/system impact
- `resolution` (optional, string): How it was fixed
- `prevention` (optional, array): Steps to prevent recurrence
- `severity` (optional, string): low|medium|high|critical (default: medium)
- `status` (optional, string): investigating|resolved|recurring (default: investigating)
- `pattern` (optional, string): Failure category
- `tags` (optional, array): Auto-extracted if omitted
- `author` (optional, string): Reporter email
- `lessons_learned` (optional, string): Key takeaways

**Response:**
```json
{
  "id": "FAIL-043",
  "status": "created",
  "title": "API Gateway Timeout Under Load",
  "pattern": "resource_exhaustion",
  "relationships_created": ["FAIL-043->ADR-001"]
}
```

---

### Get Failure

```
GET /api/failure/:id
```

**Response:**
```json
{
  "id": "FAIL-042",
  "title": "Database Connection Pool Exhaustion",
  "incident_date": "2025-11-03",
  "severity": "high",
  "root_cause": "Pool size insufficient for peak load",
  "symptoms": "API timeouts, 500 errors",
  "impact": "15% users affected for 2 hours",
  "resolution": "Increased pool to 200, added monitoring",
  "prevention": [
    "Added pool metrics",
    "Set up alerts",
    "Updated load tests"
  ],
  "status": "resolved",
  "pattern": "resource_exhaustion",
  "tags": ["database", "performance"],
  "lessons_learned": "Always monitor resource utilization",
  "author": "oncall@company.com",
  "access_count_30d": 23,
  "created_at": "2025-11-03T14:00:00Z",
  "updated_at": "2025-11-04T10:00:00Z",
  "related_items": [
    {
      "id": "ADR-001",
      "type": "adr",
      "relationship": "caused_by"
    }
  ]
}
```

---

### List Failures

```
GET /api/failure?status=resolved&pattern=resource_exhaustion
```

**Query Parameters:**
- `status` (optional): investigating|resolved|recurring
- `pattern` (optional): Filter by failure pattern
- `severity` (optional): low|medium|high|critical
- `tags` (optional): Filter by tag
- `limit` (optional, integer): Default 50
- `offset` (optional, integer): Pagination

**Response:**
```json
[
  {
    "id": "FAIL-042",
    "title": "Connection Pool Exhaustion",
    "incident_date": "2025-11-03",
    "severity": "high",
    "status": "resolved",
    "pattern": "resource_exhaustion"
  }
]
```

---

### Update Failure

```
PUT /api/failure/:id
```

**Request Body:**
```json
{
  "resolution": "Increased pool size and added monitoring",
  "status": "resolved",
  "prevention": [
    "Added metrics dashboard",
    "Set up alerting"
  ]
}
```

**Response:**
```json
{
  "id": "FAIL-042",
  "status": "updated",
  "updated_fields": ["resolution", "status", "prevention"]
}
```

---

## Meetings (Decisions)

### Create Meeting

```
POST /api/meeting
```

**Request Body:**
```json
{
  "meeting_title": "Q1 2026 Architecture Review",
  "date": "2026-02-10",
  "decisions": [
    {
      "decision": "Migrate to microservices by Q3",
      "rationale": "Improve team autonomy and deployment speed",
      "action_items": [
        {
          "task": "Create migration plan",
          "owner": "alice@company.com",
          "due": "2026-03-01",
          "status": "in_progress"
        }
      ]
    }
  ],
  "attendees": ["alice@company.com", "bob@company.com"],
  "tags": ["architecture", "planning"]
}
```

**Parameters:**
- `meeting_title` (required, string): Meeting name
- `date` (required, date): Meeting date
- `decisions` (required, array): Decisions made
  - `decision` (string): What was decided
  - `rationale` (string): Why
  - `action_items` (array): Tasks with owners
- `attendees` (optional, array): Participant emails
- `tags` (optional, array): Auto-extracted if omitted
- `status` (optional, string): active|completed|cancelled

**Response:**
```json
{
  "id": "MEET-004",
  "status": "created",
  "title": "Q1 2026 Architecture Review",
  "date": "2026-02-10"
}
```

---

### Get Meeting

```
GET /api/meeting/:id
```

**Response:**
```json
{
  "id": "MEET-003",
  "meeting_title": "Q4 2025 Architecture Review",
  "date": "2025-10-15",
  "decisions": [...],
  "attendees": ["alice@company.com", "bob@company.com"],
  "tags": ["architecture"],
  "status": "active",
  "created_at": "2025-10-15T14:00:00Z"
}
```

---

### List Meetings

```
GET /api/meeting?status=active
```

**Query Parameters:**
- `status` (optional): active|completed|cancelled
- `limit` (optional): Default 50
- `offset` (optional): Pagination

---

### Update Meeting

```
PUT /api/meeting/:id
```

**Request Body:**
```json
{
  "status": "completed"
}
```

---

## Graph Queries

### Get Related Items

Find items connected via relationships.

```
GET /api/graph/related/:id?type=adr&depth=2
```

**Path Parameters:**
- `id` (required, string): Item ID (e.g., "ADR-001")

**Query Parameters:**
- `type` (required, string): Item type (adr|failure|meeting)
- `depth` (optional, integer): Traversal depth 1-5 (default: 2)

**Response:**
```json
{
  "item": {
    "id": "ADR-001",
    "type": "adr",
    "title": "Choose PostgreSQL"
  },
  "related": [
    {
      "id": "FAIL-042",
      "type": "failure",
      "title": "Connection Pool Exhaustion",
      "relationship": "caused_by",
      "depth": 1
    },
    {
      "id": "MEET-003",
      "type": "meeting",
      "title": "Architecture Review",
      "relationship": "discussed_in",
      "depth": 1
    },
    {
      "id": "ADR-002",
      "type": "adr",
      "title": "Add Connection Pooling",
      "relationship": "related_to",
      "depth": 2
    }
  ],
  "total_related": 3
}
```

---

## Error Handling

### Error Response Format

All errors return JSON:

```json
{
  "error": "Error message",
  "details": "Additional context",
  "code": "ERROR_CODE"
}
```

### HTTP Status Codes

- `200` OK - Success
- `201` Created - Resource created
- `400` Bad Request - Invalid input
- `404` Not Found - Resource not found
- `422` Unprocessable Entity - Validation failed
- `429` Too Many Requests - Rate limit exceeded
- `500` Internal Server Error - Server error

### Common Errors

**Validation Error (422):**
```json
{
  "error": "Validation failed",
  "details": {
    "title": ["can't be blank"],
    "decision": ["can't be blank"]
  }
}
```

**Not Found (404):**
```json
{
  "error": "Resource not found",
  "details": "ADR with id 'ADR-999' not found"
}
```

**Rate Limit (429):**
```json
{
  "error": "Rate limit exceeded",
  "details": "Maximum 10 requests per minute",
  "retry_after": 45
}
```

---

## Rate Limiting

**Limits:**
- 10 requests per minute per client
- 100 requests per hour per client

**Headers:**
```
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1707826800
```

**Exceeding Limits:**
- Returns 429 status
- `Retry-After` header indicates wait time
- Resets every minute

---

## Best Practices

### Querying Context

1. **Be specific:** "database connection pool issues" not "database"
2. **Use domains:** Narrow results with domain filters
3. **Set token limits:** Balance detail vs. response size
4. **Cache results:** Avoid redundant queries

### Creating Content

1. **Include context:** Explain "why" not just "what"
2. **Link related items:** Reference ADR-XXX, FAIL-XXX in text
3. **Use tags:** Help categorization and search
4. **Update outcomes:** Add results after implementation

### Performance

1. **Batch creates:** Use multiple calls if creating many items
2. **Limit results:** Use pagination for large result sets
3. **Use graph depth wisely:** Depth 1-2 is usually sufficient
4. **Cache embeddings:** Consider Redis in production

---

## Examples

### Complete Workflow

```bash
# 1. Query for existing context
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "caching decisions"}'

# 2. Create ADR for new decision
curl -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Use Redis for Caching",
    "decision": "Implement Redis as primary cache",
    "context": "Need distributed caching",
    "tags": ["cache", "redis"]
  }'
# Returns: {"id": "ADR-004", ...}

# 3. Later, record failure
curl -X POST http://localhost:4000/api/failure \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Cache Miss Storm",
    "root_cause": "Cold cache after deployment",
    "resolution": "Added cache warming - see ADR-004"
  }'
# Automatically links to ADR-004

# 4. Query related items
curl "http://localhost:4000/api/graph/related/ADR-004?type=adr&depth=2"
# Shows failure and other related items
```

---

**API Version:** 1.0.0

**Last Updated:** 2026-02-13

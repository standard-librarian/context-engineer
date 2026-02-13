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
version: 1.2.0
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
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"

    "github.com/labstack/echo/v4"
)

// Response types
type ContextResponse struct {
    QueryID       string                   `json:"query_id"`
    KeyDecisions  []map[string]interface{} `json:"key_decisions"`
    KnownIssues   []map[string]interface{} `json:"known_issues"`
    RecentChanges []map[string]interface{} `json:"recent_changes"`
    TotalItems    int                      `json:"total_items"`
}

type RemediationResponse struct {
    Pattern      string          `json:"pattern"`
    Severity     string          `json:"severity"`
    Incidents    []IncidentMatch `json:"similar_incidents"`
    Actions      []string        `json:"suggested_actions"`
}

type IncidentMatch struct {
    ID           string   `json:"id"`
    Title        string   `json:"title"`
    RootCause    string   `json:"root_cause"`
    Resolution   string   `json:"resolution"`
    Prevention   []string `json:"prevention"`
    Similarity   float64  `json:"similarity"`
}

type FeedbackResponse struct {
    ID                string             `json:"id"`
    QueryID           string             `json:"query_id"`
    DebatesProcessed  []DebateProcessed  `json:"debates_processed"`
}

type DebateProcessed struct {
    ResourceID   string `json:"resource_id"`
    DebateID     string `json:"debate_id"`
    MessageCount int    `json:"message_count"`
}

type DebateContribution struct {
    ResourceID string `json:"resource_id"`
    Stance     string `json:"stance"`
    Argument   string `json:"argument"`
}

const contextServiceURL = "http://localhost:4000"

// QueryContext performs semantic search for organizational knowledge
func QueryContext(question string, includeDebates bool) (*ContextResponse, error) {
    payload := map[string]interface{}{
        "query":      question,
        "max_tokens": 3000,
    }
    if includeDebates {
        payload["include_debates"] = true
    }

    resp, err := http.Post(
        contextServiceURL+"/api/context/query",
        "application/json",
        bytes.NewBuffer(mustMarshal(payload)),
    )
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var result ContextResponse
    json.NewDecoder(resp.Body).Decode(&result)
    return &result, nil
}

// FindRemediation searches for similar resolved failures
func FindRemediation(errorMessage, stackTrace string) (*RemediationResponse, error) {
    payload := map[string]interface{}{
        "error_message": errorMessage,
        "stack_trace":   stackTrace,
    }

    resp, err := http.Post(
        contextServiceURL+"/api/remediate",
        "application/json",
        bytes.NewBuffer(mustMarshal(payload)),
    )
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var result RemediationResponse
    json.NewDecoder(resp.Body).Decode(&result)
    return &result, nil
}

// SubmitFeedback sends feedback with optional debate contributions
func SubmitFeedback(queryID string, rating int, helpful, notHelpful, used []string, contributions []DebateContribution) (*FeedbackResponse, error) {
    payload := map[string]interface{}{
        "query_id":           queryID,
        "overall_rating":     rating,
        "items_helpful":      helpful,
        "items_not_helpful":  notHelpful,
        "items_used":         used,
        "debate_contributions": contributions,
        "agent_id":           "echo-api",
    }

    resp, err := http.Post(
        contextServiceURL+"/api/feedback",
        "application/json",
        bytes.NewBuffer(mustMarshal(payload)),
    )
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var result FeedbackResponse
    json.NewDecoder(resp.Body).Decode(&result)
    return &result, nil
}

// GetDebate retrieves debate for a specific resource
func GetDebate(resourceID, resourceType string) (map[string]interface{}, error) {
    resp, err := http.Get(fmt.Sprintf("%s/api/debate/by-resource?resource_id=%s&resource_type=%s",
        contextServiceURL, resourceID, resourceType))
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var result map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&result)
    return result, nil
}

func mustMarshal(v interface{}) []byte {
    b, _ := json.Marshal(v)
    return b
}

// Echo middleware: query context and check for known issues before handling requests
func ContextMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
    return func(c echo.Context) error {
        ctx, _ := QueryContext("known issues "+c.Path(), false)
        if ctx != nil && len(ctx.KnownIssues) > 0 {
            c.Logger().Warnf("Known issues for %s: %v", c.Path(), ctx.KnownIssues[0]["title"])
        }
        return next(c)
    }
}

// Error handling with auto-remediation
func HandleError(c echo.Context, err error) {
    remediation, _ := FindRemediation(err.Error(), "")
    if remediation != nil && len(remediation.Incidents) > 0 {
        incident := remediation.Incidents[0]
        c.Logger().Errorf("Error: %s. Known issue: %s. Resolution: %s",
            err.Error(), incident.Title, incident.Resolution)
    }
}

// Complete workflow example: query -> use -> feedback -> debate
func ExampleWorkflow(c echo.Context) error {
    // 1. Query for context
    ctx, _ := QueryContext("database connection pooling", true)
    if ctx == nil {
        return c.JSON(500, map[string]string{"error": "context service unavailable"})
    }

    // 2. Use context to complete work...
    for _, adr := range ctx.KeyDecisions {
        c.Logger().Infof("ADR: %s - %s", adr["id"], adr["title"])
        if debate, ok := adr["debate"].(map[string]interface{}); ok && debate != nil {
            c.Logger().Infof("  Debate status: %s, messages: %v", debate["status"], debate["message_count"])
        }
    }

    // 3. Submit feedback with debate contribution
    helpful := []string{}
    used := []string{}
    contributions := []DebateContribution{}

    for _, adr := range ctx.KeyDecisions {
        helpful = append(helpful, adr["id"].(string))
        used = append(used, adr["id"].(string))

        // Optionally contribute to debate
        contributions = append(contributions, DebateContribution{
            ResourceID: adr["id"].(string),
            Stance:     "agree",
            Argument:   "This ADR was directly applicable to the database optimization task.",
        })
    }

    feedback, _ := SubmitFeedback(ctx.QueryID, 5, helpful, nil, used, contributions)
    c.Logger().Infof("Feedback submitted, debates processed: %d", len(feedback.DebatesProcessed))

    return c.JSON(200, map[string]interface{}{
        "query_id":     ctx.QueryID,
        "items_used":   used,
        "debates_started": len(feedback.DebatesProcessed),
    })
}
```

## Python Integration

```python
import requests

CONTEXT_SERVICE_URL = "http://localhost:4000"

def query_context(question, max_tokens=3000, include_debates=False):
    payload = {'query': question, 'max_tokens': max_tokens}
    if include_debates:
        payload['include_debates'] = True
    resp = requests.post(f'{CONTEXT_SERVICE_URL}/api/context/query', json=payload)
    return resp.json() if resp.ok else None

def find_remediation(error_message, stack_trace=None):
    payload = {'error_message': error_message}
    if stack_trace:
        payload['stack_trace'] = stack_trace
    resp = requests.post(f'{CONTEXT_SERVICE_URL}/api/remediate', json=payload)
    return resp.json() if resp.ok else None

def submit_feedback(query_id, rating=None, helpful=None, not_helpful=None, 
                    used=None, contributions=None, agent_id="python-agent"):
    payload = {'query_id': query_id, 'agent_id': agent_id}
    if rating:
        payload['overall_rating'] = rating
    if helpful:
        payload['items_helpful'] = helpful
    if not_helpful:
        payload['items_not_helpful'] = not_helpful
    if used:
        payload['items_used'] = used
    if contributions:
        payload['debate_contributions'] = contributions
    resp = requests.post(f'{CONTEXT_SERVICE_URL}/api/feedback', json=payload)
    return resp.json() if resp.ok else None

def get_debate(resource_id, resource_type):
    resp = requests.get(f'{CONTEXT_SERVICE_URL}/api/debate/by-resource',
                       params={'resource_id': resource_id, 'resource_type': resource_type})
    return resp.json() if resp.ok else None

# Example workflow: query -> use -> feedback -> debate
def example_workflow():
    # 1. Query for context with debates included
    context = query_context("database connection pooling", include_debates=True)
    
    # 2. Use context
    helpful = []
    used = []
    contributions = []
    
    for adr in context.get('key_decisions', []):
        print(f"ADR: {adr['id']} - {adr['title']}")
        helpful.append(adr['id'])
        used.append(adr['id'])
        
        # Check for existing debate
        if adr.get('debate'):
            print(f"  Debate: {adr['debate']['status']}, {adr['debate']['message_count']} messages")
        
        # Contribute to debate
        contributions.append({
            'resource_id': adr['id'],
            'stance': 'agree',
            'argument': 'This ADR was directly applicable to the database optimization task.'
        })
    
    for fail in context.get('known_issues', []):
        print(f"Failure: {fail['id']} - {fail['title']}")
    
    # 3. Submit feedback with debate contributions
    feedback = submit_feedback(
        query_id=context['query_id'],
        rating=5,
        helpful=helpful,
        used=used,
        contributions=contributions
    )
    print(f"Feedback submitted, debates processed: {len(feedback.get('debates_processed', []))}")
    
    return feedback

# Error handling with auto-remediation
def handle_error(error):
    remediation = find_remediation(str(error))
    if remediation and remediation.get('similar_incidents'):
        incident = remediation['similar_incidents'][0]
        print(f"Known issue: {incident['title']}")
        print(f"Resolution: {incident['resolution']}")
        return incident
    return None

# Example: wrap error handling
try:
    # some operation
    pass
except Exception as e:
    handle_error(e)
```

## Node.js Integration

```javascript
const CONTEXT_SERVICE_URL = 'http://localhost:4000';

async function queryContext(question, options = {}) {
    const payload = {
        query: question,
        max_tokens: options.maxTokens || 3000,
        include_debates: options.includeDebates || false
    };
    
    const resp = await fetch(`${CONTEXT_SERVICE_URL}/api/context/query`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload)
    });
    return resp.json();
}

async function findRemediation(errorMessage, stackTrace = null) {
    const payload = { error_message: errorMessage };
    if (stackTrace) payload.stack_trace = stackTrace;
    
    const resp = await fetch(`${CONTEXT_SERVICE_URL}/api/remediate`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload)
    });
    return resp.json();
}

async function submitFeedback(queryId, options = {}) {
    const payload = {
        query_id: queryId,
        agent_id: options.agentId || 'nodejs-agent'
    };
    if (options.rating) payload.overall_rating = options.rating;
    if (options.helpful) payload.items_helpful = options.helpful;
    if (options.notHelpful) payload.items_not_helpful = options.notHelpful;
    if (options.used) payload.items_used = options.used;
    if (options.contributions) payload.debate_contributions = options.contributions;
    
    const resp = await fetch(`${CONTEXT_SERVICE_URL}/api/feedback`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload)
    });
    return resp.json();
}

async function getDebate(resourceId, resourceType) {
    const resp = await fetch(
        `${CONTEXT_SERVICE_URL}/api/debate/by-resource?resource_id=${resourceId}&resource_type=${resourceType}`
    );
    return resp.json();
}

// Example workflow: query -> use -> feedback -> debate
async function exampleWorkflow() {
    // 1. Query for context with debates
    const context = await queryContext('database connection pooling', { includeDebates: true });
    
    // 2. Use context
    const helpful = [];
    const used = [];
    const contributions = [];
    
    for (const adr of context.key_decisions || []) {
        console.log(`ADR: ${adr.id} - ${adr.title}`);
        helpful.push(adr.id);
        used.push(adr.id);
        
        if (adr.debate) {
            console.log(`  Debate: ${adr.debate.status}, ${adr.debate.message_count} messages`);
        }
        
        contributions.push({
            resource_id: adr.id,
            stance: 'agree',
            argument: 'This ADR was directly applicable to the database optimization task.'
        });
    }
    
    for (const fail of context.known_issues || []) {
        console.log(`Failure: ${fail.id} - ${fail.title}`);
    }
    
    // 3. Submit feedback with debate contributions
    const feedback = await submitFeedback(context.query_id, {
        rating: 5,
        helpful,
        used,
        contributions
    });
    
    console.log(`Feedback submitted, debates processed: ${feedback.debates_processed?.length || 0}`);
    return feedback;
}

// Error handling with auto-remediation
async function handleError(error) {
    const remediation = await findRemediation(error.message);
    if (remediation?.similar_incidents?.length > 0) {
        const incident = remediation.similar_incidents[0];
        console.log(`Known issue: ${incident.title}`);
        console.log(`Resolution: ${incident.resolution}`);
        return incident;
    }
    return null;
}

module.exports = {
    queryContext,
    findRemediation,
    submitFeedback,
    getDebate,
    exampleWorkflow,
    handleError
};
```

## Best Practices

1. **Query before you code** — check for existing decisions and known issues
2. **Use specific queries** — `"database connection pooling decisions"` not `"database"`
3. **Check multiple perspectives** — query both decisions and failures for the same topic
4. **Follow the graph** — if ADR-001 mentions FAIL-042, fetch that failure for full context
5. **Validate freshness** — check `created_date`; old decisions may be superseded

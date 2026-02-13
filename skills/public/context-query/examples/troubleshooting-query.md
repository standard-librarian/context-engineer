# Troubleshooting Query Examples

## Connection Errors

**Symptom:** Database connections timing out

```bash
curl -X POST http://localhost:4000/api/context/query \
  -d '{"query": "database connection timeout errors pool"}'
```

Expected: FAIL records with root causes like pool exhaustion, resolutions, and prevention steps.

## Performance Degradation

**Symptom:** API responses slowing down

```bash
curl -X POST http://localhost:4000/api/context/query \
  -d '{"query": "performance slow API latency"}'
```

Expected: Past performance incidents, what caused them, how they were resolved.

## Go/Echo Specific

**Symptom:** Goroutine leak in Echo handler

```bash
curl -X POST http://localhost:4000/api/context/query \
  -d '{"query": "goroutine leak memory panic"}'
```

Expected: Runtime panic failures, resource exhaustion patterns, prevention measures.

## Pattern Search

If you know the failure pattern, query the failure list directly:

```bash
# All connection errors
curl http://localhost:4000/api/failure?status=resolved

# Then search semantically for specifics
curl -X POST http://localhost:4000/api/context/query \
  -d '{"query": "connection_error pattern resolution"}'
```

## Cross-Referencing

When a failure references an ADR:

```bash
# 1. Find the failure
curl http://localhost:4000/api/failure/FAIL-042

# 2. Check graph for related items
curl "http://localhost:4000/api/graph/related/FAIL-042?type=failure&depth=2"

# 3. Fetch the related ADR
curl http://localhost:4000/api/adr/ADR-001
```

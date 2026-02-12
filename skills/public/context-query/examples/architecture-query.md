# Architecture Query Examples

## Database Choice

**Question:** "Why did we choose PostgreSQL?"

```bash
curl -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database choice PostgreSQL why"}'
```

Expected: ADR-001 with decision rationale, consistency requirements, team expertise factors.

## Caching Strategy

**Question:** "What's our caching approach?"

```bash
curl -X POST http://localhost:4000/api/context/query \
  -d '{"query": "caching strategy Redis"}'
```

Expected: ADR about Redis adoption, related failures (cache stampede), prevention strategies.

## API Design Decisions

**Question:** "How should API endpoints be structured?"

```bash
curl -X POST http://localhost:4000/api/context/query \
  -d '{"query": "API design REST endpoint structure"}'
```

Expected: ADRs about API conventions, related meeting decisions.

## Full Domain Overview

**Question:** "What do I need to know about authentication?"

```bash
curl -X POST http://localhost:4000/api/context/query \
  -d '{"query": "authentication security architecture", "domains": ["security", "authentication"]}'
```

Then follow up with the domain endpoint:

```bash
curl http://localhost:4000/api/context/domain/security
```

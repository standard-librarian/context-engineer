# Context Engineering - Quick Reference

## 🎯 Feedback and Debate Features

### Core Concepts

- **Feedback**: Rate context usefulness (1-5 stars, helpful items, missing context)
- **Debate**: Multi-agent discussion about resource quality
- **Judge**: Auto-evaluates after 3 debate messages → produces score + action

### Debate Lifecycle

```
Message 1 → open
Message 2 → open
Message 3 → JUDGE TRIGGERED → judged
```

### Judge Scores

- **5**: Excellent (≥80% agree)
- **4**: Good (≥60% agree)
- **3**: Mixed (≥40% agree)
- **2**: Poor (≥20% agree)
- **1**: Very poor (<20% agree)

### Actions

- **none**: Keep as-is (≥70% agree)
- **review**: Needs attention (40-70% agree)
- **update**: Needs fixes (<40% agree)
- **deprecate**: Should be removed

## 📋 Quick Commands

### Query with Debates
```bash
curl -X POST http://localhost:4000/api/context/query \
  -H 'Content-Type: application/json' \
  -d '{"query": "database", "include_debates": true}'
```

### Submit Feedback + Debate
```bash
curl -X POST http://localhost:4000/api/feedback \
  -H 'Content-Type: application/json' \
  -d '{
    "query_text": "database decisions",
    "overall_rating": 4,
    "items_helpful": ["ADR-001"],
    "agent_id": "my-agent",
    "debate_contributions": [{
      "resource_id": "ADR-001",
      "resource_type": "adr",
      "stance": "disagree",
      "argument": "This is outdated because..."
    }]
  }'
```

### Get Debate Details
```bash
curl 'http://localhost:4000/api/debate/by-resource?resource_id=ADR-001&resource_type=adr'
```

### Get Feedback Stats
```bash
curl http://localhost:4000/api/feedback/stats?days_back=30
```

### List Pending Judgments
```bash
curl http://localhost:4000/api/debate/pending-judgment
```

## 🧪 Test Data

Run: `mix run priv/repo/seeds_with_debates.exs`

Creates:
- **ADR-001**: PostgreSQL (judged outdated, score: 1/5)
- **ADR-002**: pkg/errors (judged outdated, score: 1/5)
- **ADR-003**: Echo (2 messages, awaiting 3rd)
- **ADR-004**: Redis (1 question)
- **FAIL-002**: Cache Miss (incomplete resolution)

## 🤖 AI Agent Guidelines

### When Querying
```
Always: include_debates: true
Check: debate.judgment.score
If score < 3: Warn user about low confidence
```

### After Providing Answer
```
Ask: "Was this helpful?"
Submit feedback:
  - overall_rating (1-5)
  - items_helpful (what worked)
  - missing_context (what's needed)
```

### When Noticing Issues
```
Submit debate_contribution:
  - stance: "disagree" if wrong
  - stance: "question" if unclear
  - stance: "agree" if correct
  - argument: Specific, actionable feedback
```

## 📊 Stance Guide

- **agree**: Resource is accurate
- **disagree**: Resource has problems
- **neutral**: Observations only
- **question**: Need clarification

## 🎓 Examples

### Good Debate Arguments

✅ **Specific:**
```
"ADR-001 recommends PostgreSQL but go.mod shows mongodb-driver. 
Team migrated in Q4 2024. Should be superseded by ADR-005."
```

✅ **Evidence-based:**
```
"Current codebase (handlers/user.go:42) uses stdlib fmt.Errorf, 
not pkg/errors. This ADR is outdated."
```

❌ **Bad:**
```
"This is wrong"  # No details
"I prefer MongoDB"  # Opinion without evidence
```

## 📖 Full Documentation

- **Test Guide**: `examples/go-echo-app/FEEDBACK_DEBATE_TEST_GUIDE.md`
- **AI Integration**: `examples/go-echo-app/.cursorrules`
- **Test Script**: `test_debate_features.sh`
- **Seed Data**: `priv/repo/seeds_with_debates.exs`

## 🚀 Quick Start

```bash
# 1. Seed database
mix run priv/repo/seeds_with_debates.exs

# 2. Start server
mix phx.server

# 3. Test
./test_debate_features.sh

# 4. Try manual queries
curl -X POST http://localhost:4000/api/context/query \
  -H 'Content-Type: application/json' \
  -d '{"query": "database", "include_debates": true}' | jq .
```

Done! 🎉

#!/bin/bash

# Test script for Feedback and Debate features
# Run after: mix run priv/repo/seeds_with_debates.exs

API="http://localhost:4000/api"

echo "🧪 Testing Feedback and Debate Features"
echo "========================================"
echo ""

# Test 1: Query with debates
echo "1️⃣  Query database decisions (with debates)"
echo "-------------------------------------------"
curl -s -X POST "$API/context/query" \
  -H 'Content-Type: application/json' \
  -d '{"query": "database decisions", "include_debates": true}' | \
  jq '.key_decisions[] | {id, title, debate: {status: .debate.status, score: .debate.judgment.score, action: .debate.judgment.suggested_action}}'
echo ""

# Test 2: Get specific debate
echo "2️⃣  Get debate for ADR-001"
echo "-------------------------------------------"
curl -s "$API/debate/by-resource?resource_id=ADR-001&resource_type=adr" | \
  jq '{resource_id, status, message_count}'
echo ""

# Test 3: Submit feedback with debate contribution (add 3rd message to ADR-003)
echo "3️⃣  Add 3rd debate message to ADR-003 (should trigger judge)"
echo "-------------------------------------------"
RESPONSE=$(curl -s -X POST "$API/feedback" \
  -H 'Content-Type: application/json' \
  -d '{
    "query_text": "echo framework decision",
    "overall_rating": 5,
    "items_helpful": ["ADR-003"],
    "items_used": ["ADR-003"],
    "agent_id": "test-script",
    "debate_contributions": [{
      "resource_id": "ADR-003",
      "resource_type": "adr",
      "stance": "agree",
      "argument": "Third confirmation: Echo v4 is working excellently. All team members report high productivity. No issues found in production."
    }]
  }')
echo "$RESPONSE" | jq '{feedback_id: .id, debates_processed}'
echo ""

# Wait for judge to process
echo "⏳ Waiting 2 seconds for judge to process..."
sleep 2
echo ""

# Test 4: Check if ADR-003 debate was judged
echo "4️⃣  Check ADR-003 debate status (should be judged now)"
echo "-------------------------------------------"
curl -s "$API/debate/by-resource?resource_id=ADR-003&resource_type=adr" | \
  jq '{resource_id, status, message_count}'
echo ""

# Test 5: Query ADR-003 with debate info
echo "5️⃣  Query Echo framework (should show positive debate)"
echo "-------------------------------------------"
curl -s -X POST "$API/context/query" \
  -H 'Content-Type: application/json' \
  -d '{"query": "echo framework REST API", "include_debates": true}' | \
  jq '.key_decisions[] | select(.id == "ADR-003") | {id, title, debate: {status: .debate.status, score: .debate.judgment.score, action: .debate.judgment.suggested_action}}'
echo ""

# Test 6: Get feedback stats
echo "6️⃣  Get feedback statistics"
echo "-------------------------------------------"
curl -s "$API/feedback/stats?days_back=30" | \
  jq '{total_feedback, avg_rating, most_helpful_items: .most_helpful_items[0:3]}'
echo ""

# Test 7: List all debates
echo "7️⃣  List all debates"
echo "-------------------------------------------"
curl -s "$API/debate" | \
  jq '.[] | {resource_id, status, message_count}'
echo ""

# Test 8: Add message to FAIL-002 (incomplete resolution)
echo "8️⃣  Add 2nd message to FAIL-002 debate"
echo "-------------------------------------------"
curl -s -X POST "$API/feedback" \
  -H 'Content-Type: application/json' \
  -d '{
    "query_text": "redis cache miss issues",
    "overall_rating": 2,
    "items_helpful": [],
    "items_not_helpful": ["FAIL-002"],
    "agent_id": "test-script-2",
    "debate_contributions": [{
      "resource_id": "FAIL-002",
      "resource_type": "failure",
      "stance": "disagree",
      "argument": "This resolution is too vague. What specific deployment changes were made? Need concrete steps like: graceful cache warmup, staggered deployments, or cache persistence configuration."
    }]
  }' | jq '{feedback_id: .id, debates_processed}'
echo ""

# Test 9: Check pending judgments
echo "9️⃣  List debates pending judgment"
echo "-------------------------------------------"
curl -s "$API/debate/pending-judgment" | \
  jq '.[] | {resource_id, message_count, needs: "One more message to trigger judge"}'
echo ""

# Test 10: Query with debate context
echo "🔟 Query error handling (should show ADR-002 outdated)"
echo "-------------------------------------------"
curl -s -X POST "$API/context/query" \
  -H 'Content-Type: application/json' \
  -d '{"query": "golang error handling", "include_debates": true}' | \
  jq '.key_decisions[] | select(.id == "ADR-002") | {id, title, debate: {status: .debate.status, score: .debate.judgment.score, summary: .debate.judgment.summary}}'
echo ""

echo "✅ All tests complete!"
echo ""
echo "📊 Summary of Debate Statuses:"
curl -s "$API/debate" | jq -r '.[] | "\(.resource_id): \(.status) (\(.message_count) messages)"'

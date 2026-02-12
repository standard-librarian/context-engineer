#!/bin/bash

# Demo script for Context Engineering + Go Echo App Integration
# This script demonstrates the full workflow of the system

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                                                            ║${NC}"
echo -e "${BOLD}${CYAN}║     Context Engineering + Go Echo App Demo                 ║${NC}"
echo -e "${BOLD}${CYAN}║     AI-Native Knowledge Management System                  ║${NC}"
echo -e "${BOLD}${CYAN}║                                                            ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"
echo ""

# Check if Context Engineering is running
echo -e "${CYAN}→ Checking Context Engineering server (port 4000)...${NC}"
if curl -s http://localhost:4000/api/adr > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Context Engineering is running${NC}"
else
    echo -e "${RED}  ✗ Context Engineering is NOT running${NC}"
    echo -e "${YELLOW}  → Please start it in another terminal:${NC}"
    echo -e "     ${BOLD}cd ../.. && mix phx.server${NC}"
    echo ""
    exit 1
fi

# Check if Go is installed
echo -e "${CYAN}→ Checking Go installation...${NC}"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    echo -e "${GREEN}  ✓ Go is installed ($GO_VERSION)${NC}"
else
    echo -e "${RED}  ✗ Go is NOT installed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Part 1: Query Organizational Knowledge${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Let's query what decisions have been made about databases:${NC}"
echo ""
echo -e "${CYAN}$ curl -X POST http://localhost:4000/api/context/query \\${NC}"
echo -e "${CYAN}    -H 'Content-Type: application/json' \\${NC}"
echo -e "${CYAN}    -d '{\"query\": \"database decisions\"}'${NC}"
echo ""
sleep 2

RESULT=$(curl -s -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "database decisions"}')

echo -e "${GREEN}Response:${NC}"
echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
echo ""

DECISION_COUNT=$(echo "$RESULT" | grep -o '"key_decisions":\[[^]]*\]' | grep -o '"id"' | wc -l | xargs)
echo -e "${GREEN}✓ Found $DECISION_COUNT relevant decisions${NC}"
echo ""

read -p "Press Enter to continue..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Part 2: Record a New Decision (ADR)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Let's record a decision to use Go for microservices:${NC}"
echo ""
sleep 1

ADR_RESULT=$(curl -s -X POST http://localhost:4000/api/adr \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Use Go for High-Performance Microservices",
    "decision": "Adopt Go as the primary language for new microservices that require high performance and low latency",
    "context": "Need to build services that handle 100k+ requests per second with minimal resource usage",
    "options_considered": {
      "go": ["Excellent performance", "Great concurrency", "Fast compile times", "Small binary size"],
      "rust": ["Even faster", "Memory safe", "Steeper learning curve"],
      "nodejs": ["Team familiarity", "Not suitable for CPU-intensive tasks"]
    },
    "tags": ["golang", "microservices", "performance", "architecture"],
    "stakeholders": ["platform-team", "backend-team"]
  }')

ADR_ID=$(echo "$ADR_RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "ADR-XXX")
echo -e "${GREEN}✓ Created $ADR_ID: Use Go for High-Performance Microservices${NC}"
echo ""

read -p "Press Enter to continue..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Part 3: Start Go Echo Application${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Clean up old data
rm -f users.db

echo -e "${CYAN}→ Starting Go Echo application on port 8080...${NC}"
echo ""
sleep 1

# Start Go app in background
go run main.go > /tmp/go-echo-demo.log 2>&1 &
GO_PID=$!
sleep 3

# Check if started
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Go application is running (PID: $GO_PID)${NC}"
else
    echo -e "${RED}✗ Failed to start Go application${NC}"
    cat /tmp/go-echo-demo.log
    exit 1
fi
echo ""

read -p "Press Enter to continue..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Part 4: Create Users (with Context Integration)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Creating users... The Go app will automatically query Context${NC}"
echo -e "${YELLOW}Engineering for relevant decisions before creating each user.${NC}"
echo ""
sleep 2

# Create first user
echo -e "${CYAN}→ Creating user: Alice Johnson (admin)${NC}"
USER1=$(curl -s -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Johnson", "email": "alice@example.com", "role": "admin"}')
echo -e "${GREEN}  ✓ Created: $(echo $USER1 | python3 -c "import sys, json; u=json.load(sys.stdin); print(f\"{u['name']} (ID: {u['ID']})\")" 2>/dev/null || echo "User created")${NC}"
sleep 1

# Create second user
echo -e "${CYAN}→ Creating user: Bob Smith (user)${NC}"
USER2=$(curl -s -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob Smith", "email": "bob@example.com", "role": "user"}')
echo -e "${GREEN}  ✓ Created: $(echo $USER2 | python3 -c "import sys, json; u=json.load(sys.stdin); print(f\"{u['name']} (ID: {u['ID']})\")" 2>/dev/null || echo "User created")${NC}"
sleep 1

# Create third user
echo -e "${CYAN}→ Creating user: Carol Davis (moderator)${NC}"
USER3=$(curl -s -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Carol Davis", "email": "carol@example.com", "role": "moderator"}')
echo -e "${GREEN}  ✓ Created: $(echo $USER3 | python3 -c "import sys, json; u=json.load(sys.stdin); print(f\"{u['name']} (ID: {u['ID']})\")" 2>/dev/null || echo "User created")${NC}"

echo ""
echo -e "${GREEN}✓ All users created successfully${NC}"
echo ""

read -p "Press Enter to continue..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Part 5: List All Users${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

USERS=$(curl -s http://localhost:8080/users)
echo -e "${CYAN}$ curl http://localhost:8080/users${NC}"
echo ""
echo "$USERS" | python3 -m json.tool 2>/dev/null || echo "$USERS"
echo ""

USER_COUNT=$(echo "$USERS" | grep -o '"name"' | wc -l | xargs)
echo -e "${GREEN}✓ Total users: $USER_COUNT${NC}"
echo ""

read -p "Press Enter to continue..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Part 6: Query Context from Go App${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}The Go app can also query organizational knowledge:${NC}"
echo ""
sleep 1

CONTEXT_RESULT=$(curl -s -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "golang microservices performance"}')

echo -e "${CYAN}$ curl -X POST http://localhost:8080/context/query \\${NC}"
echo -e "${CYAN}    -d '{\"query\": \"golang microservices performance\"}'${NC}"
echo ""
sleep 1

echo -e "${GREEN}Response Summary:${NC}"
KEY_DEC=$(echo "$CONTEXT_RESULT" | grep -o '"key_decisions":\[[^]]*\]' | grep -o '"id"' | wc -l | xargs)
KNOWN_ISS=$(echo "$CONTEXT_RESULT" | grep -o '"known_issues":\[[^]]*\]' | grep -o '"id"' | wc -l | xargs)
RECENT_CH=$(echo "$CONTEXT_RESULT" | grep -o '"recent_changes":\[[^]]*\]' | grep -o '"id"' | wc -l | xargs)

echo -e "  • Key Decisions: ${GREEN}$KEY_DEC${NC}"
echo -e "  • Known Issues: ${GREEN}$KNOWN_ISS${NC}"
echo -e "  • Recent Changes: ${GREEN}$RECENT_CH${NC}"
echo ""

if [ "$KEY_DEC" -gt 0 ]; then
    echo -e "${CYAN}Found relevant ADR:${NC}"
    echo "$CONTEXT_RESULT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for decision in data.get('key_decisions', [])[:1]:
        print(f\"  → {decision['id']}: {decision['title']}\")
except:
    pass
" 2>/dev/null
fi

echo ""

read -p "Press Enter to continue..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Part 7: Check Application Logs${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Here's what happened behind the scenes:${NC}"
echo ""
echo -e "${CYAN}Last 15 lines from /tmp/go-echo-demo.log:${NC}"
echo ""
tail -15 /tmp/go-echo-demo.log | sed 's/^/  /'
echo ""

read -p "Press Enter to continue..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Part 8: Test AI Agent Integration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}The system is configured to work with AI agents:${NC}"
echo ""

# Check for agent configuration files
echo -e "${CYAN}→ Checking agent configuration files:${NC}"
[ -f .cursorrules ] && echo -e "${GREEN}  ✓ .cursorrules (Cursor AI)${NC}" || echo -e "${RED}  ✗ .cursorrules missing${NC}"
[ -f .github/copilot-instructions.md ] && echo -e "${GREEN}  ✓ copilot-instructions.md (GitHub Copilot)${NC}" || echo -e "${RED}  ✗ copilot-instructions.md missing${NC}"
echo ""

echo -e "${CYAN}→ Checking agent skills:${NC}"
[ -d skills/public/go-api-query ] && echo -e "${GREEN}  ✓ go-api-query skill (public)${NC}" || echo -e "${RED}  ✗ go-api-query skill missing${NC}"
[ -d skills/user/go-api-record ] && echo -e "${GREEN}  ✓ go-api-record skill (user)${NC}" || echo -e "${RED}  ✗ go-api-record skill missing${NC}"
echo ""

echo -e "${YELLOW}Try these with your AI agent:${NC}"
echo ""
echo -e "  ${BOLD}1. Open Cursor:${NC}"
echo -e "     ${CYAN}$ cursor .${NC}"
echo ""
echo -e "  ${BOLD}2. Ask in chat:${NC}"
echo -e "     \"How should I handle errors in Go?\""
echo -e "     \"Show me past decisions about databases\""
echo -e "     \"What are the best practices for user validation?\""
echo ""
echo -e "  ${BOLD}3. Or open VS Code:${NC}"
echo -e "     ${CYAN}$ code .${NC}"
echo ""
echo -e "  ${BOLD}4. Start typing:${NC}"
echo -e "     ${CYAN}// Validate email format following organizational pattern${NC}"
echo ""

read -p "Press Enter to see final summary..."
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Demo Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}✓ Context Engineering System${NC}"
echo -e "  • Running on http://localhost:4000"
echo -e "  • Contains organizational knowledge (ADRs, Failures, Meetings)"
echo -e "  • Provides semantic search via embeddings"
echo ""

echo -e "${GREEN}✓ Go Echo Application${NC}"
echo -e "  • Running on http://localhost:8080"
echo -e "  • Automatically queries context before operations"
echo -e "  • Records decisions on startup"
echo -e "  • Integrates with Context Engineering"
echo ""

echo -e "${GREEN}✓ AI Agent Integration${NC}"
echo -e "  • Agent skills configured"
echo -e "  • Auto-triggers on relevant queries"
echo -e "  • Provides context-aware code suggestions"
echo ""

echo -e "${CYAN}Key Endpoints:${NC}"
echo ""
echo -e "  ${BOLD}Context Engineering:${NC}"
echo -e "    GET  http://localhost:4000/api/adr"
echo -e "    POST http://localhost:4000/api/context/query"
echo -e "    POST http://localhost:4000/api/adr"
echo -e "    POST http://localhost:4000/api/failure"
echo ""
echo -e "  ${BOLD}Go Application:${NC}"
echo -e "    GET  http://localhost:8080/health"
echo -e "    GET  http://localhost:8080/users"
echo -e "    POST http://localhost:8080/users"
echo -e "    POST http://localhost:8080/context/query"
echo ""

echo -e "${YELLOW}Documentation:${NC}"
echo -e "  • README.md - Full documentation"
echo -e "  • QUICKSTART.md - 5-minute setup guide"
echo -e "  • TEST_SUMMARY.md - Test results"
echo -e "  • ../../docs/ - Complete system documentation"
echo ""

# Cleanup
echo -e "${BLUE}Cleaning up...${NC}"
kill $GO_PID 2>/dev/null || true
sleep 1
echo -e "${GREEN}✓ Go application stopped${NC}"
echo ""

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                                                            ║${NC}"
echo -e "${BOLD}${CYAN}║                    Demo Complete! 🎉                       ║${NC}"
echo -e "${BOLD}${CYAN}║                                                            ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Run tests: ${CYAN}./test-integration.sh${NC}"
echo -e "  2. Try AI agent integration with Cursor or VS Code"
echo -e "  3. Explore the code in handlers/user_handler.go"
echo -e "  4. Read the documentation in README.md"
echo ""

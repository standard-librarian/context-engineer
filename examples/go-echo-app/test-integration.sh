#!/bin/bash
set -e

echo "🧪 Testing Context Engineering + Go Integration"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Cleanup function
cleanup() {
    echo ""
    echo -e "${BLUE}Cleaning up...${NC}"
    if [ ! -z "$GO_PID" ]; then
        kill $GO_PID 2>/dev/null || true
    fi
    rm -f users.db
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

trap cleanup EXIT

# 1. Check Context Engineering is running
echo -e "${BLUE}1. Checking Context Engineering server...${NC}"
if curl -s http://localhost:4000/api/adr > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Context Engineering is running${NC}"
else
    echo -e "${RED}❌ Context Engineering not running${NC}"
    echo "   Start with: cd ../.. && mix phx.server"
    exit 1
fi
echo ""

# 2. Install Go dependencies
echo -e "${BLUE}2. Installing Go dependencies...${NC}"
if go mod tidy; then
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi
echo ""

# 3. Start Go app in background
echo -e "${BLUE}3. Starting Go application...${NC}"
go run main.go > /tmp/go-echo-app.log 2>&1 &
GO_PID=$!
sleep 3

# Check if app started successfully
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Go app is running (PID: $GO_PID)${NC}"
else
    echo -e "${RED}❌ Go app failed to start${NC}"
    echo "   Check logs: tail /tmp/go-echo-app.log"
    cat /tmp/go-echo-app.log
    exit 1
fi
echo ""

# 4. Test health endpoint
echo -e "${BLUE}4. Testing health endpoint...${NC}"
HEALTH=$(curl -s http://localhost:8080/health)
if echo "$HEALTH" | grep -q "ok"; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    echo "   Response: $HEALTH"
else
    echo -e "${RED}❌ Health check failed${NC}"
    echo "   Response: $HEALTH"
fi
echo ""

# 5. Test context query from Go app
echo -e "${BLUE}5. Testing context query from Go app...${NC}"
QUERY_RESULT=$(curl -s -X POST http://localhost:8080/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "user management"}')

if echo "$QUERY_RESULT" | grep -q "key_decisions"; then
    echo -e "${GREEN}✓ Context query working${NC}"
    echo "   Total items: $(echo "$QUERY_RESULT" | grep -o '"total_items":[0-9]*' | cut -d: -f2)"
else
    echo -e "${YELLOW}⚠️  Context query returned unexpected format${NC}"
    echo "   Response: $QUERY_RESULT"
fi
echo ""

# 6. Create user (triggers context query)
echo -e "${BLUE}6. Creating user (should trigger context query)...${NC}"
echo "   Watch the Go app logs for: 📚 Context check"
USER_RESULT=$(curl -s -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Integration Test User", "email": "test@example.com", "role": "admin"}')

if echo "$USER_RESULT" | grep -q "Integration Test User"; then
    echo -e "${GREEN}✓ User created successfully${NC}"
    USER_ID=$(echo "$USER_RESULT" | grep -o '"ID":[0-9]*' | cut -d: -f2)
    echo "   User ID: $USER_ID"
else
    echo -e "${RED}❌ User creation failed${NC}"
    echo "   Response: $USER_RESULT"
fi
echo ""

# 7. Get user
echo -e "${BLUE}7. Testing GET user...${NC}"
if [ ! -z "$USER_ID" ]; then
    GET_RESULT=$(curl -s http://localhost:8080/users/$USER_ID)
    if echo "$GET_RESULT" | grep -q "test@example.com"; then
        echo -e "${GREEN}✓ User retrieved successfully${NC}"
    else
        echo -e "${RED}❌ Failed to retrieve user${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping (no user ID)${NC}"
fi
echo ""

# 8. List users
echo -e "${BLUE}8. Testing list users...${NC}"
LIST_RESULT=$(curl -s http://localhost:8080/users)
if echo "$LIST_RESULT" | grep -q "Integration Test User"; then
    USER_COUNT=$(echo "$LIST_RESULT" | grep -o '"ID":[0-9]*' | wc -l)
    echo -e "${GREEN}✓ Users listed successfully${NC}"
    echo "   Total users: $USER_COUNT"
else
    echo -e "${YELLOW}⚠️  User list may be empty${NC}"
fi
echo ""

# 9. Verify ADR was created on startup
echo -e "${BLUE}9. Checking if startup ADR was recorded...${NC}"
ADR_LIST=$(curl -s http://localhost:4000/api/adr)
if echo "$ADR_LIST" | grep -q "Echo Framework"; then
    echo -e "${GREEN}✓ ADR recorded on startup${NC}"
    ADR_COUNT=$(echo "$ADR_LIST" | grep -o '"id":"ADR-[0-9]*"' | wc -l)
    echo "   Total ADRs: $ADR_COUNT"
else
    echo -e "${YELLOW}⚠️  Startup ADR not found (may already exist)${NC}"
fi
echo ""

# 10. Test skills files exist
echo -e "${BLUE}10. Verifying skills files...${NC}"
if [ -f "skills/public/go-api-query/SKILL.md" ]; then
    echo -e "${GREEN}✓ go-api-query skill exists${NC}"
else
    echo -e "${RED}❌ go-api-query skill missing${NC}"
fi

if [ -f "skills/user/go-api-record/SKILL.md" ]; then
    echo -e "${GREEN}✓ go-api-record skill exists${NC}"
else
    echo -e "${RED}❌ go-api-record skill missing${NC}"
fi
echo ""

# 11. Test agent configuration files
echo -e "${BLUE}11. Verifying agent configuration files...${NC}"
if [ -f ".cursorrules" ]; then
    echo -e "${GREEN}✓ .cursorrules exists (Cursor AI)${NC}"
else
    echo -e "${YELLOW}⚠️  .cursorrules missing${NC}"
fi

if [ -f ".github/copilot-instructions.md" ]; then
    echo -e "${GREEN}✓ copilot-instructions.md exists (GitHub Copilot)${NC}"
else
    echo -e "${YELLOW}⚠️  copilot-instructions.md missing${NC}"
fi
echo ""

# 12. Test direct Context Engineering API
echo -e "${BLUE}12. Testing direct Context Engineering API...${NC}"
DIRECT_QUERY=$(curl -s -X POST http://localhost:4000/api/context/query \
  -H "Content-Type: application/json" \
  -d '{"query": "golang error handling"}')

if echo "$DIRECT_QUERY" | grep -q "key_decisions"; then
    echo -e "${GREEN}✓ Direct API query working${NC}"
else
    echo -e "${YELLOW}⚠️  Direct API query returned unexpected format${NC}"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Integration Test Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps to test AI agent integration:"
echo ""
echo "1. Open this directory in Cursor:"
echo "   $ cursor ."
echo ""
echo "2. Ask Cursor: 'How should I validate email addresses?'"
echo "   → Cursor should query Context Engineering automatically"
echo ""
echo "3. Or open in VS Code with GitHub Copilot:"
echo "   $ code ."
echo ""
echo "4. Type in a .go file: // Validate email format"
echo "   → Copilot should suggest code based on organizational patterns"
echo ""
echo "5. Check server logs for context queries:"
echo "   $ tail /tmp/go-echo-app.log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

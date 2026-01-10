#!/bin/bash
# Quick validation script - fast checks without long operations

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$REPO_ROOT/bin"

PASSED=0
FAILED=0

test_pass() {
    PASSED=$((PASSED + 1))
    echo -e "${GREEN}✅${NC} $1"
}

test_fail() {
    FAILED=$((FAILED + 1))
    echo -e "${RED}❌${NC} $1"
}

echo -e "${BLUE}🔍 Quick Validation${NC}"
echo "=================="
echo ""

# Check executability
echo "Checking executability..."
for script in "$BIN_DIR"/*.sh "$BIN_DIR"/*.py; do
    [ -f "$script" ] && [ -x "$script" ] && test_pass "$(basename "$script") executable" || test_fail "$(basename "$script") not executable"
done

# Check syntax
echo ""
echo "Checking syntax..."
for script in "$BIN_DIR"/*.sh; do
    [ -f "$script" ] && bash -n "$script" 2>/dev/null && test_pass "$(basename "$script") syntax OK" || test_fail "$(basename "$script") syntax error"
done

for script in "$BIN_DIR"/*.py; do
    [ -f "$script" ] && python3 -m py_compile "$script" 2>/dev/null && test_pass "$(basename "$script") syntax OK" || test_fail "$(basename "$script") syntax error"
done

# Check help output (quick)
echo ""
echo "Checking help output..."
output=$("$BIN_DIR/restore_chat_history.sh" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | head -3)
echo "$output" | grep -qi "Migration\|Usage" && test_pass "restore_chat_history.sh help" || test_fail "restore_chat_history.sh help"

output=$("$BIN_DIR/emergency_recovery.sh" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | head -3)
echo "$output" | grep -qi "EMERGENCY\|RECOVERY" && test_pass "emergency_recovery.sh help" || test_fail "emergency_recovery.sh help"

# Check dependencies
echo ""
echo "Checking dependencies..."
command -v bash >/dev/null && test_pass "bash available" || test_fail "bash missing"
command -v python3 >/dev/null && test_pass "python3 available" || test_fail "python3 missing"
command -v sqlite3 >/dev/null && test_pass "sqlite3 available" || test_fail "sqlite3 missing"

# Check documentation
echo ""
echo "Checking documentation..."
[ -f "$REPO_ROOT/README.md" ] && test_pass "README.md exists" || test_fail "README.md missing"
[ -f "$REPO_ROOT/LICENSE" ] && test_pass "LICENSE exists" || test_fail "LICENSE missing"
[ -f "$REPO_ROOT/CONTRIBUTING.md" ] && test_pass "CONTRIBUTING.md exists" || test_fail "CONTRIBUTING.md missing"

# Check for hardcoded paths
echo ""
echo "Checking for hardcoded paths..."
found_hardcoded=false
for script in "$BIN_DIR"/*.sh "$BIN_DIR"/*.py; do
    if [ -f "$script" ] && grep -qE "/Users/[^/]+/(QuickCal|CalEvent)" "$script" 2>/dev/null; then
        test_fail "$(basename "$script") has hardcoded paths"
        found_hardcoded=true
    fi
done
[ "$found_hardcoded" = false ] && test_pass "No hardcoded user paths found"

# Summary
echo ""
echo -e "${BLUE}📊 Summary${NC}"
echo "=========="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total:  $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All quick checks passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some checks failed. Run full test suite for details.${NC}"
    exit 1
fi

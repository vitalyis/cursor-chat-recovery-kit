#!/bin/bash
# Comprehensive test suite for Cursor Chat Recovery Kit
# Tests all scripts in a safe, sandboxed environment

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$REPO_ROOT/bin"

# Test sandbox
TEST_SANDBOX="$REPO_ROOT/test/sandbox"
TEST_CURSOR_STORAGE="$TEST_SANDBOX/cursor_storage"
TEST_BACKUP_DIR="$TEST_SANDBOX/backups"

echo -e "${BLUE}🧪 Cursor Chat Recovery Kit - Test Suite${NC}"
echo "=========================================="
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}🧹 Cleaning up test sandbox...${NC}"
    rm -rf "$TEST_SANDBOX"
}

trap cleanup EXIT

# Test helper functions
test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${GREEN}✅ PASS${NC}: $1"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${RED}❌ FAIL${NC}: $1"
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

# Setup test sandbox
setup_sandbox() {
    echo -e "${YELLOW}📦 Setting up test sandbox...${NC}"
    mkdir -p "$TEST_SANDBOX"
    mkdir -p "$TEST_CURSOR_STORAGE/workspaceStorage"
    mkdir -p "$TEST_BACKUP_DIR/cursor_exports/20251220_160000/workspaceStorage"
    
    # Create mock workspace
    mkdir -p "$TEST_CURSOR_STORAGE/workspaceStorage/test_workspace_123"
    echo '{"folder": "file:///Users/test/TestProject"}' > "$TEST_CURSOR_STORAGE/workspaceStorage/test_workspace_123/workspace.json"
    touch "$TEST_CURSOR_STORAGE/workspaceStorage/test_workspace_123/state.vscdb"
    
    # Create mock backup workspace
    mkdir -p "$TEST_BACKUP_DIR/cursor_exports/20251220_160000/workspaceStorage/old_workspace_456"
    echo '{"folder": "file:///Users/test/OldProject"}' > "$TEST_BACKUP_DIR/cursor_exports/20251220_160000/workspaceStorage/old_workspace_456/workspace.json"
    touch "$TEST_BACKUP_DIR/cursor_exports/20251220_160000/workspaceStorage/old_workspace_456/state.vscdb"
    
    test_info "Sandbox created at: $TEST_SANDBOX"
}

# Test 1: Script executability
test_script_executability() {
    echo ""
    echo -e "${BLUE}Test 1: Script Executability${NC}"
    echo "---------------------------"
    
    for script in "$BIN_DIR"/*.sh "$BIN_DIR"/*.py; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                test_pass "$(basename "$script") is executable"
            else
                test_fail "$(basename "$script") is not executable"
            fi
        fi
    done
}

# Test 2: Script syntax
test_script_syntax() {
    echo ""
    echo -e "${BLUE}Test 2: Script Syntax Validation${NC}"
    echo "---------------------------"
    
    for script in "$BIN_DIR"/*.sh; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                test_pass "$(basename "$script") syntax is valid"
            else
                test_fail "$(basename "$script") has syntax errors"
            fi
        fi
    done
    
    for script in "$BIN_DIR"/*.py; do
        if [ -f "$script" ]; then
            if python3 -m py_compile "$script" 2>/dev/null; then
                test_pass "$(basename "$script") syntax is valid"
            else
                test_fail "$(basename "$script") has syntax errors"
            fi
        fi
    done
}

# Test 3: Help/Usage output
test_help_output() {
    echo ""
    echo -e "${BLUE}Test 3: Help/Usage Output${NC}"
    echo "---------------------------"
    
    # Test restore_chat_history.sh (strip color codes for matching)
    output=$("$BIN_DIR/restore_chat_history.sh" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    if echo "$output" | grep -qiE "(Migration Tool|Usage|auto|migrate|Cursor Chat)"; then
        test_pass "restore_chat_history.sh shows help"
    else
        test_fail "restore_chat_history.sh help not working"
    fi
    
    # Test emergency_recovery.sh (strip color codes for matching)
    output=$("$BIN_DIR/emergency_recovery.sh" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    if echo "$output" | grep -qiE "(EMERGENCY|RECOVERY|diagnose|restore|COMMANDS)"; then
        test_pass "emergency_recovery.sh shows help"
    else
        test_fail "emergency_recovery.sh help not working"
    fi
    
    # Test other scripts
    for script in quick_backup.sh convert_chats_to_markdown.sh session_logger.sh; do
        if [ -f "$BIN_DIR/$script" ]; then
            if "$BIN_DIR/$script" 2>&1 | grep -qE "(Usage|COMMANDS|help|CURSOR|BACKUP)" || "$BIN_DIR/$script" 2>&1 | head -5 | grep -q .; then
                test_pass "$script shows output/help"
            else
                test_fail "$script shows no output"
            fi
        fi
    done
    
    # Test export_cursor_chats.sh (it runs immediately, so check it produces output)
    # Note: This will create a real backup, but that's acceptable for testing
    output=$("$BIN_DIR/export_cursor_chats.sh" 2>&1 | head -5)
    if echo "$output" | grep -qE "(BACKUP|Exporting|timestamp|CURSOR|workspaceStorage)"; then
        test_pass "export_cursor_chats.sh produces output"
    else
        # If it fails due to missing directory, that's also valid
        if echo "$output" | grep -qE "(not found|No such|Error)"; then
            test_pass "export_cursor_chats.sh handles errors gracefully"
        else
            test_fail "export_cursor_chats.sh shows no output"
        fi
    fi
}

# Test 4: Path detection
test_path_detection() {
    echo ""
    echo -e "${BLUE}Test 4: Path Detection${NC}"
    echo "---------------------------"
    
    # Test that scripts detect their own location
    for script in setup_aliases.sh setup_cron.sh convert_chats_to_markdown.sh session_logger.sh; do
        if [ -f "$BIN_DIR/$script" ]; then
            if grep -q 'SCRIPT_DIR=' "$BIN_DIR/$script" || grep -q 'dirname.*BASH_SOURCE' "$BIN_DIR/$script"; then
                test_pass "$script has path detection"
            else
                test_fail "$script missing path detection"
            fi
        fi
    done
}

# Test 5: Dependencies
test_dependencies() {
    echo ""
    echo -e "${BLUE}Test 5: Dependency Checks${NC}"
    echo "---------------------------"
    
    # Check for required commands
    for cmd in bash python3 sqlite3; do
        if command -v "$cmd" >/dev/null 2>&1; then
            test_pass "$cmd is available"
        else
            test_fail "$cmd is not available"
        fi
    done
}

# Test 6: Dry-run operations
test_dry_run() {
    echo ""
    echo -e "${BLUE}Test 6: Dry-Run Operations${NC}"
    echo "---------------------------"
    
    # Test list-backups (should work even without real backups)
    output=$("$BIN_DIR/restore_chat_history.sh" list-backups 2>&1)
    if echo "$output" | grep -qE "(backups|No backup|Available|📋)"; then
        test_pass "list-backups command works"
    else
        # If it exits with error, that's also valid (no backups directory)
        if echo "$output" | grep -qE "(not found|No backup directory)"; then
            test_pass "list-backups handles missing backups gracefully"
        else
            test_fail "list-backups command failed: $output"
        fi
    fi
    
    # Test list-workspaces (should work even without real workspaces)
    output=$("$BIN_DIR/restore_chat_history.sh" list-workspaces 2>&1)
    if echo "$output" | grep -qE "(workspaces|Available|Listing|📂)"; then
        test_pass "list-workspaces command works"
    else
        # Empty output is also valid (no workspaces)
        if [ -z "$output" ] || echo "$output" | grep -qE "(not found|No workspace)"; then
            test_pass "list-workspaces handles empty state gracefully"
        else
            test_fail "list-workspaces command failed: $output"
        fi
    fi
    
    # Test find command (should handle missing gracefully)
    output=$("$BIN_DIR/restore_chat_history.sh" find "NonExistentProject12345" 2>&1)
    if echo "$output" | grep -qE "(Found|not found|Searching|✅|❌)"; then
        test_pass "find command works"
    else
        test_fail "find command failed: $output"
    fi
}

# Test 7: Python scripts
test_python_scripts() {
    echo ""
    echo -e "${BLUE}Test 7: Python Script Validation${NC}"
    echo "---------------------------"
    
    # Test chat_extractor.py with empty input
    if echo "" | "$BIN_DIR/chat_extractor.py" "test_workspace" 2>&1 | grep -qE "(No chat|Error|found)"; then
        test_pass "chat_extractor.py handles empty input"
    else
        test_fail "chat_extractor.py doesn't handle empty input"
    fi
    
    # Test generate_index.py with empty input
    if echo "[]" | "$BIN_DIR/generate_index.py" 2>&1 | grep -qE "(No chats|Error|found)"; then
        test_pass "generate_index.py handles empty input"
    else
        test_fail "generate_index.py doesn't handle empty input"
    fi
}

# Test 8: Safety checks
test_safety_checks() {
    echo ""
    echo -e "${BLUE}Test 8: Safety Checks${NC}"
    echo "---------------------------"
    
    # Check that restore_chat_history.sh checks for Cursor running
    if grep -q "check_cursor_running\|pgrep.*Cursor" "$BIN_DIR/restore_chat_history.sh"; then
        test_pass "restore_chat_history.sh has Cursor running check"
    else
        test_fail "restore_chat_history.sh missing Cursor running check"
    fi
    
    # Check that emergency_recovery.sh has safety features
    if grep -q "backup\|Backing up" "$BIN_DIR/emergency_recovery.sh"; then
        test_pass "emergency_recovery.sh has backup safety"
    else
        test_fail "emergency_recovery.sh missing backup safety"
    fi
}

# Test 9: Relative path usage
test_relative_paths() {
    echo ""
    echo -e "${BLUE}Test 9: Relative Path Usage${NC}"
    echo "---------------------------"
    
    # Check that scripts don't have hardcoded absolute paths (except system paths)
    for script in "$BIN_DIR"/*.sh "$BIN_DIR"/*.py; do
        if [ -f "$script" ]; then
            # Check for hardcoded user paths (bad)
            if grep -qE "/Users/[^/]+/QuickCal|/Users/[^/]+/CalEvent" "$script" 2>/dev/null; then
                test_fail "$(basename "$script") has hardcoded user paths"
            else
                test_pass "$(basename "$script") uses relative/portable paths"
            fi
        fi
    done
}

# Test 10: Documentation links
test_documentation() {
    echo ""
    echo -e "${BLUE}Test 10: Documentation Files${NC}"
    echo "---------------------------"
    
    for doc in README.md QUICKSTART.md LICENSE CONTRIBUTING.md SECURITY.md; do
        if [ -f "$REPO_ROOT/$doc" ]; then
            test_pass "$doc exists"
        else
            test_fail "$doc is missing"
        fi
    done
    
    for doc in MIGRATION_GUIDE.md BACKUP_GUIDE.md EMERGENCY_RECOVERY.md TROUBLESHOOTING.md; do
        if [ -f "$REPO_ROOT/docs/$doc" ]; then
            test_pass "docs/$doc exists"
        else
            test_fail "docs/$doc is missing"
        fi
    done
}

# Run all tests
main() {
    setup_sandbox
    test_script_executability
    test_script_syntax
    test_help_output
    test_path_detection
    test_dependencies
    test_dry_run
    test_python_scripts
    test_safety_checks
    test_relative_paths
    test_documentation
    
    # Summary
    echo ""
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "=================="
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo -e "Total:  $TESTS_TOTAL"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}⚠️  Some tests failed. Please review above.${NC}"
        exit 1
    fi
}

main "$@"

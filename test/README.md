# Test Suite

Comprehensive test suite for validating Cursor Chat Recovery Kit functionality.

## Running Tests

```bash
./test/test-suite.sh
```

## What Gets Tested

### 1. Script Executability
- Verifies all scripts have executable permissions
- Checks both shell scripts (.sh) and Python scripts (.py)

### 2. Script Syntax Validation
- Validates bash syntax for all shell scripts
- Validates Python syntax for all Python scripts
- Catches syntax errors before runtime

### 3. Help/Usage Output
- Verifies all scripts show help or usage information
- Tests that commands are discoverable
- Ensures user-friendly error messages

### 4. Path Detection
- Verifies scripts detect their own location
- Checks for relative path usage
- Ensures portability

### 5. Dependency Checks
- Verifies required tools are available (bash, python3, sqlite3)
- Catches missing dependencies early

### 6. Dry-Run Operations
- Tests list-backups command
- Tests list-workspaces command
- Tests find command
- Validates graceful error handling

### 7. Python Script Validation
- Tests Python scripts with empty input
- Verifies error handling
- Checks for proper output formatting

### 8. Safety Checks
- Verifies Cursor running checks exist
- Validates backup safety features
- Ensures data protection

### 9. Relative Path Usage
- Checks for hardcoded user paths (bad)
- Verifies portable path usage
- Ensures cross-user compatibility

### 10. Documentation Files
- Verifies all documentation exists
- Checks for required files (README, LICENSE, etc.)
- Validates documentation structure

## Test Environment

Tests run in a sandboxed environment:
- Creates temporary test directories
- Doesn't modify real Cursor data
- Cleans up after execution
- Safe to run anytime

## Expected Results

All tests should pass. If any fail:
1. Review the error message
2. Check the script mentioned
3. Verify the test logic
4. Fix the issue and re-run

## Continuous Integration

This test suite can be integrated into CI/CD pipelines:
- Run on every commit
- Validate before releases
- Ensure quality standards

## Manual Testing

For manual testing of specific features:

```bash
# Test migration (dry-run)
./bin/restore_chat_history.sh list-backups
./bin/restore_chat_history.sh list-workspaces

# Test help output
./bin/restore_chat_history.sh
./bin/emergency_recovery.sh

# Test Python scripts
echo '{"tabs":[]}' | ./bin/chat_extractor.py test_ws
echo '[]' | ./bin/generate_index.py
```

---

**Note:** These tests don't modify your real Cursor workspace. They're safe to run anytime.

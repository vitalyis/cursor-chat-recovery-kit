# Troubleshooting Guide

Common issues and solutions for Cursor Chat Recovery Kit.

## Migration Issues

### "Workspace not found for: <path>"

**Symptoms:**
- Migration fails with "Could not find workspace"
- Workspace appears missing

**Solutions:**
1. Use `list-workspaces` to see available workspaces
2. Try partial path matching (just folder name)
3. Check backup date - use `list-backups` to see options
4. Verify folder name spelling and case sensitivity
5. Use `find` command to locate workspace ID

**Example:**
```bash
# First, find the workspace
./bin/restore_chat_history.sh find 'ProjectName'

# Then try migration with exact name
./bin/restore_chat_history.sh auto 'ExactOldName' 'ExactNewName'
```

### "Backup not found: <date>"

**Symptoms:**
- Migration fails with backup not found
- Backup date doesn't exist

**Solutions:**
1. List available backups: `./bin/restore_chat_history.sh list-backups`
2. Omit backup date to use latest: `auto 'Old' 'New'`
3. Check backup directory: `ls ~/cursor_backups/cursor_exports/`
4. Verify backup format: `YYYYMMDD_HHMMSS`

### Chat history still not showing after migration

**Symptoms:**
- Migration completes successfully
- Chat history doesn't appear in Cursor

**Solutions:**
1. **Completely quit Cursor** (not just close window)
   - Check Activity Monitor: `ps aux | grep -i cursor`
   - Force quit if needed: `killall Cursor`
2. **Restart Cursor** and open the correct folder
3. **Verify workspace** - Check you opened the renamed folder
4. **Check workspace.json** - Verify it matches current folder path
5. **Try different backup** - Use older backup if available

### Wrong workspace migrated

**Symptoms:**
- Migration worked but wrong project's chats appeared
- Multiple projects with similar names

**Solutions:**
1. Use more specific path fragments
2. Use `find` to verify correct workspace first
3. Use manual `migrate` with exact workspace IDs
4. Check workspace paths with `list-workspaces`

## Backup Issues

### "No backup directory found"

**Symptoms:**
- Backup commands fail
- No backups available

**Solutions:**
1. Create initial backup: `./bin/quick_backup.sh`
2. Check directory exists: `ls ~/cursor_backups/`
3. Create directory if missing: `mkdir -p ~/cursor_backups/cursor_exports`
4. Verify permissions: `ls -ld ~/cursor_backups`

### Backups not running automatically

**Symptoms:**
- Cron job set up but backups not happening
- No new backups appearing

**Solutions:**
1. Check cron is running: `ps aux | grep cron`
2. View cron jobs: `crontab -l`
3. Check cron logs (macOS): Console.app → search for "cron"
4. Verify script path in cron entry (use absolute path)
5. Test script manually: `./bin/export_cursor_chats.sh`
6. Check backup log: `tail ~/cursor_backups/backup.log`

### "Permission denied" during backup

**Symptoms:**
- Backup fails with permission errors
- Cannot write to backup directory

**Solutions:**
1. Check directory permissions: `ls -ld ~/cursor_backups`
2. Fix permissions: `chmod 755 ~/cursor_backups`
3. Check disk space: `df -h ~`
4. Verify write access: `touch ~/cursor_backups/test && rm ~/cursor_backups/test`

## Emergency Recovery Issues

### "Cursor is still running"

**Symptoms:**
- Recovery script refuses to run
- Error about Cursor being active

**Solutions:**
1. Quit Cursor completely (Cmd+Q)
2. Check Activity Monitor for Cursor processes
3. Force quit: `killall Cursor`
4. Wait a few seconds and try again
5. Verify: `pgrep -x Cursor` should return nothing

### Recovery didn't restore everything

**Symptoms:**
- Some workspaces missing after recovery
- Chat history incomplete

**Solutions:**
1. Check backup contents: `./bin/restore_chat_history.sh list-workspaces <backup>`
2. Try different backup (more recent)
3. Restore specific workspaces manually
4. Merge from multiple backups if needed

### "Backup corrupted" or incomplete

**Symptoms:**
- Backup exists but restore fails
- Missing files in backup

**Solutions:**
1. Try different backup
2. Check backup integrity: `ls -lh ~/cursor_backups/cursor_exports/<backup>/`
3. Verify backup contains expected directories
4. Check backup manifest if available
5. Use emergency backup if available

## General Issues

### Scripts not executable

**Symptoms:**
- "Permission denied" when running scripts
- Scripts won't execute

**Solutions:**
```bash
# Make all scripts executable
chmod +x bin/*.sh bin/*.py

# Or specific script
chmod +x bin/restore_chat_history.sh
```

### "Command not found" for aliases

**Symptoms:**
- Aliases don't work after setup
- Commands not recognized

**Solutions:**
1. Reload shell config: `source ~/.zshrc` or `source ~/.bashrc`
2. Restart terminal
3. Verify aliases: `grep cursor ~/.zshrc`
4. Re-run setup: `./bin/setup_aliases.sh`

### Python scripts fail

**Symptoms:**
- Chat export fails
- Python errors

**Solutions:**
1. Check Python 3 installed: `python3 --version`
2. Verify script executable: `chmod +x bin/chat_extractor.py`
3. Check shebang: `head -1 bin/chat_extractor.py` (should be `#!/usr/bin/env python3`)
4. Test Python: `python3 bin/chat_extractor.py --help`

### sqlite3 not found

**Symptoms:**
- Chat export fails
- "sqlite3: command not found"

**Solutions:**
1. Check if installed: `which sqlite3`
2. Install on macOS: `brew install sqlite3` (if using Homebrew)
3. Usually pre-installed on macOS - check PATH
4. Use full path: `/usr/bin/sqlite3`

## Platform-Specific Issues

### macOS Path Issues

**Symptoms:**
- Scripts can't find Cursor storage
- Paths with spaces cause issues

**Solutions:**
1. Use quotes for paths with spaces
2. Verify Cursor location: `ls ~/Library/Application\ Support/Cursor/User/`
3. Check path in scripts matches your system
4. Use absolute paths if relative paths fail

### Shell Compatibility

**Symptoms:**
- Scripts work in bash but not zsh (or vice versa)
- Syntax errors

**Solutions:**
1. Scripts use `#!/bin/bash` - ensure bash is available
2. Test in bash: `bash bin/restore_chat_history.sh`
3. Check shell: `echo $SHELL`
4. Use compatible shell or adjust scripts

## Performance Issues

### Migration takes too long

**Symptoms:**
- Migration hangs or is very slow
- Large workspace databases

**Solutions:**
1. Check workspace size: `du -sh ~/Library/Application\ Support/Cursor/User/workspaceStorage/<ws_id>`
2. Close other applications
3. Ensure sufficient disk space
4. Large workspaces (>1GB) may take several minutes

### Backups consuming too much space

**Symptoms:**
- Disk space running low
- Many large backups

**Solutions:**
1. Reduce retention (edit cleanup in scripts)
2. Manually delete old backups
3. Move backups to external drive
4. Use compression (future feature)

## Getting Help

### Debug Information

When reporting issues, include:

1. **Script output** - Full error messages
2. **System info** - macOS version, Cursor version
3. **Workspace info** - Size, number of workspaces
4. **Backup info** - Available backups, sizes
5. **Steps to reproduce** - What you did before error

### Useful Commands

```bash
# System info
sw_vers  # macOS version
cursor --version  # Cursor version (if available)

# Workspace info
./bin/restore_chat_history.sh list-workspaces
du -sh ~/Library/Application\ Support/Cursor/User/workspaceStorage

# Backup info
./bin/restore_chat_history.sh list-backups
du -sh ~/cursor_backups/cursor_exports/*

# Script debugging
bash -x bin/restore_chat_history.sh auto 'Old' 'New'
```

## Prevention

### Best Practices

1. **Regular backups** - Set up automatic backups
2. **Test migrations** - Try on non-critical projects first
3. **Verify backups** - Periodically check backup integrity
4. **Document renames** - Note when/why you renamed folders
5. **Keep multiple backups** - Don't rely on just the latest

### Regular Maintenance

```bash
# Weekly: Check workspace health
./bin/emergency_recovery.sh diagnose

# Weekly: Verify backups
./bin/restore_chat_history.sh list-backups

# Monthly: Test recovery
# (Create test backup, make change, restore, verify)
```

---

> [!IMPORTANT]
> Always close Cursor before running migration or restore operations.

<br>

**Made with ❤️ for the Cursor community**

# Emergency Recovery Guide

Complete guide for recovering from workspace corruption or data loss.

## When to Use Emergency Recovery

Use emergency recovery when:

- Cursor workspace is completely corrupted
- Chat history is lost and migration didn't work
- Multiple workspaces are affected
- You need to restore entire Cursor state
- Workspace storage directory is missing or damaged

## Quick Recovery

### Step 1: Diagnose the Problem

Check what's wrong with your workspace:

```bash
./bin/emergency_recovery.sh diagnose
```

This will show:
- Missing directories
- Workspace count
- Storage status
- History status

### Step 2: List Available Backups

See what backups you have:

```bash
./bin/emergency_recovery.sh list
# Or:
cursor-emergency list
```

### Step 3: Restore from Backup

Restore from a specific backup:

```bash
./bin/emergency_recovery.sh restore <backup_name>
# Example:
./bin/emergency_recovery.sh restore 20251219_160000
```

**⚠️ Important:** Close Cursor completely before restoring!

## Recovery Process

### What Gets Restored

Emergency recovery restores:

✅ **workspaceStorage/** - All workspace databases and chat history  
✅ **globalStorage/** - Cross-workspace data  
✅ **History/** - File edit history  
✅ **settings.json** - Cursor settings  
✅ **keybindings.json** - Key bindings

### Safety Features

Before restoring, the script:

1. **Creates emergency backup** of current state
2. **Validates backup** exists and is readable
3. **Checks Cursor is closed** (prevents corruption)
4. **Preserves current state** in `~/cursor_backups/emergency_backup_<timestamp>`

## Commands

### Diagnose

Check workspace health:

```bash
./bin/emergency_recovery.sh diagnose
```

**Output:**
```
🔍 WORKSPACE DIAGNOSIS
=====================
✅ workspaceStorage exists (5 workspaces found)
✅ globalStorage exists
✅ History exists (42 entries)
```

### List Backups

Show available recovery points:

```bash
./bin/emergency_recovery.sh list
```

**Output:**
```
📋 Available backups:
===================
  📁 20251220_160000 (2.5G) - 2025-12-20 16:00:00
  📁 20251220_120000 (2.4G) - 2025-12-20 12:00:00
  📁 20251219_160000 (2.4G) - 2025-12-19 16:00:00
```

### Restore

Restore from specific backup:

```bash
./bin/emergency_recovery.sh restore <backup_name>
```

**Example:**
```bash
./bin/emergency_recovery.sh restore 20251219_160000
```

**Process:**
1. Backs up current state
2. Restores workspaceStorage
3. Restores globalStorage
4. Restores History
5. Restores settings

### Find Cursor Data

Search for Cursor data locations:

```bash
./bin/emergency_recovery.sh find-cursor
```

Useful when:
- Cursor storage moved
- Multiple Cursor installations
- Investigating data locations

## Recovery Workflow

### Standard Recovery

```bash
# 1. Diagnose
./bin/emergency_recovery.sh diagnose

# 2. List backups
./bin/emergency_recovery.sh list

# 3. Close Cursor completely

# 4. Restore
./bin/emergency_recovery.sh restore 20251219_160000

# 5. Restart Cursor
```

### Partial Recovery

If only specific workspaces are affected, use migration instead:

```bash
# Restore specific workspace chat history
./bin/restore_chat_history.sh auto 'ProjectName' 'ProjectName' 20251219_160000
```

### Selective Restore

To restore only specific components:

```bash
# Manual restore of workspaceStorage only
BACKUP_DIR="$HOME/cursor_backups/cursor_exports"
BACKUP_NAME="20251219_160000"
CURSOR_STORAGE="$HOME/Library/Application Support/Cursor/User"

# Backup current
cp -r "$CURSOR_STORAGE/workspaceStorage" "$CURSOR_STORAGE/workspaceStorage.backup"

# Restore from backup
cp -r "$BACKUP_DIR/$BACKUP_NAME/workspaceStorage" "$CURSOR_STORAGE/"
```

## Before Recovery

### Checklist

- [ ] Close Cursor completely (check Activity Monitor)
- [ ] Verify backup exists and is readable
- [ ] Note current workspace paths (if possible)
- [ ] Understand what will be restored
- [ ] Have emergency backup location ready

### Backup Current State

The script automatically backs up current state, but you can also:

```bash
# Manual backup before recovery
./bin/quick_backup.sh
```

## After Recovery

### Verification Steps

1. **Restart Cursor** - Required for changes to take effect
2. **Check workspaces** - Verify projects open correctly
3. **Verify chat history** - Check that conversations are visible
4. **Check settings** - Verify preferences restored
5. **Test functionality** - Ensure Cursor works normally

### If Recovery Fails

1. **Check emergency backup** - Your pre-recovery state is saved
2. **Try different backup** - Use older/newer backup
3. **Partial restore** - Restore only specific components
4. **Check logs** - Review any error messages
5. **Manual restore** - Copy files manually if needed

## Troubleshooting

### "Backup not found"

**Cause:** Specified backup doesn't exist.

**Solutions:**
1. Run `list` to see available backups
2. Check backup directory: `ls ~/cursor_backups/cursor_exports/`
3. Verify backup name format: `YYYYMMDD_HHMMSS`

### "Cursor is still running"

**Cause:** Cursor process is active.

**Solutions:**
1. Quit Cursor completely (not just close window)
2. Check Activity Monitor: `ps aux | grep -i cursor`
3. Force quit if needed: `killall Cursor`

### "Permission denied"

**Cause:** Insufficient permissions to write to Cursor storage.

**Solutions:**
1. Check permissions: `ls -ld ~/Library/Application\ Support/Cursor/User`
2. Run with appropriate permissions
3. Check disk space: `df -h ~`

### Recovery didn't work

**Cause:** Backup may be corrupted or incomplete.

**Solutions:**
1. Try different backup
2. Check backup integrity: `ls -lh ~/cursor_backups/cursor_exports/<backup>/`
3. Verify backup contains expected files
4. Check emergency backup for rollback

### Workspaces missing after recovery

**Cause:** Backup may not contain all workspaces.

**Solutions:**
1. Check backup contents: `./bin/restore_chat_history.sh list-workspaces <backup>`
2. Use more recent backup
3. Merge workspaces from multiple backups manually

## Advanced Recovery

### Restore Specific Workspace

If only one workspace is affected:

```bash
# Find workspace ID in backup
./bin/restore_chat_history.sh list-workspaces 20251219_160000

# Restore specific workspace
BACKUP_WS="$HOME/cursor_backups/cursor_exports/20251219_160000/workspaceStorage/<workspace_id>"
CURRENT_WS="$HOME/Library/Application Support/Cursor/User/workspaceStorage/<workspace_id>"

cp -r "$BACKUP_WS" "$CURRENT_WS"
```

### Merge Multiple Backups

To combine workspaces from different backups:

```bash
# Copy workspace from backup 1
cp -r "$BACKUP1/workspaceStorage/<ws1>" "$CURRENT/workspaceStorage/"

# Copy workspace from backup 2
cp -r "$BACKUP2/workspaceStorage/<ws2>" "$CURRENT/workspaceStorage/"
```

### Restore Settings Only

To restore only settings without workspaces:

```bash
BACKUP_DIR="$HOME/cursor_backups/cursor_exports/20251219_160000"
CURSOR_STORAGE="$HOME/Library/Application Support/Cursor/User"

cp "$BACKUP_DIR/settings.json" "$CURSOR_STORAGE/"
cp "$BACKUP_DIR/keybindings.json" "$CURSOR_STORAGE/"
```

## Prevention

### Regular Backups

Set up automatic backups:

```bash
./bin/setup_cron.sh
```

### Monitor Workspace Health

Periodically check workspace status:

```bash
./bin/emergency_recovery.sh diagnose
```

### Test Recovery

Occasionally test that you can restore:

1. Create test backup
2. Make small change
3. Restore from backup
4. Verify restoration works

## Related Documentation

- [Migration Guide](MIGRATION_GUIDE.md) - For workspace-specific recovery
- [Backup Guide](BACKUP_GUIDE.md) - Setting up backups
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues

---

> **⚠️ Important:** Always close Cursor before running migration or restore operations!

**Made with ❤️ for the Cursor community**

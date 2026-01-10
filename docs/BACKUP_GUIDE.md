# Backup Guide

Complete guide to setting up and managing Cursor workspace backups.

## Overview

Regular backups protect your chat history and workspace data from loss. This guide covers:

- Setting up automatic backups
- Creating manual backups
- Managing backup storage
- Understanding backup structure

## Quick Setup

### Automatic Backups (Recommended)

Set up automatic backups every 4 hours:

```bash
./bin/setup_cron.sh
```

This will:
- Create a cron job that runs every 4 hours
- Save backups to `~/cursor_backups/cursor_exports/`
- Keep the last 5 backups automatically
- Log operations to `~/cursor_backups/backup.log`

### Manual Backups

Create a quick backup on demand:

```bash
./bin/quick_backup.sh
```

Or create a full backup with manifest:

```bash
./bin/export_cursor_chats.sh
```

## Backup Locations

### Default Backup Directory

```
~/cursor_backups/
├── cursor_exports/
│   ├── 20251220_160000/
│   ├── 20251220_120000/
│   └── 20251219_160000/
├── markdown_exports/
└── backup.log
```

### Backup Structure

Each backup contains:

```
<timestamp>/
├── workspaceStorage/     # Individual workspace databases
├── globalStorage/        # Cross-workspace data
├── History/              # File edit history
├── settings.json         # Cursor settings
├── keybindings.json      # Key bindings
└── backup_manifest.txt   # Backup metadata
```

## Backup Commands

### List Backups

View all available backups:

```bash
./bin/restore_chat_history.sh list-backups
# Or with alias:
cursor-backups
```

### View Backup Contents

Explore what's in a backup:

```bash
./bin/restore_chat_history.sh list-workspaces 20251219_160000
```

### Backup Size Management

Backups automatically keep the last 5 snapshots. Older backups are removed to save space.

To manually clean up:

```bash
cd ~/cursor_backups/cursor_exports
ls -lt | tail -n +6 | xargs rm -rf
```

## Backup Types

### Quick Backup

Fast backup for immediate needs:

```bash
./bin/quick_backup.sh
```

**Features:**
- Minimal output
- Fast execution
- Essential data only
- Auto-cleanup (keeps last 5)

### Full Backup

Complete backup with manifest:

```bash
./bin/export_cursor_chats.sh
```

**Features:**
- Complete workspace snapshot
- Backup manifest with metadata
- Size information
- Detailed logging

## Automation

### Cron Setup

The `setup_cron.sh` script configures automatic backups:

```bash
./bin/setup_cron.sh
```

**Schedule:** Every 4 hours at :00 minutes

**Cron Entry:**
```
0 */4 * * * /path/to/export_cursor_chats.sh >> ~/cursor_backups/backup.log 2>&1
```

### Managing Cron Jobs

View current cron jobs:

```bash
crontab -l
```

Edit cron jobs:

```bash
crontab -e
```

Remove backup cron:

```bash
crontab -l | grep -v 'export_cursor_chats.sh' | crontab -
```

### Custom Schedule

To change backup frequency, edit the cron entry:

```bash
crontab -e
```

Examples:
- Every hour: `0 * * * *`
- Every 6 hours: `0 */6 * * *`
- Daily at 2 AM: `0 2 * * *`

## Backup Verification

### Check Backup Logs

View backup operation logs:

```bash
tail -f ~/cursor_backups/backup.log
```

### Verify Backup Integrity

Check that backups contain expected data:

```bash
# List workspaces in backup
./bin/restore_chat_history.sh list-workspaces 20251219_160000

# Check backup size
du -sh ~/cursor_backups/cursor_exports/20251219_160000
```

## Backup Best Practices

1. **Regular Backups** - Set up automatic backups
2. **Multiple Snapshots** - Keep several backup versions
3. **Verify Backups** - Periodically check backup integrity
4. **Monitor Storage** - Ensure sufficient disk space
5. **Test Restores** - Verify you can restore from backups

## Storage Considerations

### Backup Sizes

Typical backup sizes:
- Small project: 10-50 MB
- Medium project: 50-200 MB
- Large project: 200 MB - 2 GB

### Disk Space Management

- Backups automatically keep last 5 snapshots
- Each backup is a full snapshot (not incremental)
- Monitor `~/cursor_backups/` directory size
- Clean up old backups manually if needed

### Backup Retention

Default retention: **Last 5 backups**

To change retention, edit the cleanup logic in:
- `quick_backup.sh` (line ~30)
- `export_cursor_chats.sh` (line ~90)

## Troubleshooting

### "No backup directory found"

**Cause:** Backups haven't been created yet.

**Solution:**
```bash
# Create initial backup
./bin/quick_backup.sh
```

### "Backup failed"

**Cause:** Cursor may be running or insufficient permissions.

**Solutions:**
1. Close Cursor before backup
2. Check disk space: `df -h ~`
3. Verify write permissions: `ls -ld ~/cursor_backups`

### Cron job not running

**Cause:** Cron may not have correct permissions or path.

**Solutions:**
1. Verify cron is running: `ps aux | grep cron`
2. Check cron logs: `grep CRON /var/log/syslog` (Linux) or Console.app (macOS)
3. Use absolute paths in cron entries

### Backups taking too long

**Cause:** Large workspace or slow disk.

**Solutions:**
1. Check workspace size: `du -sh ~/Library/Application\ Support/Cursor/User/workspaceStorage`
2. Consider excluding large workspaces
3. Run backups during low-activity periods

## Advanced Usage

### Custom Backup Location

To change backup location, edit scripts:

```bash
# In quick_backup.sh or export_cursor_chats.sh
BACKUP_DIR="$HOME/my_custom_backups/cursor_exports"
```

### Backup Specific Workspaces

To backup only specific workspaces:

```bash
# Manual backup of specific workspace
cp -r "$HOME/Library/Application Support/Cursor/User/workspaceStorage/<workspace_id>" \
      "$HOME/cursor_backups/manual_backup/"
```

### Backup to External Drive

```bash
# Create symlink to external drive
ln -s /Volumes/ExternalDrive/cursor_backups ~/cursor_backups
```

## Related Documentation

- [Migration Guide](MIGRATION_GUIDE.md) - Using backups for migration
- [Emergency Recovery](EMERGENCY_RECOVERY.md) - Restoring from backups
- [Troubleshooting](TROUBLESHOOTING.md) - Common backup issues

---

> **⚠️ Important:** Always close Cursor before running migration or restore operations!

**Made with ❤️ for the Cursor community**

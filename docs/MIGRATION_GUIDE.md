# Chat History Migration Guide

A comprehensive guide for migrating, backing up, and recovering Cursor chat history between workspaces.

## Overview

When you rename a project folder in Cursor, the workspace ID changes and your chat history becomes "orphaned" in the old workspace. This guide helps you:

- **Migrate** chat history between renamed projects
- **Restore** from backups after accidental loss
- **List** and explore available backups and workspaces
- **Auto-detect** and migrate by folder name

## Quick Start

### Setup (One-Time)

For convenient access from anywhere, install shell aliases:

```bash
./bin/setup_aliases.sh
source ~/.zshrc  # or restart terminal
```

This adds commands like:
- `cursor-migrate 'OldName' 'NewName'` - Quick migration
- `cursor-backups` - List backups
- `cursor-workspaces` - List workspaces
- `cursor-restore` - Full tool access

### Most Common Use Case: Folder Rename

If you renamed your project folder and lost chat history:

```bash
# With aliases installed:
cursor-migrate 'Old Folder Name' 'New Folder Name'

# Or directly:
./bin/restore_chat_history.sh auto 'Old Folder Name' 'New Folder Name'
```

**Important:** Close Cursor before running any migration!

## Commands

### 1. Auto Migration (Recommended)

Automatically finds and migrates chat history between renamed folders.

```bash
./bin/restore_chat_history.sh auto <old_path> <new_path> [backup_date]
```

**Parameters:**
- `old_path` - Original folder name or path fragment
- `new_path` - Current folder name or path fragment  
- `backup_date` - (Optional) Specific backup to use (default: latest)

**Examples:**
```bash
# Use latest backup
./bin/restore_chat_history.sh auto 'MyOldProject' 'MyNewProject'

# Use specific backup
./bin/restore_chat_history.sh auto 'MyOldProject' 'MyNewProject' 20251219_160000
```

### 2. Manual Migration

Directly migrate between specific workspace directories (advanced).

```bash
./bin/restore_chat_history.sh migrate <source_ws_dir> <target_ws_dir>
```

**Example:**
```bash
./bin/restore_chat_history.sh migrate \
  "$HOME/cursor_backups/cursor_exports/20251219_160000/workspaceStorage/ae441a8e..." \
  "$HOME/Library/Application Support/Cursor/User/workspaceStorage/f11b110f..."
```

### 3. List Backups

View all available backup snapshots.

```bash
./bin/restore_chat_history.sh list-backups
```

**Output:**
```
📋 Available backups:
===================
  📁 20251220_160000 (2.5G) - 2025-12-20 16:00:00
  📁 20251220_120000 (2.4G) - 2025-12-20 12:00:00
  📁 20251219_160000 (2.4G) - 2025-12-19 16:00:00
```

### 4. List Workspaces

View all workspaces in current Cursor or from a backup.

```bash
# List current workspaces
./bin/restore_chat_history.sh list-workspaces

# List workspaces from specific backup
./bin/restore_chat_history.sh list-workspaces 20251219_160000
```

**Output:**
```
📂 Available workspaces:
======================
  🔹 f11b110fec9af323600d378772bc1797
     Path: /Users/username/MyProject
     Size: 52M (DB: 40M)
```

### 5. Find Workspace

Find the workspace ID for a specific folder path.

```bash
./bin/restore_chat_history.sh find <folder_path>
```

**Example:**
```bash
./bin/restore_chat_history.sh find 'MyProject'
```

**Output:**
```
✅ Found: f11b110fec9af323600d378772bc1797
Full path: /Users/username/Library/Application Support/Cursor/User/workspaceStorage/f11b110fec9af323600d378772bc1797
```

## Understanding Cursor Workspaces

### What is a Workspace?

A workspace is Cursor's internal identifier for a project folder. Each workspace has:
- **Workspace ID** - A unique hash (e.g., `f11b110fec9af323600d378772bc1797`)
- **state.vscdb** - SQLite database containing chat history
- **images/** - Directory with chat-embedded images
- **workspace.json** - Metadata linking ID to folder path

### Where is Data Stored?

**Current Workspaces:**
```
~/Library/Application Support/Cursor/User/workspaceStorage/
```

**Backups:**
```
~/cursor_backups/cursor_exports/<timestamp>/workspaceStorage/
```

### What Happens on Folder Rename?

1. Cursor creates a **new workspace ID** for the renamed folder
2. The **old workspace** (with chat history) remains but is no longer linked
3. Your chat history appears "lost" but is actually still in the old workspace

## How It Works

### Auto Migration Process

1. **Searches backups** for workspace matching old folder name
2. **Finds current workspace** for new folder name
3. **Copies chat database** (`state.vscdb`) from old to new
4. **Copies images** associated with chats
5. **Creates backup** of current state before overwriting

### What Gets Migrated?

✅ **Chat history** (complete conversation threads)  
✅ **Images** (screenshots, diagrams in chats)  
✅ **Chat metadata** (timestamps, context)

❌ **Code changes** (tracked separately in git)  
❌ **Settings** (project-specific configs)  
❌ **Extensions data** (extension state)

## Important Notes

### Before Running Migration

1. **Close Cursor completely** - The script checks and will exit if Cursor is running
2. **Check available backups** - Use `list-backups` to confirm you have recent backups
3. **Verify folder names** - Make sure you're using the correct old/new folder names

### After Migration

1. **Restart Cursor** - Chat history won't appear until you restart
2. **Verify success** - Check that your chat history is visible
3. **Backup preserved** - Your pre-migration state is saved as `.backup_<timestamp>`

### Safety Features

- **Automatic backups** before overwriting
- **Cursor running check** prevents data corruption
- **Validation** of source and target workspaces
- **Timestamped backups** allow rollback if needed

## Troubleshooting

### "Workspace not found for: <path>"

**Cause:** The folder path isn't matching any workspace in the backup.

**Solutions:**
1. Use `list-workspaces <backup_date>` to see available workspaces
2. Try a different backup date with `list-backups`
3. Use partial path (e.g., just folder name, not full path)

### "Backup not found: <date>"

**Cause:** Specified backup doesn't exist.

**Solutions:**
1. Run `list-backups` to see available backups
2. Omit backup_date parameter to use latest
3. Check backup system is running (see Backup Guide)

### Chat history still not showing

**Cause:** Cursor might be caching or workspace ID mismatch.

**Solutions:**
1. Completely quit and restart Cursor (not just close window)
2. Verify you opened the correct folder in Cursor
3. Check workspace.json matches your current folder path
4. Try `list-workspaces` to confirm the target workspace exists

### Wrong folder got migrated

**Cause:** Multiple projects with similar names.

**Solutions:**
1. Use more specific path fragments
2. Use manual `migrate` command with exact workspace IDs
3. Use `find` command first to verify correct workspace

## Examples & Use Cases

### Example 1: Simple Rename
```bash
# Renamed "MyApp" to "MyApp-v2"
./bin/restore_chat_history.sh auto 'MyApp' 'MyApp-v2'
```

### Example 2: Using Specific Backup
```bash
# Want to restore from yesterday's backup
./bin/restore_chat_history.sh list-backups
./bin/restore_chat_history.sh auto 'OldName' 'NewName' 20251219_160000
```

### Example 3: Investigating Before Migration
```bash
# Find what backups are available
./bin/restore_chat_history.sh list-backups

# See what's in a backup
./bin/restore_chat_history.sh list-workspaces 20251219_160000

# Find current workspace
./bin/restore_chat_history.sh find 'MyProject'

# Now migrate
./bin/restore_chat_history.sh auto 'OldProject' 'MyProject'
```

### Example 4: Recovering from Multiple Renames
```bash
# If you renamed multiple times, use the oldest backup
./bin/restore_chat_history.sh list-backups
./bin/restore_chat_history.sh auto 'OriginalName' 'CurrentName' 20251210_120000
```

## Best Practices

1. **Avoid renaming project folders** when possible - use symlinks instead
2. **Run backups regularly** - ensure backup cron job is active
3. **Test migrations** on non-critical projects first
4. **Keep multiple backups** - don't rely on just the latest
5. **Document renames** - note when and why you renamed for future reference

## Tips

- Use tab completion for long folder names
- The script handles spaces in folder names
- Partial path matching works (e.g., just "ProjectName" vs "/Users/username/ProjectName")
- Run without arguments to see full help menu
- All operations preserve your original data

## Related Tools

- **emergency_recovery.sh** - Full Cursor workspace restoration
- **convert_chats_to_markdown.sh** - Export chats to markdown format
- **quick_backup.sh** - Manual backup trigger

## Technical Details

### Database Format

The `state.vscdb` is a SQLite database containing:
- Chat messages and responses
- Conversation threads and context
- Embedded code snippets
- References to image files

### Workspace ID Generation

Cursor generates workspace IDs using a hash of:
- Folder path
- Possibly timestamp or random seed
- Makes each folder rename create a new ID

### Backup System

Backups are created by the backup system:
- **Frequency:** Every 4 hours (configurable)
- **Location:** `~/cursor_backups/cursor_exports/`
- **Format:** `YYYYMMDD_HHMMSS`
- **Contents:** Full workspace storage snapshot

---

> **⚠️ Important:** Always close Cursor before running migration or restore operations!

**Made with ❤️ for the Cursor community**

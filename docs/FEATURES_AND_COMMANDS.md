# Features and Command Guide

Detailed overview of the main features and commands in Cursor Chat Recovery Kit.

## Chat History Migration

Automatically find and migrate chat history between renamed folders:

```bash
cursor-migrate 'OldName' 'NewName'
```

### Migration Features

- Searches backups for the source workspace
- Finds the current workspace by folder name
- Copies chat database and associated images
- Creates a safety backup before overwriting

## Backup Automation

Set up automatic backups every 4 hours:

```bash
./bin/setup_cron.sh
```

Create manual backups:

```bash
cursor-backup          # Quick backup
cursor-backups         # List available backups
```

## Emergency Recovery

Recover from complete workspace corruption:

```bash
cursor-emergency diagnose   # Check what's wrong
cursor-emergency list       # See available backups
cursor-emergency restore <backup_name>
```

## Chat Export

Convert chat conversations to Markdown:

```bash
./bin/convert_chats_to_markdown.sh latest
./bin/convert_chats_to_markdown.sh backup 20251219_160000
```

## Workspace Discovery

Explore your workspaces and backups:

```bash
cursor-workspaces                    # List current workspaces
cursor-workspaces 20251219_160000    # List workspaces in backup
./bin/restore_chat_history.sh find 'ProjectName'  # Find workspace ID
```

## Command Reference

### Migration Commands

<div align="left">

| Command | Description |
|:--------|:------------|
| `cursor-migrate 'Old' 'New'` | Auto-migrate chat history between renamed folders |
| `cursor-restore auto <old> <new> [backup]` | Same as migrate, with optional backup date |
| `cursor-restore migrate <src> <dst>` | Manual migration between workspace directories |
| `cursor-restore list-backups` | Show available backup snapshots |
| `cursor-restore list-workspaces [backup]` | List workspaces (current or from backup) |
| `cursor-restore find <path>` | Find workspace ID for a folder path |

</div>

### Backup Commands

<div align="left">

| Command | Description |
|:--------|:------------|
| `cursor-backup` | Create quick manual backup |
| `cursor-backups` | List all available backups |
| `./bin/export_cursor_chats.sh` | Full backup with manifest |
| `./bin/setup_cron.sh` | Set up automatic backups (every 4 hours) |

</div>

### Emergency Recovery Commands

<div align="left">

| Command | Description |
|:--------|:------------|
| `cursor-emergency diagnose` | Check workspace health |
| `cursor-emergency list` | Show available backups |
| `cursor-emergency restore <name>` | Restore from specific backup |

</div>

### Export and Utility Commands

<div align="left">

| Command | Description |
|:--------|:------------|
| `./bin/convert_chats_to_markdown.sh latest` | Export latest backup to Markdown |
| `./bin/convert_chats_to_markdown.sh backup <name>` | Export specific backup |
| `./bin/session_logger.sh start [topic]` | Start logging a development session |
| `./bin/cursor-chat-recover.sh scan` | Advanced: scan for chat files |

</div>

---

> [!IMPORTANT]
> Always close Cursor before running migration or restore operations.

<br>

**Made with ❤️ for the Cursor community**


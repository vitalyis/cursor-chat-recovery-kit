# Cursor Chat Recovery Kit

<div align="center">

![Cover Image](assets/cover.png)
<sup>*Recover and migrate your Cursor chat history when workspace folders are renamed or lost*</sup>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

</div>

## The Problem

When you rename a project folder in Cursor, the workspace ID changes and your chat history becomes "orphaned" in the old workspace. Your conversations appear lost, but they're actually still stored in Cursor's workspace storage—just no longer linked to your renamed folder.

**This toolkit helps you:**
- 🔄 Migrate chat history between renamed project folders
- 💾 Create automated backups of your Cursor workspace
- 🚨 Recover from workspace corruption or data loss
- 📄 Export chat conversations to Markdown format
- 🔍 Discover and explore your workspace backups

## Quick Start

<details>
<summary><b>📦 Installation</b></summary>

1. **Clone or download this repository:**

   ```bash
   git clone https://github.com/vitalyis/cursor-chat-recovery-kit.git
   cd cursor-chat-recovery-kit
   ```

2. **Set up convenient aliases (optional but recommended):**

   ```bash
   ./bin/setup_aliases.sh
   source ~/.zshrc  # or restart your terminal
   ```

</details>

### Most Common Use Case: Folder Rename

If you renamed your project folder and lost chat history:

```bash
# With aliases installed:
cursor-migrate 'Old Project Name' 'New Project Name'

# Or directly:
./bin/restore_chat_history.sh auto 'Old Project Name' 'New Project Name'
```

> **⚠️ Important:** Close Cursor completely before running any migration!

## Features

### 🔄 Chat History Migration

Automatically find and migrate chat history between renamed folders:

```bash
cursor-migrate 'OldName' 'NewName'
```

**Features:**

- ✅ Searches backups for source workspace
- ✅ Finds current workspace by folder name
- ✅ Copies chat database and associated images
- ✅ Creates backup before overwriting

### 💾 Backup Automation

Set up automatic backups every 4 hours:

```bash
./bin/setup_cron.sh
```

Or create manual backups:

```bash
cursor-backup          # Quick backup
cursor-backups         # List available backups
```

### 🚨 Emergency Recovery

Recover from complete workspace corruption:

```bash
cursor-emergency diagnose   # Check what's wrong
cursor-emergency list      # See available backups
cursor-emergency restore <backup_name>
```

### 📄 Chat Export

Convert chat conversations to Markdown:

```bash
./bin/convert_chats_to_markdown.sh latest
./bin/convert_chats_to_markdown.sh backup 20251219_160000
```

### 🔍 Workspace Discovery

Explore your workspaces and backups:

```bash
cursor-workspaces                    # List current workspaces
cursor-workspaces 20251219_160000   # List workspaces in backup
./bin/restore_chat_history.sh find 'ProjectName'  # Find workspace ID
```

## Command Reference

### Migration Commands

| Command | Description |
|:--------|:------------|
| `cursor-migrate 'Old' 'New'` | Auto-migrate chat history between renamed folders |
| `cursor-restore auto <old> <new> [backup]` | Same as migrate, with optional backup date |
| `cursor-restore migrate <src> <dst>` | Manual migration between workspace directories |
| `cursor-restore list-backups` | Show available backup snapshots |
| `cursor-restore list-workspaces [backup]` | List workspaces (current or from backup) |
| `cursor-restore find <path>` | Find workspace ID for a folder path |

### Backup Commands

| Command | Description |
|:--------|:------------|
| `cursor-backup` | Create quick manual backup |
| `cursor-backups` | List all available backups |
| `./bin/export_cursor_chats.sh` | Full backup with manifest |
| `./bin/setup_cron.sh` | Set up automatic backups (every 4 hours) |

### Emergency Recovery

| Command | Description |
|:--------|:------------|
| `cursor-emergency diagnose` | Check workspace health |
| `cursor-emergency list` | Show available backups |
| `cursor-emergency restore <name>` | Restore from specific backup |

### Export & Utilities

| Command | Description |
|:--------|:------------|
| `./bin/convert_chats_to_markdown.sh latest` | Export latest backup to Markdown |
| `./bin/convert_chats_to_markdown.sh backup <name>` | Export specific backup |
| `./bin/session_logger.sh start [topic]` | Start logging a development session |
| `./bin/cursor-chat-recover.sh scan` | Advanced: scan for chat files |

## How It Works

### Understanding Cursor Workspaces

A workspace is Cursor's internal identifier for a project folder. Each workspace has:

- **Workspace ID** — A unique hash (e.g., `f11b110fec9af323600d378772bc1797`)
- **state.vscdb** — SQLite database containing chat history
- **images/** — Directory with chat-embedded images
- **workspace.json** — Metadata linking ID to folder path

### Data Locations

**Current Workspaces:**

```text
~/Library/Application Support/Cursor/User/workspaceStorage/
```

**Backups:**

```text
~/cursor_backups/cursor_exports/<timestamp>/workspaceStorage/
```

### Migration Process

1. **Searches backups** for workspace matching old folder name
2. **Finds current workspace** for new folder name
3. **Copies chat database** (`state.vscdb`) from old to new
4. **Copies images** associated with chats
5. **Creates backup** of current state before overwriting

## Safety Features

- ✅ **Automatic backups** before overwriting
- ✅ **Cursor running check** prevents data corruption
- ✅ **Validation** of source and target workspaces
- ✅ **Timestamped backups** allow rollback if needed
- ✅ **Dry-run mode** for advanced operations

## Requirements

- **Platform:** macOS (primary support)
- **Cursor:** v2.3+ (tested with v2.3.29)
- **Dependencies:**
  - `sqlite3` (for chat export — usually pre-installed on macOS)
  - `python3` (for markdown conversion — usually pre-installed)

## Documentation

- **[Quick Start Guide](QUICKSTART.md)** — Get up and running in 5 minutes
- **[Migration Guide](docs/MIGRATION_GUIDE.md)** — Complete guide to chat history migration
- **[Backup Guide](docs/BACKUP_GUIDE.md)** — Setting up and managing backups
- **[Emergency Recovery](docs/EMERGENCY_RECOVERY.md)** — Full workspace recovery procedures
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** — Common issues and solutions

## Security & Privacy

- 🔒 **Local Processing Only** — All operations performed locally
- 🚫 **No Network Access** — No data transmission to external servers
- 📁 **File System Access** — Requires access to Cursor's workspace storage
- 💾 **Backup Safety** — Always creates backups before modifying data

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

Originally developed to solve the "lost chat history after folder rename" problem. Tested and refined through real-world recovery scenarios.

## Support

- 📖 Check the [documentation](docs/) for detailed guides
- 🐛 Report issues on GitHub
- 💡 Suggest improvements via pull requests

---

> **⚠️ Important:** Always close Cursor before running migration or restore operations!

**Made with ❤️ for the Cursor community**

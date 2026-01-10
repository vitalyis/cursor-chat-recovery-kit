# Quick Start Guide

> Get up and running with Cursor Chat Recovery Kit in **5 minutes**.

## Installation

### 1. Download or Clone

```bash
   git clone https://github.com/vitalyis/cursor-chat-recovery-kit.git
cd cursor-chat-recovery-kit
```

### 2. Make Scripts Executable

```bash
chmod +x bin/*.sh bin/*.py
```

### 3. Set Up Aliases (Recommended)

```bash
./bin/setup_aliases.sh
source ~/.zshrc  # or restart terminal
```

## Your First Migration

If you renamed a project folder and lost chat history:

1. **Close Cursor completely** (Cmd+Q, check Activity Monitor)

2. **Run migration:**

   ```bash
   cursor-migrate 'Old Project Name' 'New Project Name'
   # Or without aliases:
   ./bin/restore_chat_history.sh auto 'Old Project Name' 'New Project Name'
   ```

3. **Restart Cursor** and open your renamed project

4. **Verify** your chat history is restored

## Set Up Automatic Backups

Protect yourself from future issues:

```bash
./bin/setup_cron.sh
```

> This creates backups every 4 hours automatically.

## Common Commands

### Migration

```bash
cursor-migrate 'Old' 'New'    # Migrate chat history
cursor-backups                 # List backups
cursor-workspaces               # List workspaces
```

### Backup

```bash
cursor-backup                    # Manual backup
./bin/setup_cron.sh             # Auto-backup setup
```

### Recovery

```bash
cursor-emergency diagnose      # Check workspace health
cursor-emergency list          # List recovery points
cursor-emergency restore <backup>  # Full restore
```

## Next Steps

- 📖 Read the [full README](README.md) for complete documentation
- 📘 Check [Migration Guide](docs/MIGRATION_GUIDE.md) for detailed instructions
- 🔧 See [Troubleshooting](docs/TROUBLESHOOTING.md) if you encounter issues

## Getting Help

- 📚 Check the [documentation](docs/) folder
- 💻 Review [examples](examples/example-usage.sh)
- 🐛 Open an issue on GitHub

---

> **⚠️ Important:** Always close Cursor before running migration or restore operations!

**Made with ❤️ for the Cursor community**

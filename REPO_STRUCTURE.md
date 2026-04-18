# Repository Structure

Overview of the current Cursor Chat Recovery Kit layout.

## Directory Layout

```text
cursor-chat-recovery-kit/
├── bin/
│   ├── restore_chat_history.sh
│   ├── emergency_recovery.sh
│   ├── quick_backup.sh
│   ├── export_cursor_chats.sh
│   ├── relocate_cursor_project.sh
│   ├── convert_chats_to_markdown.sh
│   ├── setup_aliases.sh
│   ├── setup_cron.sh
│   ├── session_logger.sh
│   ├── cursor-chat-recover.sh
│   ├── chat_extractor.py
│   └── generate_index.py
├── docs/
│   ├── BACKUP_GUIDE.md
│   ├── EMERGENCY_RECOVERY.md
│   ├── FEATURES_AND_COMMANDS.md
│   ├── MIGRATION_GUIDE.md
│   └── TROUBLESHOOTING.md
├── tests/
│   ├── README.md
│   ├── TEST_RESULTS.md
│   ├── quick-validate.sh
│   └── test-suite.sh
├── examples/
│   └── example-usage.sh
├── assets/
│   └── cover.png
├── .github/
│   └── FUNDING.yml
├── README.md
├── QUICKSTART.md
├── CHANGELOG.md
├── RELEASE_NOTES.md
├── CONTRIBUTING.md
├── SECURITY.md
├── GITHUB_SETUP.md
├── REPO_STRUCTURE.md
├── LICENSE
└── .gitignore
```

## Role of Each Top-Level Directory

### `bin/`

The product surface of the repo. These are the commands users actually run.

### `docs/`

Longer guides, feature references, and troubleshooting material.

### `tests/`

Validation scripts and notes used to verify executability, syntax, help output,
and safer dry-run behavior.

### `examples/`

Small example invocations for common workflows.

### `assets/`

Images used in GitHub presentation and documentation.

## Script Groups

### Migration and Recovery

- `restore_chat_history.sh`
- `cursor-chat-recover.sh`
- `emergency_recovery.sh`

### Backup

- `quick_backup.sh`
- `export_cursor_chats.sh`
- `setup_cron.sh`

### Relocation

- `relocate_cursor_project.sh`

### Export and Utility

- `convert_chats_to_markdown.sh`
- `session_logger.sh`
- `setup_aliases.sh`

### Python Helpers

- `chat_extractor.py`
- `generate_index.py`

## Current Counts

- Shell scripts: 10
- Python scripts: 2
- Root documentation files: 8
- Guide docs under `docs/`: 5
- Test scripts: 2

## Notes

- The repo intentionally keeps executable tools in `bin/` rather than hiding
  them behind a generic `code/` folder.
- The `tests/` rename is part of the repo cleanup to align with the more common
  convention.

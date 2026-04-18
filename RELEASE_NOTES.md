# Cursor Chat Recovery Kit - Release Notes

## Version 2.0.0

**Release Date:** 2026-04-18

### Summary

This release adds project-aware repo relocation, covering the pieces that simple
chat migration misses: linked git worktrees, matching Cursor transcript/tool-log
folders, and a safer dry-run-first move workflow. It also cleans up the repo
layout and standardizes the test directory naming.

### Highlights

- New `bin/relocate_cursor_project.sh` command with `backup`, `preflight`, and `move` modes
- Project-scoped backups for matching `workspaceStorage` and `~/.cursor/projects/...`
- Linked git worktree relocation support
- Default old-path symlink recreation for Cursor compatibility after repo moves
- New `cursor-relocate` shell alias
- `test/` renamed to `tests/`
- Root docs cleaned up and structure docs synced to the actual repo layout
- Expanded docs for relocation and repo move workflows

### Example

```bash
cursor-relocate preflight /Users/me/OldRepo /Users/me/Projects/OldRepo
cursor-relocate move /Users/me/OldRepo /Users/me/Projects/OldRepo --apply
```

### Included Docs Updates

- `CHANGELOG.md`
- `docs/BACKUP_GUIDE.md`
- `docs/MIGRATION_GUIDE.md`
- `docs/FEATURES_AND_COMMANDS.md`
- `QUICKSTART.md`

---

## Version 1.0.0

**Release Date:** January 2026

### Summary

Initial public release of Cursor Chat Recovery Kit, focused on recovering and
migrating Cursor IDE chat history when workspace folders are renamed or lost.

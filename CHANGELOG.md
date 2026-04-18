# Changelog

All notable changes to Cursor Chat Recovery Kit are documented here.

## 2.0.0 - 2026-04-18

### Added

- Added `bin/relocate_cursor_project.sh` for project-aware repo relocation.
- Added project-scoped backups for matching `workspaceStorage` and `~/.cursor/projects/...` transcript/tool-log folders.
- Added linked git worktree relocation support with preflight inspection and dry-run mode.
- Added compatibility symlink recreation by default after repo moves.
- Added `cursor-relocate` alias in `bin/setup_aliases.sh`.

### Changed

- Expanded docs and quickstart guidance to cover safe repo moves, project-scoped backups, and relocation workflows.
- Reorganized `test/` to `tests/`.
- Cleaned the repo root docs and aligned repository structure docs with reality.
- Updated release notes for the 2.0.0 toolkit release.

## 1.0.0 - 2026-01

### Added

- Initial public release of chat migration, backup, emergency recovery, and export tooling for Cursor workspaces.

#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bin/lib/cursor_paths.sh
source "$SCRIPT_DIR/lib/cursor_paths.sh"

echo "⚡ QUICK CURSOR BACKUP"
echo "====================="

# Quick backup with minimal output
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/cursor_backups"
CURSOR_STORAGE="$(cursor_user_dir)"
EXPORT_DIR="$BACKUP_DIR/cursor_exports/$TIMESTAMP"
WORKSPACE_STORAGE="$CURSOR_STORAGE/workspaceStorage"

mkdir -p "$EXPORT_DIR"

echo "🔄 Backing up workspace data..."

if [ ! -d "$WORKSPACE_STORAGE" ]; then
    echo "❌ workspaceStorage not found at: $WORKSPACE_STORAGE"
    print_cursor_path_hint
    rm -rf "$EXPORT_DIR"
    exit 1
fi

# Copy all essential data quickly
cp -r "$WORKSPACE_STORAGE" "$EXPORT_DIR/"
[ -d "$CURSOR_STORAGE/globalStorage" ] && cp -r "$CURSOR_STORAGE/globalStorage" "$EXPORT_DIR/"
[ -d "$CURSOR_STORAGE/History" ] && cp -r "$CURSOR_STORAGE/History" "$EXPORT_DIR/"
[ -f "$CURSOR_STORAGE/settings.json" ] && cp "$CURSOR_STORAGE/settings.json" "$EXPORT_DIR/"
[ -f "$CURSOR_STORAGE/keybindings.json" ] && cp "$CURSOR_STORAGE/keybindings.json" "$EXPORT_DIR/"

# Quick manifest
echo "Quick Backup - $TIMESTAMP" > "$EXPORT_DIR/backup_manifest.txt"
echo "Date: $(date)" >> "$EXPORT_DIR/backup_manifest.txt"

total_size=$(du -sh "$EXPORT_DIR" | cut -f1)

# Clean up old backups (keep last 5)
cd "$BACKUP_DIR/cursor_exports"
ls -t | tail -n +6 | xargs -r rm -rf 2>/dev/null

echo "✅ Quick backup complete! ($total_size)"
echo "📁 $EXPORT_DIR"

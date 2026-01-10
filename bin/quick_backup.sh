#!/bin/bash

echo "⚡ QUICK CURSOR BACKUP"
echo "====================="

# Quick backup with minimal output
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/cursor_backups"
CURSOR_STORAGE="$HOME/Library/Application Support/Cursor/User"
EXPORT_DIR="$BACKUP_DIR/cursor_exports/$TIMESTAMP"

mkdir -p "$EXPORT_DIR"

echo "🔄 Backing up workspace data..."

# Copy all essential data quickly
cp -r "$CURSOR_STORAGE/workspaceStorage" "$EXPORT_DIR/" 2>/dev/null
cp -r "$CURSOR_STORAGE/globalStorage" "$EXPORT_DIR/" 2>/dev/null
cp -r "$CURSOR_STORAGE/History" "$EXPORT_DIR/" 2>/dev/null
cp "$CURSOR_STORAGE/settings.json" "$EXPORT_DIR/" 2>/dev/null
cp "$CURSOR_STORAGE/keybindings.json" "$EXPORT_DIR/" 2>/dev/null

# Quick manifest
echo "Quick Backup - $TIMESTAMP" > "$EXPORT_DIR/backup_manifest.txt"
echo "Date: $(date)" >> "$EXPORT_DIR/backup_manifest.txt"

total_size=$(du -sh "$EXPORT_DIR" | cut -f1)

# Clean up old backups (keep last 5)
cd "$BACKUP_DIR/cursor_exports" 2>/dev/null
ls -t | tail -n +6 | xargs -r rm -rf 2>/dev/null

echo "✅ Quick backup complete! ($total_size)"
echo "📁 $EXPORT_DIR"

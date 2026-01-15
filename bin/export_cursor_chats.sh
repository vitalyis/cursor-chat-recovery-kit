#!/bin/bash

echo "🛡️ CURSOR WORKSPACE BACKUP SYSTEM"
echo "================================="

TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/cursor_backups"
CURSOR_STORAGE="$HOME/Library/Application Support/Cursor/User"
EXPORT_DIR="$BACKUP_DIR/cursor_exports/$TIMESTAMP"

echo "📅 Backup timestamp: $TIMESTAMP"
echo "📁 Export location: $EXPORT_DIR"
echo ""

# Create timestamped backup directory
mkdir -p "$EXPORT_DIR"

echo "🔄 Exporting Cursor workspace data..."

# Copy all workspace storage (contains individual workspace databases)
if [ -d "$CURSOR_STORAGE/workspaceStorage" ]; then
    echo "  📦 Copying workspaceStorage..."
    cp -r "$CURSOR_STORAGE/workspaceStorage" "$EXPORT_DIR/"
    ws_size=$(du -sh "$EXPORT_DIR/workspaceStorage" | cut -f1)
    echo "  ✅ Workspace storage: $ws_size"
else
    echo "  ❌ workspaceStorage not found"
fi

# Copy global storage (contains cross-workspace data)
if [ -d "$CURSOR_STORAGE/globalStorage" ]; then
    echo "  📦 Copying globalStorage..."
    cp -r "$CURSOR_STORAGE/globalStorage" "$EXPORT_DIR/"
    gs_size=$(du -sh "$EXPORT_DIR/globalStorage" | cut -f1)
    echo "  ✅ Global storage: $gs_size"
else
    echo "  ❌ globalStorage not found"
fi

# Copy history (contains file edit history and chat context)
if [ -d "$CURSOR_STORAGE/History" ]; then
    echo "  📦 Copying History..."
    cp -r "$CURSOR_STORAGE/History" "$EXPORT_DIR/"
    h_size=$(du -sh "$EXPORT_DIR/History" | cut -f1)
    echo "  ✅ History: $h_size"
else
    echo "  ❌ History not found"
fi

# Copy settings and keybindings
echo "  📦 Copying settings..."
if [ -f "$CURSOR_STORAGE/settings.json" ]; then
    cp "$CURSOR_STORAGE/settings.json" "$EXPORT_DIR/"
    echo "  ✅ Settings backed up"
fi

if [ -f "$CURSOR_STORAGE/keybindings.json" ]; then
    cp "$CURSOR_STORAGE/keybindings.json" "$EXPORT_DIR/"
    echo "  ✅ Keybindings backed up"
fi

# Create backup manifest
cat > "$EXPORT_DIR/backup_manifest.txt" << EOF
Cursor Workspace Backup
======================
Date: $(date)
Timestamp: $TIMESTAMP
Host: $(hostname)
User: $(whoami)

Contents:
- workspaceStorage/ (individual workspace databases)
- globalStorage/ (cross-workspace data)  
- History/ (file edit history and chat context)
- settings.json (Cursor settings)
- keybindings.json (key bindings)

Backup Size: $(du -sh "$EXPORT_DIR" | cut -f1)
EOF

# Get total backup size
total_size=$(du -sh "$EXPORT_DIR" | cut -f1)

echo ""
echo "✅ BACKUP COMPLETED SUCCESSFULLY!"
echo "📊 Total backup size: $total_size"
echo "📁 Location: $EXPORT_DIR"
echo ""

# Clean up old backups (keep last 5)
echo "🧹 Cleaning up old backups (keeping last 5)..."
cd "$BACKUP_DIR/cursor_exports" 2>/dev/null || exit 0
ls -t | tail -n +6 | xargs -r rm -rf
old_count=$(ls -1 | wc -l)
echo "📈 Total backups retained: $old_count"

echo ""
echo "🎯 BACKUP STATUS: SUCCESS"
echo "⏰ Next backup: $(date -d '+4 hours' '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -v+4H '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'In 4 hours')"
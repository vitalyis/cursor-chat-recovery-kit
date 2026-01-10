#!/bin/bash

echo "🚨 EMERGENCY CURSOR WORKSPACE RECOVERY"
echo "======================================"
echo "⚠️  Use this script when Cursor workspace is corrupted or lost"
echo ""

CURSOR_STORAGE="$HOME/Library/Application Support/Cursor/User"
BACKUP_DIR="$HOME/cursor_backups/cursor_exports"

# Function to list available backups
list_backups() {
    echo "📋 Available backups:"
    echo "==================="
    if [ -d "$BACKUP_DIR" ]; then
        ls -la "$BACKUP_DIR" | grep "^d" | grep -E "[0-9]{8}_[0-9]{6}" | while read -r line; do
            backup_folder=$(echo "$line" | awk '{print $NF}')
            backup_size=$(du -sh "$BACKUP_DIR/$backup_folder" 2>/dev/null | cut -f1)
            backup_date=$(echo "$backup_folder" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
            echo "  📁 $backup_folder ($backup_size) - $backup_date"
        done
    else
        echo "❌ No backup directory found at: $BACKUP_DIR"
        exit 1
    fi
}

# Function to show what's wrong with current workspace
diagnose_workspace() {
    echo "🔍 WORKSPACE DIAGNOSIS"
    echo "====================="
    
    if [ ! -d "$CURSOR_STORAGE" ]; then
        echo "❌ CRITICAL: Cursor User directory missing: $CURSOR_STORAGE"
        return 1
    fi
    
    if [ ! -d "$CURSOR_STORAGE/workspaceStorage" ]; then
        echo "❌ CRITICAL: workspaceStorage directory missing"
    else
        ws_count=$(ls -1 "$CURSOR_STORAGE/workspaceStorage" | wc -l)
        echo "✅ workspaceStorage exists ($ws_count workspaces found)"
    fi
    
    if [ ! -d "$CURSOR_STORAGE/globalStorage" ]; then
        echo "❌ globalStorage directory missing"
    else
        echo "✅ globalStorage exists"
    fi
    
    if [ ! -d "$CURSOR_STORAGE/History" ]; then
        echo "❌ History directory missing"
    else
        history_count=$(ls -1 "$CURSOR_STORAGE/History" | wc -l)
        echo "✅ History exists ($history_count entries)"
    fi
    
    echo ""
}

# Function to restore from backup
restore_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [ ! -d "$backup_path" ]; then
        echo "❌ Backup not found: $backup_path"
        exit 1
    fi
    
    echo "🔄 RESTORING FROM BACKUP: $backup_name"
    echo "======================================"
    
    # Create backup of current state (if exists)
    if [ -d "$CURSOR_STORAGE" ]; then
        echo "💾 Backing up current state..."
        current_backup="$HOME/cursor_backups/emergency_backup_$(date '+%Y%m%d_%H%M%S')"
        mkdir -p "$current_backup"
        cp -r "$CURSOR_STORAGE"/* "$current_backup/" 2>/dev/null
        echo "✅ Current state backed up to: $current_backup"
    fi
    
    echo "🔄 Restoring workspace data..."
    
    # Restore workspaceStorage
    if [ -d "$backup_path/workspaceStorage" ]; then
        echo "  📦 Restoring workspaceStorage..."
        rm -rf "$CURSOR_STORAGE/workspaceStorage" 2>/dev/null
        cp -r "$backup_path/workspaceStorage" "$CURSOR_STORAGE/"
        echo "  ✅ workspaceStorage restored"
    fi
    
    # Restore globalStorage
    if [ -d "$backup_path/globalStorage" ]; then
        echo "  📦 Restoring globalStorage..."
        rm -rf "$CURSOR_STORAGE/globalStorage" 2>/dev/null
        cp -r "$backup_path/globalStorage" "$CURSOR_STORAGE/"
        echo "  ✅ globalStorage restored"
    fi
    
    # Restore History
    if [ -d "$backup_path/History" ]; then
        echo "  📦 Restoring History..."
        rm -rf "$CURSOR_STORAGE/History" 2>/dev/null
        cp -r "$backup_path/History" "$CURSOR_STORAGE/"
        echo "  ✅ History restored"
    fi
    
    # Restore settings
    if [ -f "$backup_path/settings.json" ]; then
        cp "$backup_path/settings.json" "$CURSOR_STORAGE/"
        echo "  ✅ Settings restored"
    fi
    
    if [ -f "$backup_path/keybindings.json" ]; then
        cp "$backup_path/keybindings.json" "$CURSOR_STORAGE/"
        echo "  ✅ Keybindings restored"
    fi
    
    echo ""
    echo "🎉 RECOVERY COMPLETED!"
    echo "====================="
    echo "🔄 Please restart Cursor to load the restored workspace"
    echo "📁 Your current state was backed up to: $current_backup"
}

# Main menu
case "${1:-menu}" in
    "list")
        list_backups
        ;;
    "diagnose")
        diagnose_workspace
        ;;
    "restore")
        if [ -z "$2" ]; then
            echo "❌ Please specify backup to restore from"
            echo "Usage: $0 restore 20250928_201727"
            echo ""
            list_backups
            exit 1
        fi
        restore_backup "$2"
        ;;
    "find-cursor")
        echo "🔍 Searching for Cursor data locations..."
        find "$HOME/Library" -name "*cursor*" -type d 2>/dev/null | head -20
        find "$HOME/Library" -name "state.vscdb" 2>/dev/null | head -10
        ;;
    *)
        echo "🚨 EMERGENCY RECOVERY COMMANDS:"
        echo ""
        echo "  $0 diagnose        - Check what's wrong with workspace"
        echo "  $0 list           - Show available backups"
        echo "  $0 restore [name] - Restore from specific backup"
        echo "  $0 find-cursor    - Search for Cursor data locations"
        echo ""
        echo "📋 RECOVERY WORKFLOW:"
        echo "  1. $0 diagnose     (see what's broken)"
        echo "  2. $0 list         (find good backup)"
        echo "  3. $0 restore [backup_name]"
        echo ""
        echo "⚠️  IMPORTANT: Close Cursor before running restore!"
        ;;
esac
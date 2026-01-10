#!/bin/bash

echo "📄 CURSOR CHAT TO MARKDOWN CONVERTER"
echo "===================================="

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKUP_DIR="$HOME/cursor_backups/cursor_exports"
OUTPUT_DIR="$HOME/cursor_backups/markdown_exports"

# Function to extract chats from a specific backup
extract_from_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [ ! -d "$backup_path" ]; then
        echo "❌ Backup not found: $backup_path"
        return 1
    fi
    
    echo "🔄 Processing backup: $backup_name"
    
    # Create output directory for this backup
    local output_path="$OUTPUT_DIR/$backup_name"
    mkdir -p "$output_path"
    
    # Initialize chat index log
    local chat_index_log="$output_path/chat_index.txt"
    cat > "$chat_index_log" << EOF
📚 CURSOR CHAT INDEX - BACKUP: $backup_name
==============================================
📅 Generated: $(date)
🕐 Backup Date: $(echo "$backup_name" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')

EOF
    
    # Find all state.vscdb files in workspaceStorage
    local total_chats=0
    local workspace_count=0
    
    find "$backup_path/workspaceStorage" -name "state.vscdb" 2>/dev/null | while read -r db_file; do
        local workspace_id=$(basename "$(dirname "$db_file")")
        echo "  📦 Processing workspace: $workspace_id"
        
        # Extract chat data using sqlite3
        if command -v sqlite3 >/dev/null 2>&1; then
            local chat_output="$output_path/chats_${workspace_id}.md"
            
            # Create markdown header
            cat > "$chat_output" << EOF
# Cursor Chat Extract - Workspace: $workspace_id
**Backup Date:** $(echo "$backup_name" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')  
**Extracted:** $(date)

---

EOF
            
            # Extract chat data using the correct Cursor schema and Python extractor
            sqlite3 "$db_file" "
            SELECT value FROM ItemTable 
            WHERE key LIKE 'workbench.panel.aichat.view.aichat.chatdata'
            OR key LIKE '%chatdata%'
            LIMIT 1;
            " 2>/dev/null | python3 "$SCRIPT_DIR/chat_extractor.py" "$workspace_id" >> "$chat_output" 2>/dev/null
            
            # Also extract chat index for the log
            local chat_index_json=$(sqlite3 "$db_file" "
            SELECT value FROM ItemTable 
            WHERE key LIKE 'workbench.panel.aichat.view.aichat.chatdata'
            OR key LIKE '%chatdata%'
            LIMIT 1;
            " 2>/dev/null | python3 "$SCRIPT_DIR/chat_extractor.py" "$workspace_id" "index" 2>/dev/null)
            
            # Process the chat index JSON and add to log
            if [ -n "$chat_index_json" ] && [ "$chat_index_json" != "[]" ]; then
                echo "" >> "$chat_index_log"
                echo "🎯 WORKSPACE: $workspace_id" >> "$chat_index_log"
                echo "$chat_index_json" | python3 "$SCRIPT_DIR/generate_index.py" >> "$chat_index_log"
            fi
            
            # Check if file has content beyond header
            if [ $(wc -l < "$chat_output") -gt 10 ]; then
                echo "  ✅ Exported chats to: $(basename "$chat_output")"
            else
                echo "  ⚠️  No chat data found in workspace $workspace_id"
                rm -f "$chat_output"
            fi
        else
            echo "  ❌ sqlite3 not available - cannot extract chat data"
        fi
    done
}

# Function to process latest backup
process_latest() {
    echo "🔍 Finding latest backup..."
    local latest=$(ls -1 "$BACKUP_DIR" 2>/dev/null | grep -E "[0-9]{8}_[0-9]{6}" | sort -r | head -n 1)
    
    if [ -n "$latest" ]; then
        echo "📁 Latest backup: $latest"
        extract_from_backup "$latest"
    else
        echo "❌ No backups found in $BACKUP_DIR"
        return 1
    fi
}

# Function to show available markdown exports
show_exports() {
    echo "📚 Available Markdown Exports:"
    echo "============================="
    
    if [ -d "$OUTPUT_DIR" ]; then
        # Show chat index logs first
        find "$OUTPUT_DIR" -name "chat_index.txt" 2>/dev/null | while read -r index_file; do
            local size=$(du -sh "$index_file" 2>/dev/null | cut -f1)
            local backup=$(basename "$(dirname "$index_file")")
            echo "  📚 $backup/chat_index.txt ($size) - 🗺️ Chat Index Log"
        done
        
        echo ""
        
        # Show markdown files
        find "$OUTPUT_DIR" -name "*.md" 2>/dev/null | while read -r md_file; do
            local size=$(du -sh "$md_file" 2>/dev/null | cut -f1)
            local backup=$(basename "$(dirname "$md_file")")
            local filename=$(basename "$md_file")
            echo "  📄 $backup/$filename ($size)"
        done
    else
        echo "  ❌ No exports found"
    fi
}

# Function to show chat index for a specific backup
show_chat_index() {
    local backup_name="$1"
    local index_file="$OUTPUT_DIR/$backup_name/chat_index.txt"
    
    if [ -f "$index_file" ]; then
        echo "📚 CHAT INDEX PREVIEW - $backup_name"
        echo "=========================================="
        cat "$index_file"
    else
        echo "❌ Chat index not found for backup: $backup_name"
        echo "Run: $0 backup $backup_name (to generate index)"
    fi
}

# Main menu
case "${1:-menu}" in
    "latest")
        process_latest
        ;;
    "backup")
        if [ -z "$2" ]; then
            echo "❌ Please specify backup name"
            echo "Usage: $0 backup 20250928_201727"
            exit 1
        fi
        extract_from_backup "$2"
        ;;
    "list")
        show_exports
        ;;
    "index")
        if [ -z "$2" ]; then
            # Show latest index if no backup specified
            latest=$(ls -1 "$OUTPUT_DIR" 2>/dev/null | grep -E "[0-9]{8}_[0-9]{6}" | sort -r | head -n 1)
            if [ -n "$latest" ]; then
                show_chat_index "$latest"
            else
                echo "❌ No backup indices found"
            fi
        else
            show_chat_index "$2"
        fi
        ;;
    "open")
        echo "📂 Opening markdown exports directory..."
        open "$OUTPUT_DIR" 2>/dev/null || echo "Directory: $OUTPUT_DIR"
        ;;
    *)
        echo "📄 CHAT TO MARKDOWN CONVERTER COMMANDS:"
        echo ""
        echo "  $0 latest          - Convert chats from latest backup"
        echo "  $0 backup [name]   - Convert chats from specific backup"
        echo "  $0 list           - Show available markdown exports"
        echo "  $0 index [backup]  - Show chat index (titles & counts)"
        echo "  $0 open           - Open exports directory"
        echo ""
        echo "💡 WHAT THIS DOES:"
        echo "  • Extracts chat conversations from SQLite backups"
        echo "  • Converts to readable Markdown format"
        echo "  • Organizes by backup timestamp and workspace"
        echo "  • Preserves chat titles, dates, and conversation flow"
        echo "  • Creates chat index logs with titles and timestamps"
        echo ""
        echo "📁 Files saved to: $OUTPUT_DIR"
        echo "📚 Index logs: $OUTPUT_DIR/[backup]/chat_index.txt"
        ;;
esac

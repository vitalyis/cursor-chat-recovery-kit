#!/bin/bash
# Chat History Migration & Recovery Script
# Migrates Cursor chat history between workspaces or restores from backups

CURSOR_STORAGE="$HOME/Library/Application Support/Cursor/User"
BACKUP_DIR="$HOME/cursor_backups/cursor_exports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if Cursor is running
check_cursor_running() {
    if pgrep -x "Cursor" > /dev/null; then
        echo -e "${RED}❌ ERROR: Cursor is still running!${NC}"
        echo "Please close Cursor first, then run this script again."
        exit 1
    fi
}

# Function to find workspace ID by folder path
find_workspace_by_path() {
    local search_path="$1"
    local storage_dir="$2"
    
    for ws_dir in "$storage_dir"/*/; do
        if [ -f "$ws_dir/workspace.json" ]; then
            if grep -q "$search_path" "$ws_dir/workspace.json" 2>/dev/null; then
                basename "$ws_dir"
                return 0
            fi
        fi
    done
    return 1
}

# Function to list available backups
list_backups() {
    echo -e "${BLUE}📋 Available backups:${NC}"
    echo "==================="
    if [ -d "$BACKUP_DIR" ]; then
        ls -lt "$BACKUP_DIR" | grep "^d" | grep -E "[0-9]{8}_[0-9]{6}" | while read -r line; do
            backup_folder=$(echo "$line" | awk '{print $NF}')
            backup_size=$(du -sh "$BACKUP_DIR/$backup_folder" 2>/dev/null | cut -f1)
            backup_date=$(echo "$backup_folder" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
            echo "  📁 $backup_folder ($backup_size) - $backup_date"
        done
    else
        echo -e "${RED}❌ No backup directory found at: $BACKUP_DIR${NC}"
        exit 1
    fi
}

# Function to list workspaces in a storage directory
list_workspaces() {
    local storage_dir="$1"
    echo -e "${BLUE}📂 Available workspaces:${NC}"
    echo "======================"
    
    for ws_dir in "$storage_dir"/*/; do
        if [ -f "$ws_dir/workspace.json" ]; then
            ws_id=$(basename "$ws_dir")
            ws_path=$(grep -o '"folder":.*' "$ws_dir/workspace.json" | sed 's/"folder": "file:\/\/\(.*\)"/\1/' | sed 's/%20/ /g')
            ws_size=$(du -sh "$ws_dir" 2>/dev/null | cut -f1)
            db_size=$(du -sh "$ws_dir/state.vscdb" 2>/dev/null | cut -f1 || echo "N/A")
            echo "  🔹 $ws_id"
            echo "     Path: $ws_path"
            echo "     Size: $ws_size (DB: $db_size)"
            echo ""
        fi
    done
}

# Function to migrate chat history between workspaces
migrate_workspace() {
    local source_ws="$1"
    local target_ws="$2"
    
    if [ ! -d "$source_ws" ]; then
        echo -e "${RED}❌ Source workspace not found: $source_ws${NC}"
        exit 1
    fi
    
    if [ ! -d "$target_ws" ]; then
        echo -e "${RED}❌ Target workspace not found: $target_ws${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🔄 Migrating chat history...${NC}"
    echo "From: $source_ws"
    echo "To: $target_ws"
    echo ""
    
    # Backup current target state
    echo -e "${YELLOW}💾 Backing up current target state...${NC}"
    if [ -f "$target_ws/state.vscdb" ]; then
        cp "$target_ws/state.vscdb" "$target_ws/state.vscdb.backup_$(date '+%Y%m%d_%H%M%S')" 2>/dev/null
    fi
    
    # Copy chat history database
    echo -e "${GREEN}📋 Copying chat database...${NC}"
    if [ -f "$source_ws/state.vscdb" ]; then
        cp "$source_ws/state.vscdb" "$target_ws/state.vscdb"
        echo "✅ Chat database copied"
    fi
    
    if [ -f "$source_ws/state.vscdb.backup" ]; then
        cp "$source_ws/state.vscdb.backup" "$target_ws/state.vscdb.backup"
        echo "✅ Chat database backup copied"
    fi
    
    # Copy images
    if [ -d "$source_ws/images" ]; then
        echo -e "${GREEN}🖼️  Copying images...${NC}"
        rm -rf "$target_ws/images" 2>/dev/null
        cp -r "$source_ws/images" "$target_ws/"
        echo "✅ Images copied"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Chat history migrated successfully!${NC}"
    echo -e "${YELLOW}🔄 Please restart Cursor to see your chat history.${NC}"
}

# Function to auto-migrate by folder path
auto_migrate() {
    local old_path="$1"
    local new_path="$2"
    local backup_date="${3:-latest}"
    
    echo -e "${BLUE}🔍 Searching for workspaces...${NC}"
    
    # Find source workspace in backup
    local source_ws=""
    if [ "$backup_date" = "latest" ]; then
        # Find most recent backup
        backup_date=$(ls -t "$BACKUP_DIR" | grep -E "[0-9]{8}_[0-9]{6}" | head -1)
    fi
    
    local backup_storage="$BACKUP_DIR/$backup_date/workspaceStorage"
    if [ ! -d "$backup_storage" ]; then
        echo -e "${RED}❌ Backup not found: $backup_date${NC}"
        exit 1
    fi
    
    local source_ws_id=$(find_workspace_by_path "$old_path" "$backup_storage")
    if [ -z "$source_ws_id" ]; then
        echo -e "${RED}❌ Could not find workspace for: $old_path${NC}"
        exit 1
    fi
    source_ws="$backup_storage/$source_ws_id"
    echo -e "${GREEN}✅ Found source workspace: $source_ws_id${NC}"
    
    # Find target workspace in current storage
    local target_ws_id=$(find_workspace_by_path "$new_path" "$CURSOR_STORAGE/workspaceStorage")
    if [ -z "$target_ws_id" ]; then
        echo -e "${RED}❌ Could not find workspace for: $new_path${NC}"
        exit 1
    fi
    local target_ws="$CURSOR_STORAGE/workspaceStorage/$target_ws_id"
    echo -e "${GREEN}✅ Found target workspace: $target_ws_id${NC}"
    echo ""
    
    migrate_workspace "$source_ws" "$target_ws"
}

# Main menu
case "${1:-help}" in
    "migrate")
        check_cursor_running
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 migrate <source_workspace_dir> <target_workspace_dir>"
            echo "Example: $0 migrate /path/to/source/workspace /path/to/target/workspace"
            exit 1
        fi
        migrate_workspace "$2" "$3"
        ;;
    "auto")
        check_cursor_running
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 auto <old_folder_path> <new_folder_path> [backup_date]"
            echo "Example: $0 auto 'CalEvent Generator' 'QuickCal'"
            echo "Example: $0 auto 'CalEvent Generator' 'QuickCal' 20251219_160000"
            exit 1
        fi
        auto_migrate "$2" "$3" "${4:-latest}"
        ;;
    "list-backups")
        list_backups
        ;;
    "list-workspaces")
        if [ -z "$2" ]; then
            echo "Listing current workspaces:"
            list_workspaces "$CURSOR_STORAGE/workspaceStorage"
        else
            backup_date="$2"
            echo "Listing workspaces in backup: $backup_date"
            list_workspaces "$BACKUP_DIR/$backup_date/workspaceStorage"
        fi
        ;;
    "find")
        if [ -z "$2" ]; then
            echo "Usage: $0 find <folder_path>"
            exit 1
        fi
        echo "Searching in current workspaces:"
        ws_id=$(find_workspace_by_path "$2" "$CURSOR_STORAGE/workspaceStorage")
        if [ -n "$ws_id" ]; then
            echo -e "${GREEN}✅ Found: $ws_id${NC}"
            echo "Full path: $CURSOR_STORAGE/workspaceStorage/$ws_id"
        else
            echo -e "${RED}❌ Workspace not found for: $2${NC}"
        fi
        ;;
    *)
        echo -e "${BLUE}🔄 Cursor Chat History Migration Tool${NC}"
        echo "====================================="
        echo ""
        echo "Usage:"
        echo "  $0 auto <old_path> <new_path> [backup_date]"
        echo "      Automatically migrate chat history between renamed folders"
        echo ""
        echo "  $0 migrate <source_ws_dir> <target_ws_dir>"
        echo "      Manually migrate between specific workspace directories"
        echo ""
        echo "  $0 list-backups"
        echo "      Show available backups"
        echo ""
        echo "  $0 list-workspaces [backup_date]"
        echo "      List all workspaces (current or from backup)"
        echo ""
        echo "  $0 find <folder_path>"
        echo "      Find workspace ID for a folder path"
        echo ""
        echo "Examples:"
        echo "  $0 auto 'Old Project' 'New Project'"
        echo "  $0 list-backups"
        echo "  $0 list-workspaces 20251219_160000"
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT: Close Cursor before running migration!${NC}"
        ;;
esac

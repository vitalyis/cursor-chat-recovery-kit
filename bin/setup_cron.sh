#!/bin/bash

echo "⏰ CURSOR BACKUP AUTOMATION SETUP"
echo "================================="

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_SCRIPT="$SCRIPT_DIR/export_cursor_chats.sh"
LOG_FILE="$HOME/cursor_backups/backup.log"

echo "📝 Setting up automated backups..."
echo ""

# Create cron job entry
CRON_ENTRY="0 */4 * * * $EXPORT_SCRIPT >> $LOG_FILE 2>&1"

echo "Proposed cron schedule:"
echo "  Every 4 hours: $CRON_ENTRY"
echo ""

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$EXPORT_SCRIPT"; then
    echo "⚠️  Cursor backup cron job already exists!"
    echo "Current cron jobs:"
    crontab -l 2>/dev/null | grep "cursor\|backup"
else
    echo "🔧 Adding cron job for automatic backups..."
    
    # Add to existing crontab
    (crontab -l 2>/dev/null || echo ""; echo "$CRON_ENTRY") | crontab -
    
    if [ $? -eq 0 ]; then
        echo "✅ Cron job added successfully!"
        echo "📅 Backups will run every 4 hours"
        echo "📄 Logs will be saved to: $LOG_FILE"
    else
        echo "❌ Failed to add cron job"
        exit 1
    fi
fi

echo ""
echo "🛠️  MANUAL COMMANDS:"
echo "View current cron jobs:  crontab -l"
echo "Edit cron jobs:         crontab -e"
echo "Remove backup cron:     crontab -l | grep -v '$EXPORT_SCRIPT' | crontab -"
echo ""
echo "📋 TEST COMMANDS:"
echo "Run manual backup:      $EXPORT_SCRIPT"
echo "Quick backup:           $SCRIPT_DIR/quick_backup.sh"
echo "View backup log:        tail -f $LOG_FILE"

# Create initial log file
touch "$LOG_FILE"
echo "$(date): Cursor backup automation setup completed" >> "$LOG_FILE"

echo ""
echo "✅ AUTOMATION SETUP COMPLETE!"

#!/bin/bash

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SESSION_LOG="$HOME/cursor_backups/session_log.txt"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "📝 CURSOR CHAT SESSION LOGGER"
echo "============================"

# Ensure log file exists
touch "$SESSION_LOG"

case "${1:-menu}" in
    "start")
        TOPIC="${2:-Development Session}"
        echo "[$TIMESTAMP] 🚀 START: $TOPIC" >> "$SESSION_LOG"
        echo "✅ Started logging session: $TOPIC"
        echo "💡 Remember to run: $0 end when finished"
        ;;
    
    "end")
        NOTES="${2:-Session completed}"
        echo "[$TIMESTAMP] 🏁 END: $NOTES" >> "$SESSION_LOG"
        echo "✅ Ended session with notes: $NOTES"
        
        # Optional: Trigger backup after important session
        read -p "🔄 Run backup now? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🔄 Running quick backup..."
            "$SCRIPT_DIR/quick_backup.sh"
        fi
        ;;
        
    "note")
        NOTE="${2:-Important milestone}"
        echo "[$TIMESTAMP] 📌 NOTE: $NOTE" >> "$SESSION_LOG"
        echo "✅ Added note: $NOTE"
        ;;
        
    "view")
        echo "📋 Recent session activity:"
        echo "=========================="
        tail -n 20 "$SESSION_LOG"
        ;;
        
    "today")
        echo "📅 Today's sessions:"
        echo "=================="
        grep "$(date '+%Y-%m-%d')" "$SESSION_LOG" | tail -n 20
        ;;
        
    *)
        echo "Usage:"
        echo "  $0 start [topic]     - Start logging a session"
        echo "  $0 end [notes]       - End session with notes"
        echo "  $0 note [text]       - Add quick note"
        echo "  $0 view             - View recent activity"
        echo "  $0 today            - View today's sessions"
        echo ""
        echo "Examples:"
        echo "  $0 start 'UI Improvements'"
        echo "  $0 note 'Fixed responsive layout'"
        echo "  $0 end 'Ready for testing'"
        ;;
esac

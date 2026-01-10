#!/bin/bash
# Setup convenient shell aliases for Cursor backup tools

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_RC=""

# Detect shell config file
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    echo "⚠️  Unknown shell. Please manually add aliases to your shell config."
    exit 1
fi

echo "🔧 Setting up Cursor backup tool aliases..."
echo "Shell config: $SHELL_RC"
echo ""

# Check if aliases already exist
if grep -q "# Cursor Backup Tools" "$SHELL_RC" 2>/dev/null; then
    echo "⚠️  Aliases already exist in $SHELL_RC"
    echo "Remove the '# Cursor Backup Tools' section and run again to update."
    exit 1
fi

# Add aliases to shell config
cat >> "$SHELL_RC" << EOF

# Cursor Backup Tools
# Added by setup_aliases.sh on $(date)
alias cursor-migrate='$SCRIPT_DIR/restore_chat_history.sh auto'
alias cursor-restore='$SCRIPT_DIR/restore_chat_history.sh'
alias cursor-emergency='$SCRIPT_DIR/emergency_recovery.sh'
alias cursor-backup='$SCRIPT_DIR/quick_backup.sh'
alias cursor-backups='$SCRIPT_DIR/restore_chat_history.sh list-backups'
alias cursor-workspaces='$SCRIPT_DIR/restore_chat_history.sh list-workspaces'
EOF

echo "✅ Aliases added to $SHELL_RC"
echo ""
echo "📋 Available commands:"
echo "  cursor-migrate 'OldName' 'NewName'  - Quickly migrate chat history"
echo "  cursor-restore [command]             - Access full migration tool"
echo "  cursor-emergency [command]           - Emergency recovery tool"
echo "  cursor-backup                        - Manual backup trigger"
echo "  cursor-backups                       - List available backups"
echo "  cursor-workspaces                    - List current workspaces"
echo ""
echo "🔄 Run 'source $SHELL_RC' or restart your terminal to use these commands."

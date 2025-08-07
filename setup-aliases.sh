#!/bin/bash
# setup-aliases.sh - Setup global aliases for n8n management scripts

PROJECT_DIR="/opt/n8n-automation"
ALIAS_FILE="$HOME/.bash_aliases"

echo "🔗 Setting up n8n management aliases..."

# Create aliases file if it doesn't exist
touch "$ALIAS_FILE"

# Remove existing n8n aliases
sed -i '/# n8n management aliases/,/# end n8n aliases/d' "$ALIAS_FILE"

# Add new aliases
cat >> "$ALIAS_FILE" << 'ALIASES'
# n8n management aliases
alias start-n8n='cd /opt/n8n-automation && ./start-n8n.sh'
alias stop-n8n='cd /opt/n8n-automation && ./stop-n8n.sh'
alias restart-n8n='cd /opt/n8n-automation && ./restart-n8n.sh'
alias status-n8n='cd /opt/n8n-automation && ./status.sh'
alias monitor-n8n='cd /opt/n8n-automation && ./monitor.sh'
alias backup-n8n='cd /opt/n8n-automation && ./backup.sh'
alias restore-n8n='cd /opt/n8n-automation && ./restore.sh'
alias cleanup-n8n='cd /opt/n8n-automation && ./cleanup.sh'
alias update-n8n='cd /opt/n8n-automation && ./update.sh'
alias logs-n8n='cd /opt/n8n-automation && ./logs.sh'
alias n8n-cd='cd /opt/n8n-automation'
# end n8n aliases
ALIASES

echo "✅ Aliases added to $ALIAS_FILE"
echo ""
echo "🔄 Reload your shell or run:"
echo "   source ~/.bash_aliases"
echo ""
echo "📋 Available aliases:"
echo "   start-n8n      # Start n8n"
echo "   stop-n8n       # Stop n8n"
echo "   restart-n8n    # Restart n8n"
echo "   status-n8n     # Check status"
echo "   monitor-n8n    # Live monitoring"
echo "   backup-n8n     # Create backup"
echo "   restore-n8n    # Restore backup"
echo "   cleanup-n8n    # Cleanup disk space"
echo "   update-n8n     # Update n8n"
echo "   logs-n8n       # View logs"
echo "   n8n-cd         # Go to n8n directory"
#!/bin/bash
# restart-n8n.sh - Restart n8n automation server

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

echo "🔄 Restarting n8n Automation Server..."

# Stop first
./stop-n8n.sh

# Wait a moment
echo "⏳ Waiting 5 seconds..."
sleep 5

# Start again
./start-n8n.sh

echo "✅ n8n restart completed!"
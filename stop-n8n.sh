#!/bin/bash
# stop-n8n.sh - Stop n8n automation server (Ubuntu Intel NUC)

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

echo "🛑 Stopping n8n Automation Server..."

# Check if running
if ! docker-compose ps | grep -q "Up"; then
    echo "ℹ️  n8n is already stopped"
    exit 0
fi

# Graceful shutdown with longer timeout for Intel NUC
echo "📋 Saving workflows and stopping gracefully..."
timeout 60s docker-compose stop || {
    echo "⚠️  Graceful stop timed out, forcing shutdown..."
    docker-compose kill
}

# Remove containers but keep volumes
docker-compose down

echo "✅ n8n stopped successfully"
echo "💾 All data preserved in Docker volumes"

# Log shutdown
echo "$(date): n8n stopped" >> logs/startup.log

echo ""
echo "💡 To restart: ./start-n8n.sh"
echo "💡 To check status: ./status.sh"
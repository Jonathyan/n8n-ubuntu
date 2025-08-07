#!/bin/bash
# start-n8n.sh - Start n8n automation server (Ubuntu Intel NUC)

set -e

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

echo "🚀 Starting n8n Automation Server (Intel NUC)"
echo "=============================================="

# Load environment
if [[ ! -f .env ]]; then
    echo "❌ .env file not found!"
    echo "📋 Run ./install.sh first or copy from .env.example"
    exit 1
fi

source .env

echo "🔍 Pre-flight System Check..."

# Check if Docker is running (Ubuntu 22.04 service management)
if ! systemctl is-active --quiet docker; then
    echo "❌ Docker service is not running"
    echo "🔧 Starting Docker service..."
    sudo systemctl start docker
    sleep 3
    
    if ! systemctl is-active --quiet docker; then
        echo "❌ Failed to start Docker service"
        echo "💡 Try: sudo systemctl status docker"
        exit 1
    fi
fi

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker daemon is not accessible"
    echo "💡 Try: sudo usermod -aG docker \"$USER\" && newgrp docker"
    exit 1
fi

# Intel NUC resource check (Ubuntu 22.04 tools)
total_mem=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
available_mem=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}' 2>/dev/null || free -m | awk '/^Mem:/{print $7}')
cpu_load=$(cat /proc/loadavg | awk '{print $1}')

echo "💾 System Resources (Ubuntu 22.04):"
echo "   Total Memory:     ${total_mem}MB"
echo "   Available Memory: ${available_mem}MB"
echo "   CPU Load:         ${cpu_load}"

# Check available memory (Intel NUC needs conservative limits)
if [ "$available_mem" -lt 1024 ]; then
    echo "⚠️  Low memory detected (${available_mem}MB available)"
    echo "💡 Intel NUC J3455 recommendation: Close unnecessary services"
    
    read -p "🤔 Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check disk space
available_disk=$(df /opt --output=avail -BM | tail -1 | tr -d 'M')
if [ "$available_disk" -lt 1024 ]; then
    echo "⚠️  Low disk space: ${available_disk}MB available"
    echo "💡 Consider running ./cleanup.sh"
fi

echo ""
echo "🐳 Docker Environment:"

# Create data directory if not exists
mkdir -p data

# Docker cleanup
echo "🧹 Cleaning up old containers..."
docker container prune -f >/dev/null 2>&1 || true

# Use Docker Compose V2 syntax (Ubuntu 22.04 default)
echo "📦 Updating n8n image..."
docker compose pull

# Start containers
echo "🏗️  Starting n8n container..."
docker compose up -d

# Health check with Intel NUC appropriate timing
echo "⏳ Waiting for n8n to become healthy..."
echo "   (Intel NUC startup may take longer than usual)"

max_wait=180  # 3 minutes for Intel NUC
waited=0

while [ "$waited" -lt "$max_wait" ]; do
    if docker compose ps | grep -q "healthy"; then
        echo "✅ n8n is running and healthy!"
        break
    elif docker compose ps | grep -q "unhealthy"; then
        echo "❌ n8n health check failed"
        echo "📋 Recent logs:"
        docker compose logs --tail=10
        exit 1
    elif [ "$waited" -eq "$max_wait" ]; then
        echo "❌ n8n failed to start in ${max_wait} seconds"
        echo "📋 Startup logs:"
        docker compose logs --tail=20
        exit 1
    fi
    
    if [ $((waited % 15)) -eq 0 ] && [ "$waited" -gt 0 ]; then
        container_status=$(docker compose ps --format="table {{.Status}}" | tail -1)
        echo "   Still waiting... (${waited}s) Status: $container_status"
    fi
    
    sleep 3
    waited=$((waited + 3))
done

# Post-startup system check
echo ""
echo "📊 Post-Startup Status:"
final_mem=$(free -m | awk '/^Mem:/{print $7}')
container_mem=$(docker stats n8n-automation --no-stream --format "{{.MemUsage}}" 2>/dev/null || echo "unknown")

echo "   Available Memory: ${final_mem}MB (was ${available_mem}MB)"
echo "   Container Memory: $container_mem"

# Network info
ip_address=$(hostname -I | awk '{print $1}')
echo "   Server IP:        $ip_address"

# Success message
echo ""
echo "🎉 n8n Automation Server Ready!"
echo "==============================="
echo "🌐 Local Access:     http://localhost:${N8N_PORT:-5678}"
echo "🌐 Network Access:   http://$ip_address:${N8N_PORT:-5678}"
echo "👤 Username:         ${N8N_BASIC_AUTH_USER}"
echo "🔐 Password:         $(echo "${N8N_BASIC_AUTH_PASSWORD}" | sed 's/./*/g')"
echo ""
echo "🔧 Intel NUC Optimizations Active:"
echo "   • Memory Limit:   ${CONTAINER_MEMORY_LIMIT:-2g}"
echo "   • CPU Limit:      ${CONTAINER_CPU_LIMIT:-2.0} cores"
echo "   • Payload Size:   ${N8N_PAYLOAD_SIZE_MAX:-8}MB"
echo "   • Timeout:        ${EXECUTIONS_TIMEOUT:-180}s"
echo ""
echo "💡 Management Commands:"
echo "   ./status.sh         # Check status & resources"
echo "   ./stop-n8n.sh       # Stop n8n"
echo "   ./backup.sh         # Create backup"
echo "   ./logs.sh           # View logs"
echo "   ./monitor.sh        # Resource monitor"
echo ""
echo "🌟 Ready for automation workflows!"

# Log startup
echo "$(date): n8n started successfully" >> logs/startup.log
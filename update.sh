#!/bin/bash
# update.sh - Update n8n to latest version (Ubuntu 22.04 Intel NUC)

set -e

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

echo "⬆️ n8n Update Utility (Ubuntu 22.04)"
echo "====================================="

# Load environment
if [[ -f .env ]]; then
    source .env
    RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
else
    RETENTION_DAYS=30
    echo "⚠️  No .env file found, using defaults"
fi

# Check if we're in the right directory
if [[ ! -f docker-compose.yml ]]; then
    echo "❌ docker-compose.yml not found"
    echo "💡 Run from n8n installation directory"
    exit 1
fi

# Pre-update system check
echo ""
echo "🔍 Pre-update System Check..."

# Check available disk space
available_space=$(df /opt --output=avail -BM | tail -1 | tr -d 'M')
if [ "$available_space" -lt 2048 ]; then
    echo "⚠️  Low disk space: ${available_space}MB available"
    echo "💡 Recommended: 2GB+ free space for safe update"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# Check memory
available_mem=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}' 2>/dev/null || free -m | awk '/^Mem:/{print $7}')
if [ "$available_mem" -lt 1024 ]; then
    echo "⚠️  Low memory: ${available_mem}MB available"
    echo "💡 Consider stopping other services during update"
fi

# Check current n8n status
echo ""
echo "📊 Current n8n Status:"
if docker compose ps | grep -q "Up"; then
    current_version=$(docker compose exec -T n8n n8n --version 2>/dev/null | head -1 || echo "unknown")
    uptime_info=$(docker compose ps --format="{{.Status}}" | grep "Up" | head -1)
    
    echo "   Status:           ✅ Running"
    echo "   Version:          $current_version"
    echo "   Uptime:           $uptime_info"
    
    n8n_was_running=true
else
    echo "   Status:           ❌ Stopped"
    current_version="unknown (not running)"
    n8n_was_running=false
fi

# Check for available updates
echo ""
echo "🔍 Checking for updates..."
echo "   Current version:   $current_version"

# Pull latest image info without downloading
latest_digest=$(docker manifest inspect n8nio/n8n:latest 2>/dev/null | grep -o '"digest":"[^"]*' | cut -d'"' -f4 || echo "unknown")
current_digest=$(docker inspect n8nio/n8n:latest 2>/dev/null | grep -o '"Id":"[^"]*' | cut -d'"' -f4 || echo "none")

if [[ "$latest_digest" != "unknown" && "$current_digest" != "none" ]]; then
    if [[ "$latest_digest" == "$current_digest" ]]; then
        echo "   Latest version:    ✅ Already up to date"
        echo ""
        read -p "🤔 Update anyway to ensure latest version? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    else
        echo "   Latest version:    🆕 Update available"
    fi
else
    echo "   Latest version:    ❓ Unable to check (will update anyway)"
fi

# Safety confirmation
echo ""
echo "⚠️  Update Process Overview:"
echo "   1. Create pre-update backup"
echo "   2. Pull latest n8n image"
echo "   3. Stop current container"
echo "   4. Start with new image"
echo "   5. Verify successful startup"
echo "   6. Run post-update checks"
echo ""
read -p "🚀 Proceed with update? (y/N): " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 0

# Step 1: Create pre-update backup
echo ""
echo "1️⃣ Creating Pre-Update Backup..."
echo "==============================="

backup_name="pre_update_$(date +%Y%m%d_%H%M%S)"
echo "   Backup name: $backup_name"

if [[ -x ./backup.sh ]]; then
    # Use our backup script
    ./backup.sh
    
    # Move to update-specific location
    latest_backup=$(find backups -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    if [[ -f "$latest_backup" ]]; then
        cp "$latest_backup" "backups/${backup_name}.tar.gz"
        echo "   ✅ Pre-update backup created: ${backup_name}.tar.gz"
    else
        echo "   ⚠️  Backup script completed but file not found"
    fi
else
    # Manual backup
    echo "   Creating manual backup..."
    
    temp_backup_dir="/tmp/n8n_update_backup_$$"
    mkdir -p "$temp_backup_dir"
    
    # Copy essential files
    cp .env "$temp_backup_dir/" 2>/dev/null || true
    cp docker-compose.yml "$temp_backup_dir/" 2>/dev/null || true
    cp -r data "$temp_backup_dir/" 2>/dev/null || true
    
    # Create backup archive
    mkdir -p backups
    tar -czf "backups/${backup_name}.tar.gz" -C "$temp_backup_dir" . 2>/dev/null
    rm -rf "$temp_backup_dir"
    
    echo "   ✅ Manual backup created"
fi

# Step 2: Pull latest image
echo ""
echo "2️⃣ Pulling Latest n8n Image..."
echo "==============================="

echo "   Downloading latest n8n image..."
if docker compose pull; then
    echo "   ✅ Latest image downloaded"
else
    echo "   ❌ Failed to pull latest image"
    exit 1
fi

# Get new version info
new_image_id=$(docker images n8nio/n8n:latest --format "{{.ID}}" | head -1)
echo "   New image ID: $new_image_id"

# Step 3: Stop current container (if running)
echo ""
echo "3️⃣ Stopping Current Container..."
echo "================================"

if [[ "$n8n_was_running" == "true" ]]; then
    echo "   Gracefully stopping n8n..."
    
    # Use our stop script if available
    if [[ -x ./stop-n8n.sh ]]; then
        ./stop-n8n.sh
    else
        # Manual stop
        timeout 60s docker compose stop || {
            echo "   ⚠️  Graceful stop timed out, forcing..."
            docker compose kill
        }
        docker compose down
    fi
    
    echo "   ✅ Container stopped"
else
    echo "   ℹ️  Container was already stopped"
fi

# Step 4: Start with new image
echo ""
echo "4️⃣ Starting with New Image..."
echo "============================="

echo "   Starting n8n with updated image..."

# Use our start script if available
if [[ -x ./start-n8n.sh ]]; then
    echo "   Using start-n8n.sh script..."
    ./start-n8n.sh
else
    # Manual start
    echo "   Manual container start..."
    
    # Create data directory if not exists
    mkdir -p data
    
    # Start container
    docker compose up -d
    
    # Wait for health check
    echo "   Waiting for n8n to become healthy..."
    max_wait=180
    waited=0
    
    while [ "$waited" -lt "$max_wait" ]; do
        if docker compose ps | grep -q "healthy"; then
            echo "   ✅ n8n is running and healthy!"
            break
        elif docker compose ps | grep -q "unhealthy"; then
            echo "   ❌ n8n health check failed"
            docker compose logs --tail=10
            exit 1
        elif [ "$waited" -eq "$max_wait" ]; then
            echo "   ❌ n8n failed to start in ${max_wait} seconds"
            docker compose logs --tail=20
            exit 1
        fi
        
        if [ $((waited % 30)) -eq 0 ] && [ "$waited" -gt 0 ]; then
            echo "   Still waiting... (${waited}s)"
        fi
        
        sleep 3
        waited=$((waited + 3))
    done
fi

# Step 5: Verify successful startup
echo ""
echo "5️⃣ Verifying Update Success..."
echo "=============================="

# Check new version
if docker compose ps | grep -q "Up"; then
    new_version=$(docker compose exec -T n8n n8n --version 2>/dev/null | head -1 || echo "unknown")
    echo "   New version:      $new_version"
    
    # Compare versions
    if [[ "$current_version" != "$new_version" && "$new_version" != "unknown" ]]; then
        echo "   ✅ Version updated successfully!"
        version_changed=true
    elif [[ "$new_version" != "unknown" ]]; then
        echo "   ✅ Version verified (may be same as before)"
        version_changed=false
    else
        echo "   ⚠️  Unable to verify new version"
        version_changed=false
    fi
    
    # Check container health
    container_health=$(docker compose ps --format="{{.Status}}" | head -1)
    echo "   Container status: $container_health"
    
    # Check web interface
    ip_address=$(hostname -I | awk '{print $1}')
    echo "   Web interface:    http://$ip_address:${N8N_PORT:-5678}"
    
else
    echo "   ❌ n8n is not running after update"
    echo "   📋 Recent logs:"
    docker compose logs --tail=15
    
    echo ""
    echo "🔄 Rollback Options:"
    echo "   1. Restore from backup: ./restore.sh $backup_name"
    echo "   2. Check logs: ./logs.sh"
    echo "   3. Manual restart: ./start-n8n.sh"
    exit 1
fi

# Step 6: Post-update checks
echo ""
echo "6️⃣ Post-Update System Check..."
echo "=============================="

# Resource usage after update
final_mem=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}' 2>/dev/null || free -m | awk '/^Mem:/{print $7}')
container_mem=$(docker stats n8n-automation --no-stream --format "{{.MemUsage}}" 2>/dev/null || echo "unknown")

echo "   Available memory: ${final_mem}MB"
echo "   Container memory: $container_mem"

# Disk usage check
final_space=$(df /opt --output=avail -BM | tail -1 | tr -d 'M')
echo "   Available disk:   ${final_space}MB"

# Docker cleanup recommendation
old_images=$(docker images -f "dangling=true" -q | wc -l)
if [ "$old_images" -gt 0 ]; then
    echo "   Old images:       $old_images (cleanup with: docker image prune -f)"
fi

# Success summary
echo ""
echo "🎉 Update Completed Successfully!"
echo "================================"
echo "📊 Update Summary:"
echo "   Previous version: $current_version"
echo "   New version:      $new_version"

if [[ "$version_changed" == "true" ]]; then
    echo "   Status:           ✅ Version updated"
else
    echo "   Status:           ✅ System refreshed"
fi

echo "   Backup location:  backups/${backup_name}.tar.gz"
echo "   Update time:      $(date)"

echo ""
echo "🌐 Access n8n:"
echo "   Local:            http://localhost:${N8N_PORT:-5678}"
echo "   Network:          http://$ip_address:${N8N_PORT:-5678}"
echo "   Username:         ${N8N_BASIC_AUTH_USER:-admin}"

echo ""
echo "🔧 Post-Update Actions:"
echo "   • Test your workflows"
echo "   • Check credentials and connections"
echo "   • Verify scheduled automations"
echo "   • Run backup: ./backup.sh"

echo ""
echo "💡 Troubleshooting:"
echo "   • View logs:      ./logs.sh"
echo "   • Check status:   ./status.sh"
echo "   • Monitor:        ./monitor.sh"
echo "   • Rollback:       ./restore.sh $backup_name"

# Log the update
echo "$(date): n8n updated from '$current_version' to '$new_version'" >> logs/startup.log

echo ""
echo "✨ n8n update completed successfully!"
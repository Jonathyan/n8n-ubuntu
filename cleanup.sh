#!/bin/bash
# cleanup.sh - Comprehensive cleanup utility for Ubuntu 22.04 Intel NUC

set -e

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

echo "🧹 n8n Cleanup Utility (Ubuntu 22.04)"
echo "======================================"

# Load environment
if [[ -f .env ]]; then
    source .env
    RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
else
    RETENTION_DAYS=30
fi

# Function to show disk usage
show_disk_usage() {
    echo "💽 Current Disk Usage:"
    df -h /opt | awk 'NR==2 {printf "   Total: %s | Used: %s (%s) | Free: %s\n", $2, $3, $5, $4}'
}

# Function to calculate directory sizes
show_directory_sizes() {
    echo "📊 Directory Sizes:"
    if [[ -d data ]]; then
        data_size=$(du -sh data 2>/dev/null | cut -f1)
        echo "   n8n data:         $data_size"
    fi
    
    if [[ -d backups ]]; then
        backup_size=$(du -sh backups 2>/dev/null | cut -f1)
        backup_count=$(find backups -name "*.tar.gz" 2>/dev/null | wc -l)
        echo "   Backups:          $backup_size ($backup_count files)"
    fi
    
    if [[ -d logs ]]; then
        logs_size=$(du -sh logs 2>/dev/null | cut -f1)
        echo "   Logs:             $logs_size"
    fi
    
    # Docker usage
    docker_size=$(docker system df --format "table {{.Type}}\t{{.Size}}\t{{.Reclaimable}}" 2>/dev/null | grep -E "Images|Containers|Local Volumes|Build Cache" | awk '{size+=$2; reclaimable+=$3} END {printf "%.1fGB total, %.1fGB reclaimable", size, reclaimable}' || echo "unknown")
    echo "   Docker:           $docker_size"
}

# Show current status
echo ""
show_disk_usage
echo ""
show_directory_sizes

# Get available space
available_space=$(df /opt --output=avail -BM | tail -1 | tr -d 'M')
disk_percent=$(df /opt --output=pcent | tail -1 | tr -d ' %')

echo ""
echo "🎯 Cleanup Targets:"

# Determine what needs cleaning
cleanup_needed=false

# Check old backups
old_backups=$(find backups -name "*.tar.gz" -mtime +"$RETENTION_DAYS" 2>/dev/null | wc -l)
if [ "$old_backups" -gt 0 ]; then
    echo "   📦 Old backups (>$RETENTION_DAYS days): $old_backups files"
    cleanup_needed=true
fi

# Check Docker reclaimable space
docker_reclaimable=$(docker system df --format "{{.Reclaimable}}" 2>/dev/null | head -1 | grep -o '[0-9.]*' | head -1 || echo "0")
if (( $(echo "$docker_reclaimable > 0.5" | bc -l 2>/dev/null || echo 0) )); then
    echo "   🐳 Docker cleanup: ${docker_reclaimable}GB reclaimable"
    cleanup_needed=true
fi

# Check large log files
large_logs=$(find logs -name "*.log" -size +50M 2>/dev/null | wc -l)
if [ "$large_logs" -gt 0 ]; then
    echo "   📋 Large log files (>50MB): $large_logs files"
    cleanup_needed=true
fi

# Check temporary files
temp_files=$(find /tmp -name "*n8n*" -o -name "*docker*" 2>/dev/null | wc -l)
if [ "$temp_files" -gt 0 ]; then
    echo "   🗂️  Temporary files: $temp_files files"
    cleanup_needed=true
fi

# Check for stopped containers
stopped_containers=$(docker ps -a --filter "status=exited" --format "{{.ID}}" | wc -l)
if [ "$stopped_containers" -gt 0 ]; then
    echo "   📦 Stopped containers: $stopped_containers containers"
    cleanup_needed=true
fi

if [[ "$cleanup_needed" == "false" ]]; then
    echo "   ✅ No cleanup needed - system is clean!"
    echo ""
    echo "💡 Maintenance suggestions:"
    echo "   • Current disk usage: $disk_percent%"
    echo "   • Available space: ${available_space}MB"
    echo "   • Everything looks good!"
    exit 0
fi

# Show cleanup options
echo ""
echo "🛠️  Cleanup Options:"
echo "   1. Quick cleanup (safe)"
echo "   2. Deep cleanup (aggressive)"
echo "   3. Docker cleanup only"
echo "   4. Backup cleanup only"
echo "   5. Log cleanup only"
echo "   6. Custom cleanup"
echo "   7. Show details only"
echo "   q. Quit"

echo ""
read -p "Select cleanup type (1-7, q): " -n 1 -r
echo

case $REPLY in
    1)
        CLEANUP_TYPE="quick"
        ;;
    2)
        CLEANUP_TYPE="deep"
        ;;
    3)
        CLEANUP_TYPE="docker"
        ;;
    4)
        CLEANUP_TYPE="backup"
        ;;
    5)
        CLEANUP_TYPE="logs"
        ;;
    6)
        CLEANUP_TYPE="custom"
        ;;
    7)
        CLEANUP_TYPE="details"
        ;;
    q|Q)
        echo "👋 Cleanup cancelled"
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

# Show details only
if [[ "$CLEANUP_TYPE" == "details" ]]; then
    echo ""
    echo "🔍 Detailed Cleanup Analysis:"
    echo "============================"
    
    echo ""
    echo "📦 Backup Analysis:"
    if [[ -d backups ]]; then
        echo "   All backups:"
        find backups -name "*.tar.gz" -exec ls -lh {} \; 2>/dev/null | awk '{print "      " $9 " (" $5 ", " $6 " " $7 ")"}'
        echo ""
        echo "   Old backups (>$RETENTION_DAYS days):"
        find backups -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -exec ls -lh {} \; 2>/dev/null | awk '{print "      " $9 " (" $5 ", " $6 " " $7 ")"}' || echo "      None found"
    else
        echo "   No backup directory found"
    fi
    
    echo ""
    echo "🐳 Docker Analysis:"
    docker system df -v 2>/dev/null | sed 's/^/   /' || echo "   Unable to get Docker info"
    
    echo ""
    echo "📋 Log Analysis:"
    if [[ -d logs ]]; then
        find logs -name "*.log" -exec ls -lh {} \; 2>/dev/null | awk '{print "   " $9 " (" $5 ", " $6 " " $7 ")"}'
    else
        echo "   No logs directory found"
    fi
    
    echo ""
    echo "📊 System Analysis:"
    echo "   Disk usage: $disk_percent%"
    echo "   Available:  ${available_space}MB"
    
    # Intel NUC specific recommendations
    echo ""
    echo "💡 Intel NUC (120GB SSD) Recommendations:"
    if [ "$disk_percent" -gt 85 ]; then
        echo "   🔴 CRITICAL: >85% disk usage - immediate cleanup needed"
    elif [ "$disk_percent" -gt 70 ]; then
        echo "   🟡 WARNING: >70% disk usage - cleanup recommended"
    else
        echo "   ✅ HEALTHY: <70% disk usage - regular maintenance sufficient"
    fi
    
    exit 0
fi

# Confirmation for destructive operations
if [[ "$CLEANUP_TYPE" != "details" ]]; then
    echo ""
    echo "⚠️  Cleanup will:"
    
    case $CLEANUP_TYPE in
        "quick")
            echo "   • Remove old backups (>$RETENTION_DAYS days)"
            echo "   • Clean Docker cache and unused images"
            echo "   • Rotate large log files"
            echo "   • Clean temporary files"
            ;;
        "deep")
            echo "   • All quick cleanup actions"
            echo "   • Remove ALL unused Docker resources"
            echo "   • Truncate all log files"
            echo "   • Clean system package cache"
            ;;
        "docker")
            echo "   • Remove unused Docker images"
            echo "   • Remove unused Docker containers"
            echo "   • Remove unused Docker volumes"
            echo "   • Clean Docker build cache"
            ;;
        "backup")
            echo "   • Remove old backups (>$RETENTION_DAYS days)"
            echo "   • Compress recent backups if possible"
            ;;
        "logs")
            echo "   • Rotate large log files (>50MB)"
            echo "   • Clean old Docker logs"
            echo "   • Truncate system logs if needed"
            ;;
        "custom")
            echo "   • Interactive selection of cleanup actions"
            ;;
    esac
    
    echo ""
    read -p "🤔 Proceed with cleanup? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# Record initial disk usage
initial_usage=$(df /opt --output=used -BM | tail -1 | tr -d 'M')

echo ""
echo "🧹 Performing Cleanup..."
echo "======================="

# Custom cleanup - interactive selection
if [[ "$CLEANUP_TYPE" == "custom" ]]; then
    echo ""
    echo "Select cleanup actions (y/n for each):"
    
    read -p "   Remove old backups (>$RETENTION_DAYS days)? (y/N): " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && CLEAN_BACKUPS=true || CLEAN_BACKUPS=false
    
    read -p "   Clean Docker resources? (y/N): " -n 1 -r; echo  
    [[ $REPLY =~ ^[Yy]$ ]] && CLEAN_DOCKER=true || CLEAN_DOCKER=false
    
    read -p "   Clean log files? (y/N): " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && CLEAN_LOGS=true || CLEAN_LOGS=false
    
    read -p "   Clean temporary files? (y/N): " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && CLEAN_TEMP=true || CLEAN_TEMP=false
else
    # Set cleanup flags based on type
    case $CLEANUP_TYPE in
        "quick")
            CLEAN_BACKUPS=true
            CLEAN_DOCKER=true
            CLEAN_LOGS=true
            CLEAN_TEMP=true
            AGGRESSIVE=false
            ;;
        "deep")
            CLEAN_BACKUPS=true
            CLEAN_DOCKER=true
            CLEAN_LOGS=true
            CLEAN_TEMP=true
            AGGRESSIVE=true
            ;;
        "docker")
            CLEAN_BACKUPS=false
            CLEAN_DOCKER=true
            CLEAN_LOGS=false
            CLEAN_TEMP=false
            AGGRESSIVE=false
            ;;
        "backup")
            CLEAN_BACKUPS=true
            CLEAN_DOCKER=false
            CLEAN_LOGS=false
            CLEAN_TEMP=false
            AGGRESSIVE=false
            ;;
        "logs")
            CLEAN_BACKUPS=false
            CLEAN_DOCKER=false
            CLEAN_LOGS=true
            CLEAN_TEMP=false
            AGGRESSIVE=false
            ;;
    esac
fi

# Cleanup functions
cleanup_backups() {
    echo "📦 Cleaning old backups..."
    
    local removed=0
    local saved_space=0
    
    # Remove backups older than retention period
    while IFS= read -r -d '' backup; do
        size=$(du -m "$backup" | cut -f1)
        rm "$backup"
        removed=$((removed + 1))
        saved_space=$((saved_space + size))
    done < <(find backups -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -print0 2>/dev/null)
    
    if [ $removed -gt 0 ]; then
        echo "   ✅ Removed $removed old backups (${saved_space}MB)"
    else
        echo "   ℹ️  No old backups to remove"
    fi
    
    # Compress uncompressed backups if any
    if find backups -name "*.json" -o -name "*.sql" >/dev/null 2>&1; then
        echo "   🗜️  Compressing uncompressed backups..."
        find backups -name "*.json" -o -name "*.sql" | while read -r file; do
            gzip "$file" 2>/dev/null && echo "      Compressed $(basename "$file")"
        done
    fi
}

cleanup_docker() {
    echo "🐳 Cleaning Docker resources..."
    
    # Stop n8n temporarily if running (for safe cleanup)
    n8n_was_running=false
    if docker compose ps | grep -q "Up"; then
        echo "   🛑 Temporarily stopping n8n for safe cleanup..."
        docker compose stop
        n8n_was_running=true
    fi
    
    # Remove stopped containers
    stopped=$(docker ps -aq --filter "status=exited" | wc -l)
    if [ "$stopped" -gt 0 ]; then
        docker container prune -f >/dev/null 2>&1
        echo "   ✅ Removed $stopped stopped containers"
    fi
    
    # Remove unused images
    if [[ "$AGGRESSIVE" == "true" ]]; then
        # Remove ALL unused images
        unused_images=$(docker images -q --filter "dangling=true" | wc -l)
        if [ "$unused_images" -gt 0 ]; then
            docker image prune -af >/dev/null 2>&1
            echo "   ✅ Removed $unused_images unused images (aggressive)"
        fi
    else
        # Remove only dangling images
        dangling=$(docker images -q --filter "dangling=true" | wc -l)
        if [ "$dangling" -gt 0 ]; then
            docker image prune -f >/dev/null 2>&1
            echo "   ✅ Removed $dangling dangling images"
        fi
    fi
    
    # Remove unused volumes
    unused_volumes=$(docker volume ls -qf dangling=true | wc -l)
    if [ "$unused_volumes" -gt 0 ]; then
        docker volume prune -f >/dev/null 2>&1
        echo "   ✅ Removed $unused_volumes unused volumes"
    fi
    
    # Clean build cache
    docker builder prune -f >/dev/null 2>&1
    echo "   ✅ Cleaned Docker build cache"
    
    # Restart n8n if it was running
    if [[ "$n8n_was_running" == "true" ]]; then
        echo "   🚀 Restarting n8n..."
        docker compose up -d >/dev/null 2>&1
        sleep 5
        
        if docker compose ps | grep -q "Up"; then
            echo "   ✅ n8n restarted successfully"
        else
            echo "   ⚠️  n8n restart may need attention"
        fi
    fi
}

cleanup_logs() {
    echo "📋 Cleaning log files..."
    
    local cleaned=0
    
    # Clean large application logs
    if [[ -d logs ]]; then
        find logs -name "*.log" -size +50M | while read -r logfile; do
            # Keep last 1000 lines
            tail -1000 "$logfile" > "${logfile}.tmp"
            mv "${logfile}.tmp" "$logfile"
            cleaned=$((cleaned + 1))
            echo "   📝 Rotated $(basename "$logfile")"
        done
    fi
    
    # Clean Docker container logs
    if docker ps -q >/dev/null 2>&1; then
        docker ps -q | while read -r container; do
            container_name=$(docker inspect --format='{{.Name}}' "$container" | sed 's/^.//')
            log_size=$(docker logs "$container" 2>&1 | wc -c)
            
            if [ "$log_size" -gt 52428800 ]; then  # 50MB
                # Truncate container logs (keep last 1000 lines)
                docker logs --tail=1000 "$container" 2>/dev/null | docker exec -i "$container" sh -c 'cat > /proc/1/fd/1' 2>/dev/null || true
                echo "   🐳 Rotated logs for $container_name"
                cleaned=$((cleaned + 1))
            fi
        done
    fi
    
    if [[ "$AGGRESSIVE" == "true" ]]; then
        # Aggressive: truncate all logs
        find logs -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null && echo "   🗑️  Truncated all log files (aggressive mode)"
    fi
    
    if [ $cleaned -gt 0 ]; then
        echo "   ✅ Cleaned $cleaned log files"
    else
        echo "   ℹ️  No large log files to clean"
    fi
}

cleanup_temp() {
    echo "🗂️  Cleaning temporary files..."
    
    local removed=0
    
    # Clean system temp files related to n8n/docker
    find /tmp -name "*n8n*" -o -name "*docker*" -type f -mtime +1 2>/dev/null | while read -r tmpfile; do
        rm "$tmpfile" 2>/dev/null && removed=$((removed + 1))
    done
    
    # Clean package manager cache (Ubuntu 22.04)
    if [[ "$AGGRESSIVE" == "true" ]]; then
        sudo apt clean >/dev/null 2>&1
        echo "   ✅ Cleaned apt package cache"
    fi
    
    # Clean npm cache if present
    if command -v npm >/dev/null 2>&1; then
        npm cache clean --force >/dev/null 2>&1
        echo "   ✅ Cleaned npm cache"
    fi
    
    if [ $removed -gt 0 ]; then
        echo "   ✅ Removed $removed temporary files"
    else
        echo "   ℹ️  No temporary files to clean"
    fi
}

# Execute cleanup functions
[[ "$CLEAN_BACKUPS" == "true" ]] && cleanup_backups
[[ "$CLEAN_DOCKER" == "true" ]] && cleanup_docker  
[[ "$CLEAN_LOGS" == "true" ]] && cleanup_logs
[[ "$CLEAN_TEMP" == "true" ]] && cleanup_temp

# Calculate space saved
final_usage=$(df /opt --output=used -BM | tail -1 | tr -d 'M')
space_saved=$((initial_usage - final_usage))

echo ""
echo "🎉 Cleanup Completed!"
echo "===================="
show_disk_usage

if [ "$space_saved" -gt 0 ]; then
    echo "💾 Space saved: ${space_saved}MB"
else
    echo "💾 Space saved: Minimal (system was already clean)"
fi

# Final recommendations
final_disk_percent=$(df /opt --output=pcent | tail -1 | tr -d ' %')
echo ""
echo "📊 Final Status:"
echo "   Disk usage: ${final_disk_percent}%"
echo "   Available:  $(df /opt --output=avail -BM | tail -1 | tr -d 'M')MB"

if [ "$final_disk_percent" -gt 80 ]; then
    echo ""
    echo "⚠️  Still high disk usage. Consider:"
    echo "   • Moving old backups to external storage"
    echo "   • Reducing backup retention period"
    echo "   • Checking for large workflows/data"
fi

echo ""
echo "💡 Maintenance Schedule:"
echo "   • Weekly:  ./cleanup.sh (quick cleanup)"
echo "   • Monthly: ./cleanup.sh (deep cleanup)"
echo "   • Monitor: ./status.sh (check disk usage)"

echo ""
echo "✨ Cleanup completed successfully!"

# Log cleanup
echo "$(date): Cleanup completed - ${space_saved}MB saved" >> logs/startup.log
#!/bin/bash
# status.sh - Comprehensive status check for Intel NUC

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR" 2>/dev/null || {
    echo "❌ n8n not installed in $PROJECT_DIR"
    exit 1
}

# Load environment
if [[ -f .env ]]; then
    source .env
fi

echo "📊 n8n Status Report (Intel NUC)"
echo "================================="

# System Information
echo ""
echo "🖥️  Intel NUC System Info:"
cpu_model=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
cpu_cores=$(nproc)
cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
temp=$(sensors 2>/dev/null | grep "Core 0" | awk '{print $3}' | head -1 || echo "N/A")

echo "   CPU:              $cpu_model"
echo "   Cores:            $cpu_cores"
echo "   Load Average:     $cpu_load"
echo "   Temperature:      $temp"

# Memory Status
total_mem=$(free -m | awk '/^Mem:/{print $2}')
used_mem=$(free -m | awk '/^Mem:/{print $3}')
available_mem=$(free -m | awk '/^Mem:/{print $7}')
mem_percent=$(( (used_mem * 100) / total_mem ))

echo ""
echo "💾 Memory Status:"
echo "   Total:            ${total_mem}MB"
echo "   Used:             ${used_mem}MB (${mem_percent}%)"
echo "   Available:        ${available_mem}MB"

# Disk Status
disk_total=$(df /opt --output=size -BG | tail -1 | tr -d 'G')
disk_used=$(df /opt --output=used -BG | tail -1 | tr -d 'G')
disk_avail=$(df /opt --output=avail -BG | tail -1 | tr -d 'G')
disk_percent=$(df /opt --output=pcent | tail -1 | tr -d ' %')

echo ""
echo "💽 Storage Status (120GB SSD):"
echo "   Total:            ${disk_total}GB"
echo "   Used:             ${disk_used}GB (${disk_percent}%)"
echo "   Available:        ${disk_avail}GB"

# n8n Container Status
echo ""
echo "🐳 n8n Container Status:"

if docker-compose ps | grep -q "Up"; then
    health_status=$(docker-compose ps --format="table {{.Status}}" | tail -1)
    uptime_info=$(docker-compose ps --format="table {{.Status}}" | tail -1 | grep -o "Up [^)]*")
    
    echo "   Status:           ✅ Running ($health_status)"
    echo "   Uptime:           $uptime_info"
    
    # Container resources
    if docker stats n8n-automation --no-stream >/dev/null 2>&1; then
        container_stats=$(docker stats n8n-automation --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}")
        IFS=$'\t' read -r cpu_perc mem_usage mem_perc net_io block_io <<< "$container_stats"
        
        echo "   CPU Usage:        $cpu_perc"
        echo "   Memory Usage:     $mem_usage ($mem_perc of limit)"
        echo "   Network I/O:      $net_io"
        echo "   Disk I/O:         $block_io"
    fi
    
    # Service URL
    ip_address=$(hostname -I | awk '{print $1}')
    echo "   Web Interface:    http://$ip_address:${N8N_PORT:-5678}"
    
else
    echo "   Status:           ❌ Stopped"
    echo "   💡 Start with:    ./start-n8n.sh"
fi

# Docker Status
echo ""
echo "🐳 Docker Environment:"
docker_version=$(docker --version | awk '{print $3}' | tr -d ',')
docker_compose_version=$(docker-compose --version | awk '{print $3}' | tr -d ',')

echo "   Docker:           $docker_version"
echo "   Docker Compose:   $docker_compose_version"

# Check Docker system resources
docker_system_df=$(docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}" 2>/dev/null || echo "Unable to get Docker info")
if [[ "$docker_system_df" != "Unable to get Docker info" ]]; then
    echo "   System Usage:"
    echo "$docker_system_df" | sed 's/^/      /'
fi

# Configuration Status
echo ""
echo "🔧 Configuration:"
if [[ -f .env ]]; then
    env_vars=$(grep -c "^[^#].*=" .env 2>/dev/null || echo 0)
    echo "   Environment:      ✅ .env file present ($env_vars variables)"
    
    # Show key settings
    echo "   Host:             ${N8N_HOST:-not-set}"
    echo "   Port:             ${N8N_PORT:-not-set}"
    echo "   Memory Limit:     ${CONTAINER_MEMORY_LIMIT:-not-set}"
    echo "   CPU Limit:        ${CONTAINER_CPU_LIMIT:-not-set}"
else
    echo "   Environment:      ❌ .env file missing"
    echo "   💡 Create from:    cp .env.example .env"
fi

# Network Status
echo ""
echo "🌐 Network Status:"
ip_address=$(hostname -I | awk '{print $1}')
gateway=$(ip route | grep default | awk '{print $3}' | head -1)

echo "   Local IP:         $ip_address"
echo "   Gateway:          $gateway"

# Port check
if command -v netstat >/dev/null 2>&1; then
    port_status=$(netstat -tlnp 2>/dev/null | grep ":${N8N_PORT:-5678}" || echo "Not listening")
    if [[ "$port_status" == "Not listening" ]]; then
        echo "   Port Status:      ❌ Port ${N8N_PORT:-5678} not open"
    else
        echo "   Port Status:      ✅ Port ${N8N_PORT:-5678} listening"
    fi
fi

# Recent Activity
echo ""
echo "📋 Recent Activity:"
if [[ -f logs/startup.log ]]; then
    echo "   Startup Log:"
    tail -3 logs/startup.log | sed 's/^/      /'
else
    echo "   No startup logs found"
fi

# Health Warnings for Intel NUC
echo ""
echo "⚠️  Intel NUC Health Check:"

# Memory warning
if [ $mem_percent -gt 80 ]; then
    echo "   🔴 HIGH MEMORY USAGE: ${mem_percent}%"
    echo "      Consider reducing container limits or closing services"
elif [ $mem_percent -gt 60 ]; then
    echo "   🟡 MODERATE MEMORY USAGE: ${mem_percent}%"
    echo "      Monitor memory usage during heavy workflows"
else
    echo "   ✅ Memory usage healthy: ${mem_percent}%"
fi

# Disk warning
if [ $disk_percent -gt 85 ]; then
    echo "   🔴 LOW DISK SPACE: ${disk_percent}% used"
    echo "      Run ./cleanup.sh to free space"
elif [ $disk_percent -gt 70 ]; then
    echo "   🟡 DISK SPACE MODERATE: ${disk_percent}% used"
    echo "      Consider running ./cleanup.sh soon"
else
    echo "   ✅ Disk space healthy: ${disk_percent}% used"
fi

# Temperature warning (if available)
if [[ "$temp" != "N/A" ]]; then
    temp_value=$(echo $temp | grep -o '[0-9]*' | head -1)
    if [ $temp_value -gt 80 ]; then
        echo "   🔴 HIGH CPU TEMPERATURE: $temp"
        echo "      Check Intel NUC ventilation and cooling"
    elif [ $temp_value -gt 65 ]; then
        echo "   🟡 ELEVATED CPU TEMPERATURE: $temp"
        echo "      Monitor thermal performance"
    else
        echo "   ✅ CPU temperature normal: $temp"
    fi
fi

echo ""
echo "🎛️  Quick Actions:"
echo "   ./start-n8n.sh      # Start n8n"
echo "   ./stop-n8n.sh       # Stop n8n"
echo "   ./restart-n8n.sh    # Restart n8n"
echo "   ./backup.sh         # Create backup"
echo "   ./logs.sh           # View logs"
echo "   ./monitor.sh        # Live monitoring"
echo "   ./cleanup.sh        # Free disk space"
echo "   ./update.sh         # Update n8n"
#!/bin/bash
# monitor.sh - Real-time system and n8n monitoring for Intel NUC

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR" 2>/dev/null || {
    echo "❌ n8n not found in $PROJECT_DIR"
    exit 1
}

echo "📈 n8n Real-time Monitor (Intel NUC)"
echo "Press Ctrl+C to exit"
echo "====================================="

# Function to get CPU temperature
get_temp() {
    sensors 2>/dev/null | grep "Core 0" | awk '{print $3}' | head -1 | grep -o '[0-9]*' || echo "N/A"
}

# Function to get container stats
get_container_stats() {
    if docker stats n8n-automation --no-stream >/dev/null 2>&1; then
        docker stats n8n-automation --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
    else
        echo "N/A\tN/A\tN/A\tN/A\tN/A"
    fi
}

# Monitoring loop
while true; do
    clear
    echo "📈 n8n Monitor (Intel NUC) - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================================"
    
    # System Overview
    echo ""
    echo "🖥️  Intel NUC System:"
    cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    temp=$(get_temp)
    
    printf "   %-20s %s\n" "CPU Load:" "$cpu_load"
    if [[ "$temp" != "N/A" ]]; then
        printf "   %-20s %s°C\n" "CPU Temperature:" "$temp"
    fi
    
    # Memory Status
    echo ""
    echo "💾 Memory Status:"
    memory_stats=$(free -m | awk '/^Mem:/{printf "%d\t%d\t%d\t%.1f", $2, $3, $7, ($3*100)/$2}')
    IFS=\t' read -r total used available percent <<< "$memory_stats"
    
    printf "   %-20s %dMB\n" "Total:" "$total"
    printf "   %-20s %dMB (%.1f%%)\n" "Used:" "$used" "$percent"
    printf "   %-20s %dMB\n" "Available:" "$available"
    
    # Memory bar visualization
    bar_width=40
    filled=$(( (used * bar_width) / total ))
    empty=$(( bar_width - filled ))
    
    printf "   %-20s [" "Usage:"
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$empty" | tr ' ' '░'
    printf "] %.1f%%\n" "$percent"
    
    # Disk Status
    echo ""
    echo "💽 Storage (120GB SSD):"
    disk_stats=$(df /opt --output=size,used,avail,pcent -BG | tail -1 | tr -d 'G%')
    IFS=' ' read -r disk_total disk_used disk_avail disk_percent <<< "$disk_stats"
    
    printf "   %-20s %dGB\n" "Total:" "$disk_total"
    printf "   %-20s %dGB (%d%%)\n" "Used:" "$disk_used" "$disk_percent"
    printf "   %-20s %dGB\n" "Available:" "$disk_avail"
    
    # n8n Container Status
    echo ""
    echo "🐳 n8n Container:"
    
    if docker compose ps | grep -q "Up"; then
        container_stats=$(get_container_stats)
        IFS=\t' read -r cpu_perc mem_usage mem_perc net_io block_io <<< "$container_stats"
        
        printf "   %-20s ✅ Running\n" "Status:"
        printf "   %-20s %s\n" "CPU Usage:" "$cpu_perc"
        printf "   %-20s %s (%s of limit)\n" "Memory:" "$mem_usage" "$mem_perc"
        printf "   %-20s %s\n" "Network I/O:" "$net_io"
        printf "   %-20s %s\n" "Disk I/O:" "$block_io"
        
        # Container uptime
        uptime_info=$(docker compose ps --format="{{.Status}}" | grep "Up" | head -1)
        printf "   %-20s %s\n" "Uptime:" "$uptime_info"
        
    else
        printf "   %-20s ❌ Stopped\n" "Status:"
        echo "   💡 Start with: ./start-n8n.sh"
    fi
    
    # Network Status
    echo ""
    echo "🌐 Network:"
    ip_address=$(hostname -I | awk '{print $1}')
    printf "   %-20s %s\n" "IP Address:" "$ip_address"
    
    # Load environment if available
    if [[ -f .env ]]; then
        source .env
        printf "   %-20s http://%s:%s\n" "Web Interface:" "$ip_address" "${N8N_PORT:-5678}"
    fi
    
    # Health Indicators
    echo ""
    echo "⚡ Health Indicators:"
    
    # Memory health
    if [ "$percent" -lt 60 ]; then
        printf "   %-20s ✅ Good (%.1f%%)\n" "Memory:" "$percent"
    elif [ "$percent" -lt 80 ]; then
        printf "   %-20s ⚠️  Moderate (%.1f%%)\n" "Memory:" "$percent"
    else
        printf "   %-20s 🔴 High (%.1f%%)\n" "Memory:" "$percent"
    fi
    
    # Disk health
    if [ "$disk_percent" -lt 70 ]; then
        printf "   %-20s ✅ Good (%d%%)\n" "Disk:" "$disk_percent"
    elif [ "$disk_percent" -lt 85 ]; then
        printf "   %-20s ⚠️  Moderate (%d%%)\n" "Disk:" "$disk_percent"
    else
        printf "   %-20s 🔴 High (%d%%)\n" "Disk:" "$disk_percent"
    fi
    
    # Temperature health (if available)
    if [[ "$temp" != "N/A" ]]; then
        if [ "$temp" -lt 65 ]; then
            printf "   %-20s ✅ Good (%s°C)\n" "Temperature:" "$temp"
        elif [ "$temp" -lt 80 ]; then
            printf "   %-20s ⚠️  Elevated (%s°C)\n" "Temperature:" "$temp"
        else
            printf "   %-20s 🔴 High (%s°C)\n" "Temperature:" "$temp"
        fi
    fi
    
    # Quick actions
    echo ""
    echo "🎛️  Quick Actions:"
    echo "   r = restart n8n    s = stop n8n       l = view logs"
    echo "   b = backup         c = cleanup        q = quit"
    
    # Non-blocking input check
    read -t 5 -n 1 action 2>/dev/null || action=""
    
    case $action in
        'r'|'R')
            echo ""
            echo "🔄 Restarting n8n..."
            ./restart-n8n.sh
            read -p "Press Enter to continue monitoring..." 
            ;;
        's'|'S')
            echo ""
            echo "🛑 Stopping n8n..."
            ./stop-n8n.sh
            read -p "Press Enter to continue monitoring..."
            ;;
        'l'|'L')
            echo ""
            echo "📋 Opening logs (Ctrl+C to return)..."
            ./logs.sh live
            ;;
        'b'|'B')
            echo ""
            echo "💾 Creating backup..."
            ./backup.sh
            read -p "Press Enter to continue monitoring..."
            ;;
        'c'|'C')
            echo ""
            echo "🧹 Running cleanup..."
            ./cleanup.sh
            read -p "Press Enter to continue monitoring..."
            ;;
        'q'|'Q')
            echo ""
            echo "👋 Monitoring stopped"
            exit 0
            ;;
    esac
done
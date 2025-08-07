#!/bin/bash
# logs.sh - Log viewer and manager

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

echo "📋 n8n Log Viewer"
echo "================="

# Function to show usage
show_usage() {
    echo "💡 Usage: ./logs.sh [option]"
    echo ""
    echo "Options:"
    echo "   live                # Live container logs (default)"
    echo "   container           # Container logs (last 100 lines)"
    echo "   startup             # Startup logs"
    echo "   errors              # Error logs only"
    echo "   follow              # Follow live logs"
    echo "   last <n>            # Last n lines"
    echo "   search <pattern>    # Search in logs"
    echo "   clear               # Clear log files"
    echo "   size                # Show log file sizes"
}

# Default to live logs if no argument
ACTION=${1:-live}

case $ACTION in
    "live"|"follow")
        echo "📱 Live container logs (Ctrl+C to exit):"
        echo "======================================="
        docker-compose logs -f
        ;;
        
    "container")
        echo "📄 Container logs (last 100 lines):"
        echo "==================================="
        docker-compose logs --tail=100
        ;;
        
    "startup")
        echo "🚀 Startup logs:"
        echo "==============="
        if [[ -f logs/startup.log ]]; then
            cat logs/startup.log
        else
            echo "No startup logs found"
        fi
        ;;
        
    "errors")
        echo "🔴 Error logs:"
        echo "============="
        docker-compose logs | grep -i "error\|exception\|failed\|fatal" || echo "No errors found"
        ;;
        
    "last")
        LINES=${2:-50}
        echo "📄 Last $LINES log lines:"
        echo "========================"
        docker-compose logs --tail=$LINES
        ;;
        
    "search")
        if [[ -z "$2" ]]; then
            echo "❌ Please provide search pattern"
            echo "💡 Usage: ./logs.sh search <pattern>"
            exit 1
        fi
        echo "🔍 Searching for: $2"
        echo "=================="
        docker-compose logs | grep -i "$2" || echo "Pattern not found"
        ;;
        
    "clear")
        echo "🧹 Clearing log files..."
        docker-compose down 2>/dev/null || true
        docker system prune -f >/dev/null 2>&1 || true
        
        # Clear local logs
        rm -f logs/*.log 2>/dev/null || true
        touch logs/startup.log
        
        echo "✅ Logs cleared"
        ;;
        
    "size")
        echo "📏 Log file sizes:"
        echo "================="
        
        # Container logs
        if docker ps -q -f name=n8n-automation >/dev/null 2>&1; then
            container_log_size=$(docker logs n8n-automation 2>&1 | wc -c | awk '{print int($1/1024)"KB"}')
            echo "   Container logs:   $container_log_size"
        fi
        
        # Local logs
        if [[ -d logs ]]; then
            echo "   Local logs:"
            du -h logs/* 2>/dev/null | sed 's/^/      /' || echo "      No local logs"
        fi
        
        # Docker system logs
        docker_logs_size=$(docker system df | grep "Build Cache" | awk '{print $3}' || echo "unknown")
        echo "   Docker cache:     $docker_logs_size"
        ;;
        
    "help"|"-h"|"--help")
        show_usage
        ;;
        
    *)
        echo "❌ Unknown option: $ACTION"
        show_usage
        exit 1
        ;;
esac

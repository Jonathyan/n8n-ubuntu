#!/bin/bash
# backup.sh - Comprehensive backup utility for Intel NUC

set -e

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="n8n_backup_${TIMESTAMP}"

echo "💾 n8n Backup Utility (Intel NUC)"
echo "================================="

# Load environment
if [[ -f .env ]]; then
    source .env
    RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
else
    RETENTION_DAYS=30
fi

# Create backup directories
mkdir -p "$BACKUP_DIR"/{daily,weekly,monthly}

# Determine backup type
DAY=$(date +%u)  # 1=Monday, 7=Sunday
DATE=$(date +%d)

if [[ "$DATE" == "01" ]]; then
    BACKUP_TYPE="monthly"
    BACKUP_SUBDIR="monthly"
elif [[ "$DAY" == "7" ]]; then  # Sunday
    BACKUP_TYPE="weekly"
    BACKUP_SUBDIR="weekly"
else
    BACKUP_TYPE="daily"
    BACKUP_SUBDIR="daily"
fi

FULL_BACKUP_DIR="$BACKUP_DIR/$BACKUP_SUBDIR"
BACKUP_FILE="$FULL_BACKUP_DIR/${BACKUP_NAME}.tar.gz"

echo "📊 Backup Information:"
echo "   Type:             $BACKUP_TYPE backup"
echo "   Timestamp:        $TIMESTAMP"
echo "   Destination:      $BACKUP_FILE"
echo "   Retention:        $RETENTION_DAYS days"

# Check available disk space
available_space=$(df /opt --output=avail -BM | tail -1 | tr -d 'M')
if [ "$available_space" -lt 1024 ]; then
    echo "⚠️  Low disk space: ${available_space}MB available"
    echo "💡 Consider cleaning old backups first: ./cleanup.sh"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

echo ""
echo "🔄 Creating backup..."

# Check if n8n is running
if docker compose ps | grep -q "Up"; then
    echo "📦 n8n is running - creating live backup"
    
    # Export workflows from running n8n
    echo "   Exporting workflows..."
    if docker compose exec -T n8n n8n export:workflow --backup --output="/tmp/workflows_${TIMESTAMP}.json" >/dev/null 2>&1; then
        docker cp "n8n-automation:/tmp/workflows_${TIMESTAMP}.json" "./workflows_${TIMESTAMP}.json"
        docker compose exec -T n8n rm "/tmp/workflows_${TIMESTAMP}.json"
        echo "   ✅ Workflows exported"
    else
        echo "   ⚠️  Workflow export failed, will backup database instead"
    fi
    
    # Export credentials (if possible)
    echo "   Exporting credentials..."
    if docker compose exec -T n8n n8n export:credentials --backup --output="/tmp/credentials_${TIMESTAMP}.json" >/dev/null 2>&1; then
        docker cp "n8n-automation:/tmp/credentials_${TIMESTAMP}.json" "./credentials_${TIMESTAMP}.json"
        docker compose exec -T n8n rm "/tmp/credentials_${TIMESTAMP}.json"
        echo "   ✅ Credentials exported"
    else
        echo "   ⚠️  Credentials export failed (this is normal for some versions)"
    fi
else
    echo "📦 n8n is stopped - creating offline backup"
fi

# Create comprehensive backup
echo "   Creating archive..."

# Temporary backup staging area
TEMP_BACKUP_DIR="/tmp/n8n_backup_staging_$$"
mkdir -p "$TEMP_BACKUP_DIR"

# Copy configuration files
cp .env "$TEMP_BACKUP_DIR/" 2>/dev/null || true
cp docker-compose.yml "$TEMP_BACKUP_DIR/" 2>/dev/null || true
cp ./*.sh "$TEMP_BACKUP_DIR/" 2>/dev/null || true

# Copy exported files
cp workflows_${TIMESTAMP}.json "$TEMP_BACKUP_DIR/" 2>/dev/null || true
cp credentials_${TIMESTAMP}.json "$TEMP_BACKUP_DIR/" 2>/dev/null || true

# Copy data directory if exists
if [[ -d data ]]; then
    cp -r data "$TEMP_BACKUP_DIR/"
fi

# Copy logs (last 7 days only to save space)
if [[ -d logs ]]; then
    mkdir -p "$TEMP_BACKUP_DIR/logs"
    find logs -name "*.log" -mtime -7 -exec cp {} "$TEMP_BACKUP_DIR/logs/" \; 2>/dev/null || true
fi

# Create metadata
cat > "$TEMP_BACKUP_DIR/backup_metadata.json" << EOF
{
    "backup_date": "$(date -Iseconds)",
    "backup_type": "$BACKUP_TYPE",
    "hostname": "$(hostname)",
    "n8n_version": "$(docker compose exec -T n8n n8n --version 2>/dev/null | head -1 || echo 'unknown')",
    "system_info": {
        "cpu": "$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)",
        "memory_total": "$(free -m | awk '/^Mem:/{print $2}')MB",
        "disk_available": "${available_space}MB"
    }
}
EOF

# Create tar.gz backup
tar -czf "$BACKUP_FILE" -C "$TEMP_BACKUP_DIR" . 2>/dev/null

# Cleanup staging area
rm -rf "$TEMP_BACKUP_DIR"
rm -f workflows_${TIMESTAMP}.json credentials_${TIMESTAMP}.json

# Verify backup
if [[ -f "$BACKUP_FILE" ]]; then
    backup_size=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "   ✅ Backup created: $backup_size"
else
    echo "   ❌ Backup creation failed"
    exit 1
fi

echo ""
echo "🧹 Cleaning up old backups..."

# Cleanup old backups based on retention policy
case $BACKUP_TYPE in
    "daily")
        find "$BACKUP_DIR/daily" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
        ;;
    "weekly")
        find "$BACKUP_DIR/weekly" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
        ;;
    "monthly")
        find "$BACKUP_DIR/monthly" -name "*.tar.gz" -mtime +365 -delete 2>/dev/null || true
        ;;
esac

# Overall cleanup based on retention days
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

# Show backup summary
echo ""
echo "📊 Backup Summary:"
echo "   ✅ Backup completed successfully"
echo "   📁 Location: $BACKUP_FILE"
echo "   📏 Size: $backup_size"
echo "   🗓️  Type: $BACKUP_TYPE"

echo ""
echo "📁 Current Backups:"
if ls "$BACKUP_DIR"/*/*.tar.gz >/dev/null 2>&1; then
    ls -lh "$BACKUP_DIR"/*/*.tar.gz | awk '{print "   " $9 " (" $5 ", " $6 " " $7 ")"}'
else
    echo "   No backups found"
fi

echo ""
echo "💡 Restore with: ./restore.sh $BACKUP_NAME"
echo "🗑️  Cleanup old backups: ./cleanup.sh"

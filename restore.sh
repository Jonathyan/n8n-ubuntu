#!/bin/bash
# restore.sh - Restore n8n from backup

set -e

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

BACKUP_DIR="./backups"

echo "📥 n8n Restore Utility"
echo "====================="

# Check if backup name provided
if [[ -z "$1" ]]; then
    echo "❌ No backup specified"
    echo ""
    echo "📁 Available backups:"
    if ls "$BACKUP_DIR"/*/*.tar.gz >/dev/null 2>&1; then
        ls -1 "$BACKUP_DIR"/*/*.tar.gz | sed 's|.*/||; s|\.tar\.gz||' | nl -nln
        echo ""
        echo "💡 Usage: ./restore.sh <backup_name>"
        echo "   Example: ./restore.sh n8n_backup_20250807_143022"
    else
        echo "   No backups found"
    fi
    exit 1
fi

BACKUP_NAME="$1"
BACKUP_FILE=""

# Find backup file
for backup_type in daily weekly monthly; do
    potential_file="$BACKUP_DIR/$backup_type/${BACKUP_NAME}.tar.gz"
    if [[ -f "$potential_file" ]]; then
        BACKUP_FILE="$potential_file"
        break
    fi
done

if [[ -z "$BACKUP_FILE" ]]; then
    echo "❌ Backup not found: $BACKUP_NAME"
    exit 1
fi

echo "📊 Restore Information:"
echo "   Backup:           $BACKUP_NAME"
echo "   File:             $BACKUP_FILE"
echo "   Size:             $(du -h "$BACKUP_FILE" | cut -f1)"

# Safety warning
echo ""
echo "⚠️  WARNING: This will replace current n8n configuration!"
echo "💡 Current data will be backed up to restore_backup_$(date +%Y%m%d_%H%M%S)"
echo ""
read -p "Continue with restore? (y/N): " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Stop n8n if running
if docker-compose ps | grep -q "Up"; then
    echo "🛑 Stopping n8n..."
    ./stop-n8n.sh
fi

# Create safety backup of current state
echo "💾 Creating safety backup of current state..."
safety_backup="./backups/restore_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$safety_backup" .env docker-compose.yml data/ 2>/dev/null || true

# Extract backup
echo "📦 Extracting backup..."
TEMP_RESTORE_DIR="/tmp/n8n_restore_staging_$"
mkdir -p "$TEMP_RESTORE_DIR"

tar -xzf "$BACKUP_FILE" -C "$TEMP_RESTORE_DIR"

# Restore files
echo "🔄 Restoring configuration..."

# Restore config files
if [[ -f "$TEMP_RESTORE_DIR/.env" ]]; then
    cp "$TEMP_RESTORE_DIR/.env" ./ 
    echo "   ✅ Environment restored"
fi

if [[ -f "$TEMP_RESTORE_DIR/docker-compose.yml" ]]; then
    cp "$TEMP_RESTORE_DIR/docker-compose.yml" ./
    echo "   ✅ Docker configuration restored"
fi

# Restore data directory
if [[ -d "$TEMP_RESTORE_DIR/data" ]]; then
    rm -rf data/
    cp -r "$TEMP_RESTORE_DIR/data" ./
    echo "   ✅ Data directory restored"
fi

# Show metadata if available
if [[ -f "$TEMP_RESTORE_DIR/backup_metadata.json" ]]; then
    echo ""
    echo "📊 Backup Metadata:"
    if command -v jq >/dev/null 2>&1; then
        jq -r '
            "   Original Date: " + .backup_date + 
            "\n   Backup Type: " + .backup_type +
            "\n   Hostname: " + .hostname +
            "\n   n8n Version: " + .n8n_version
        ' "$TEMP_RESTORE_DIR/backup_metadata.json"
    else
        cat "$TEMP_RESTORE_DIR/backup_metadata.json"
    fi
fi

# Cleanup restore staging
rm -rf "$TEMP_RESTORE_DIR"

echo ""
echo "✅ Restore completed successfully!"
echo "💾 Safety backup created: $safety_backup"
echo ""
echo "🚀 Start n8n: ./start-n8n.sh"
echo "📊 Check status: ./status.sh"
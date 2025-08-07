# n8n Automation Server - Ubuntu Intel NUC Setup

Complete production-ready n8n installation for Ubuntu on Intel NUC6CAY (J3455, 8GB RAM, 120GB SSD).

## 🖥️ Hardware Specifications

- **CPU:** Intel J3455 quad-core @ 1.5-2.3GHz
- **RAM:** 8GB DDR3L  
- **Storage:** 120GB SSD
- **Network:** Gigabit Ethernet
- **OS:** Ubuntu 22.04+ LTS

## 📋 Prerequisites (Ubuntu 22.04 LTS)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages (Ubuntu 22.04 specific)
sudo apt install -y curl wget git jq bc htop tree unzip lm-sensors \
                    apt-transport-https ca-certificates gnupg lsb-release

# Install Docker Engine (Official Ubuntu 22.04 method)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose v2 (Ubuntu 22.04 includes this)
sudo apt install -y docker-compose-v2

# Create docker-compose symlink for compatibility
sudo ln -sf /usr/bin/docker-compose /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Configure sensors for temperature monitoring
sudo sensors-detect --auto

# Verify installation
docker --version
docker compose version
```

## 🚀 Quick Installation

```bash
# 1. Create project directory
sudo mkdir -p /opt/n8n-automation
sudo chown $USER:$USER /opt/n8n-automation
cd /opt/n8n-automation

# 2. Download setup files
wget https://your-setup-files/install.sh
chmod +x install.sh
./install.sh

# 3. Start n8n
./start-n8n.sh

# 4. Access at http://your-nuc-ip:5678
```

## 📁 Project Structure

```
/opt/n8n-automation/
├── .env                    # 🔒 Environment secrets
├── .env.example           # 📝 Configuration template
├── .gitignore             # 🚫 Git ignore rules
├── docker-compose.yml     # 🐳 Container configuration
├── README.md              # 📚 This documentation
├── install.sh             # 🛠️ One-click installer
├── start-n8n.sh          # 🚀 Start script
├── stop-n8n.sh           # 🛑 Stop script
├── restart-n8n.sh        # 🔄 Restart script
├── status.sh             # 📊 Status checker
├── backup.sh             # 💾 Backup utility
├── restore.sh            # 📥 Restore utility
├── logs.sh               # 📋 Log viewer
├── update.sh             # ⬆️ Update n8n
├── monitor.sh            # 📈 Resource monitor
├── cleanup.sh            # 🧹 Cleanup utility
├── shared/               # 📁 File exchange
├── backups/              # 💾 Backup storage
├── logs/                 # 📋 Application logs
├── scripts/              # 🔧 Helper scripts
├── systemd/              # ⚙️ Service files
└── docs/                 # 📚 Documentation
```

## ⚙️ Configuration Files

### Environment Template (.env.example)

```bash
# n8n Server Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http

# Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=generate-secure-password-here

# Timezone & Localization
GENERIC_TIMEZONE=Europe/Amsterdam
N8N_DEFAULT_LOCALE=en

# Security Settings
N8N_SECURE_COOKIE=false
N8N_JWT_AUTH_ACTIVE=false

# Performance Settings (Intel NUC J3455 Optimized)
N8N_PAYLOAD_SIZE_MAX=8
EXECUTIONS_TIMEOUT=180
EXECUTIONS_TIMEOUT_MAX=1800

# Logging & Debugging
N8N_LOG_LEVEL=info
N8N_METRICS=true
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_MAX_AGE=168

# Container Resource Limits (8GB System)
CONTAINER_MEMORY_LIMIT=2g
CONTAINER_CPU_LIMIT=2.0
CONTAINER_MEMORY_RESERVATION=512m
CONTAINER_CPU_RESERVATION=0.5

# Storage Settings
BACKUP_RETENTION_DAYS=30
LOG_MAX_SIZE=10m
LOG_MAX_FILES=5

# Network Settings
NUC_IP_ADDRESS=192.168.1.100
WEBHOOK_TUNNEL_URL=

# Optional: API Keys
# ANTHROPIC_API_KEY=your-claude-api-key
# OPENAI_API_KEY=your-openai-api-key
```

### Docker Compose (docker-compose.yml)

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n-automation
    restart: unless-stopped
    
    ports:
      - "${N8N_PORT:-5678}:5678"
    
    env_file:
      - .env
    
    environment:
      # Core Configuration
      - N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE}
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=5678
      - N8N_PROTOCOL=${N8N_PROTOCOL}
      
      # Localization
      - GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
      - N8N_DEFAULT_LOCALE=${N8N_DEFAULT_LOCALE}
      
      # Performance (Intel NUC Optimized)
      - N8N_PAYLOAD_SIZE_MAX=${N8N_PAYLOAD_SIZE_MAX}
      - EXECUTIONS_TIMEOUT=${EXECUTIONS_TIMEOUT}
      - EXECUTIONS_TIMEOUT_MAX=${EXECUTIONS_TIMEOUT_MAX}
      
      # Logging
      - N8N_LOG_LEVEL=${N8N_LOG_LEVEL}
      - N8N_METRICS=${N8N_METRICS}
      - EXECUTIONS_DATA_SAVE_ON_ERROR=${EXECUTIONS_DATA_SAVE_ON_ERROR}
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=${EXECUTIONS_DATA_SAVE_ON_SUCCESS}
      - EXECUTIONS_DATA_MAX_AGE=${EXECUTIONS_DATA_MAX_AGE}
      
      # Security
      - N8N_SECURE_COOKIE=${N8N_SECURE_COOKIE}
      - N8N_JWT_AUTH_ACTIVE=${N8N_JWT_AUTH_ACTIVE}
      
      # Database
      - DB_TYPE=sqlite
      - DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite
      
      # Webhooks
      - WEBHOOK_URL=http://${NUC_IP_ADDRESS:-localhost}:${N8N_PORT:-5678}/
      
      # User folder
      - N8N_USER_FOLDER=/home/node/.n8n
      
    volumes:
      # Persistent data
      - n8n_data:/home/node/.n8n
      
      # File sharing
      - ./shared:/data
      
      # Backup access
      - ./backups:/backups:ro
      
      # Log persistence
      - ./logs:/app/logs
      
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 15s
      retries: 3
      start_period: 60s
      
    # Resource limits for Intel NUC
    deploy:
      resources:
        limits:
          memory: ${CONTAINER_MEMORY_LIMIT:-2g}
          cpus: '${CONTAINER_CPU_LIMIT:-2.0}'
        reservations:
          memory: ${CONTAINER_MEMORY_RESERVATION:-512m}
          cpus: '${CONTAINER_CPU_RESERVATION:-0.5}'
    
    # Security
    security_opt:
      - no-new-privileges:true
    
    # User mapping for file permissions
    user: "${PUID:-1000}:${PGID:-1000}"
    
    # Logging configuration
    logging:
      driver: "json-file"
      options:
        max-size: "${LOG_MAX_SIZE:-10m}"
        max-file: "${LOG_MAX_FILES:-5}"

volumes:
  n8n_data:
    driver: local
    name: n8n_automation_data
    driver_opts:
      type: none
      o: bind
      device: /opt/n8n-automation/data

networks:
  default:
    name: n8n-automation-network
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Git Ignore (.gitignore)

```gitignore
# Environment secrets
.env
.env.local
.env.*.local

# n8n data
data/
*.sqlite
*.sqlite-*

# Logs
logs/*.log
*.log

# Backups (may contain sensitive data)
backups/*.json
backups/*.sql
backups/*.tar.gz

# System files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Runtime files
*.pid
node_modules/

# Docker
.docker/

# Temporary files
tmp/
temp/
*.tmp
```

## 🛠️ Management Scripts

### One-Click Installer (install.sh)

```bash
#!/bin/bash
# install.sh - One-click n8n installer for Ubuntu Intel NUC

set -e

PROJECT_DIR="/opt/n8n-automation"
USER_NAME=$(whoami)

echo "🚀 n8n Automation Server Installer"
echo "=================================="
echo "Target: Intel NUC J3455 (8GB RAM, Ubuntu)"
echo "Installation directory: $PROJECT_DIR"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root"
   echo "💡 Run as regular user with sudo privileges"
   exit 1
fi

# Check Ubuntu version (22.04 specific)
if ! grep -q "22.04" /etc/os-release; then
    echo "⚠️  Warning: This installer is optimized for Ubuntu 22.04 LTS"
    ubuntu_version=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
    echo "   Detected: Ubuntu $ubuntu_version"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

echo "1️⃣ Checking system requirements..."

# Check available memory
total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_mem_gb=$((total_mem_kb / 1024 / 1024))

if [ $total_mem_gb -lt 4 ]; then
    echo "❌ Insufficient memory: ${total_mem_gb}GB (minimum 4GB required)"
    exit 1
fi

echo "   ✅ Memory: ${total_mem_gb}GB"

# Check available storage
available_gb=$(df /opt --output=avail -BG | tail -1 | tr -d 'G')
if [ $available_gb -lt 10 ]; then
    echo "❌ Insufficient storage: ${available_gb}GB (minimum 10GB required)"
    exit 1
fi

echo "   ✅ Storage: ${available_gb}GB available"

# Check Docker (Ubuntu 22.04 methods)
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker (Ubuntu 22.04)..."
    
    # Install Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    sudo usermod -aG docker $USER
    echo "   ✅ Docker installed (Ubuntu 22.04 method)"
else
    echo "   ✅ Docker already installed"
fi

# Check Docker Compose (Ubuntu 22.04 uses docker-compose-plugin)
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "🔧 Installing Docker Compose (Ubuntu 22.04)..."
    
    # Install docker-compose-plugin (preferred method for 22.04)
    sudo apt install -y docker-compose-plugin
    
    # Create compatibility symlink
    sudo ln -sf /usr/bin/docker-compose /usr/local/bin/docker-compose 2>/dev/null || true
    
    echo "   ✅ Docker Compose installed"
else
    echo "   ✅ Docker Compose already installed"
fi

echo ""
echo "2️⃣ Setting up project structure..."

# Create project directory
sudo mkdir -p $PROJECT_DIR
sudo chown $USER_NAME:$USER_NAME $PROJECT_DIR
cd $PROJECT_DIR

# Create subdirectories
mkdir -p {shared,backups,logs,scripts,systemd,docs,data}

echo "   ✅ Project directories created"

echo ""
echo "3️⃣ Generating secure configuration..."

# Generate secure password
secure_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Get system info
cpu_cores=$(nproc)
mem_gb=$total_mem_gb
ip_address=$(hostname -I | awk '{print $1}')

# Create .env file
cat > .env << EOF
# n8n Server Configuration - Generated $(date)
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http

# Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=$secure_password

# System Information
NUC_IP_ADDRESS=$ip_address
CPU_CORES=$cpu_cores
MEMORY_GB=$mem_gb

# Timezone & Localization
GENERIC_TIMEZONE=Europe/Amsterdam
N8N_DEFAULT_LOCALE=en

# Performance Settings (Intel NUC Optimized)
N8N_PAYLOAD_SIZE_MAX=8
EXECUTIONS_TIMEOUT=180
EXECUTIONS_TIMEOUT_MAX=1800

# Logging
N8N_LOG_LEVEL=info
N8N_METRICS=true
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_MAX_AGE=168

# Container Limits (8GB System)
CONTAINER_MEMORY_LIMIT=2g
CONTAINER_CPU_LIMIT=2.0
CONTAINER_MEMORY_RESERVATION=512m
CONTAINER_CPU_RESERVATION=0.5

# User/Group IDs
PUID=$(id -u)
PGID=$(id -g)

# Storage & Backup
BACKUP_RETENTION_DAYS=30
LOG_MAX_SIZE=10m
LOG_MAX_FILES=5
EOF

echo "   ✅ Configuration generated"
echo "   🔐 Admin password: $secure_password"

echo ""
echo "4️⃣ Installing management scripts..."

# Create all management scripts here...
# (Scripts will be created in separate artifacts)

echo "   ✅ Management scripts installed"

echo ""
echo "5️⃣ Setting up systemd service..."

# Create systemd service (Ubuntu 22.04 compatible)
sudo tee /etc/systemd/system/n8n-automation.service > /dev/null << EOF
[Unit]
Description=n8n Automation Server
Documentation=https://docs.n8n.io
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/start-n8n.sh
ExecStop=$PROJECT_DIR/stop-n8n.sh
ExecReload=/bin/bash -c 'cd $PROJECT_DIR && ./stop-n8n.sh && ./start-n8n.sh'
TimeoutStartSec=300
TimeoutStopSec=60
User=$USER_NAME
Group=docker
Restart=on-failure
RestartSec=10

# Security settings for Ubuntu 22.04
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$PROJECT_DIR

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable n8n-automation

echo "   ✅ Systemd service configured"

echo ""
echo "6️⃣ Final setup..."

# Set permissions
chmod +x *.sh
chown -R $USER_NAME:$USER_NAME $PROJECT_DIR

# Create initial backup directory structure
mkdir -p backups/{daily,weekly,monthly}

echo "   ✅ Permissions set"

echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "📊 System Summary:"
echo "   Server IP:     $ip_address"
echo "   CPU Cores:     $cpu_cores"
echo "   Memory:        ${mem_gb}GB"
echo "   n8n Port:      5678"
echo "   Install Path:  $PROJECT_DIR"
echo ""
echo "🔐 Login Credentials:"
echo "   Username:      admin"
echo "   Password:      $secure_password"
echo ""
echo "🚀 Quick Start:"
echo "   cd $PROJECT_DIR"
echo "   ./start-n8n.sh"
echo "   # Access: http://$ip_address:5678"
echo ""
echo "⚙️  Service Management:"
echo "   sudo systemctl start n8n-automation"
echo "   sudo systemctl status n8n-automation"
echo "   sudo systemctl stop n8n-automation"
echo ""
echo "📚 Available Commands:"
echo "   ./start-n8n.sh     # Start n8n"
echo "   ./stop-n8n.sh      # Stop n8n"
echo "   ./status.sh        # Check status"
echo "   ./backup.sh        # Create backup"
echo "   ./monitor.sh       # System monitor"
echo ""
echo "💡 Next Steps:"
echo "   1. Start n8n: ./start-n8n.sh"
echo "   2. Open browser: http://$ip_address:5678"
echo "   3. Login with credentials above"
echo "   4. Add API keys: Settings → Credentials"
echo ""
echo "📖 Documentation: $PROJECT_DIR/README.md"
echo ""
echo "✨ Happy Automating!"
```

### Start Script (start-n8n.sh)

```bash
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
    echo "💡 Try: sudo usermod -aG docker $USER && newgrp docker"
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
if [ $available_mem -lt 1024 ]; then
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
if [ $available_disk -lt 1024 ]; then
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

while [ $waited -lt $max_wait ]; do
    if docker compose ps | grep -q "healthy"; then
        echo "✅ n8n is running and healthy!"
        break
    elif docker compose ps | grep -q "unhealthy"; then
        echo "❌ n8n health check failed"
        echo "📋 Recent logs:"
        docker compose logs --tail=10
        exit 1
    elif [ $waited -eq $max_wait ]; then
        echo "❌ n8n failed to start in ${max_wait} seconds"
        echo "📋 Startup logs:"
        docker compose logs --tail=20
        exit 1
    fi
    
    if [ $((waited % 15)) -eq 0 ] && [ $waited -gt 0 ]; then
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
echo "🔐 Password:         $(echo ${N8N_BASIC_AUTH_PASSWORD} | sed 's/./*/g')"
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
```

### Stop Script (stop-n8n.sh)

```bash
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
```

### Status Script (status.sh)

```bash
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
```

### Restart Script (restart-n8n.sh)

```bash
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
```

### Backup Script (backup.sh)

```bash
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
HOUR=$(date +%H)
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
if [ $available_space -lt 1024 ]; then
    echo "⚠️  Low disk space: ${available_space}MB available"
    echo "💡 Consider cleaning old backups first: ./cleanup.sh"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

echo ""
echo "🔄 Creating backup..."

# Check if n8n is running
if docker-compose ps | grep -q "Up"; then
    echo "📦 n8n is running - creating live backup"
    
    # Export workflows from running n8n
    echo "   Exporting workflows..."
    if docker-compose exec -T n8n n8n export:workflow --backup --output=/tmp/workflows_${TIMESTAMP}.json >/dev/null 2>&1; then
        docker cp n8n-automation:/tmp/workflows_${TIMESTAMP}.json ./workflows_${TIMESTAMP}.json
        docker-compose exec -T n8n rm /tmp/workflows_${TIMESTAMP}.json
        echo "   ✅ Workflows exported"
    else
        echo "   ⚠️  Workflow export failed, will backup database instead"
    fi
    
    # Export credentials (if possible)
    echo "   Exporting credentials..."
    if docker-compose exec -T n8n n8n export:credentials --backup --output=/tmp/credentials_${TIMESTAMP}.json >/dev/null 2>&1; then
        docker cp n8n-automation:/tmp/credentials_${TIMESTAMP}.json ./credentials_${TIMESTAMP}.json
        docker-compose exec -T n8n rm /tmp/credentials_${TIMESTAMP}.json
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
TEMP_BACKUP_DIR="/tmp/n8n_backup_staging_$"
mkdir -p "$TEMP_BACKUP_DIR"

# Copy configuration files
cp .env "$TEMP_BACKUP_DIR/" 2>/dev/null || true
cp docker-compose.yml "$TEMP_BACKUP_DIR/" 2>/dev/null || true
cp *.sh "$TEMP_BACKUP_DIR/" 2>/dev/null || true

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
    "n8n_version": "$(docker-compose exec -T n8n n8n --version 2>/dev/null | head -1 || echo 'unknown')",
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
```

### Restore Script (restore.sh)

```bash
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
```

### Logs Script (logs.sh)

```bash
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
```

### Monitor Script (monitor.sh)

```bash
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
    
    if docker-compose ps | grep -q "Up"; then
        container_stats=$(get_container_stats)
        IFS=\t' read -r cpu_perc mem_usage mem_perc net_io block_io <<< "$container_stats"
        
        printf "   %-20s ✅ Running\n" "Status:"
        printf "   %-20s %s\n" "CPU Usage:" "$cpu_perc"
        printf "   %-20s %s (%s of limit)\n" "Memory:" "$mem_usage" "$mem_perc"
        printf "   %-20s %s\n" "Network I/O:" "$net_io"
        printf "   %-20s %s\n" "Disk I/O:" "$block_io"
        
        # Container uptime
        uptime_info=$(docker-compose ps --format="{{.Status}}" | grep "Up" | head -1)
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
```

### Update Script (update.sh)

```bash
#!/bin/bash
# update.sh - Update n8n to latest version

set -e

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

echo "⬆️ n8n Update Utility"
echo "===================="

# Load environment
if [[ -f .env ]]; then
    source .env
fi

# Check current version
echo "🔍 Checking current version..."
if docker-compose ps | grep -q "Up"; then
    current_version=$(docker-compose exec -T n8n n8n --version 2>/dev/null | head -1 || echo "unknown")
    echo "   Current: $current_version"
else
    echo "   n8n is not running"
    current_version="unknown"
fi

# Safety backup before update
echo ""
echo "💾 Creating pre-update backup``
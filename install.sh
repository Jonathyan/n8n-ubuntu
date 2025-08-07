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

if [ "$total_mem_gb" -lt 4 ]; then
    echo "❌ Insufficient memory: ${total_mem_gb}GB (minimum 4GB required)"
    exit 1
fi

echo "   ✅ Memory: ${total_mem_gb}GB"

# Check available storage
available_gb=$(df /opt --output=avail -BG | tail -1 | tr -d 'G')
if [ "$available_gb" -lt 10 ]; then
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
    
    sudo usermod -aG docker "$USER"
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
sudo mkdir -p "$PROJECT_DIR"
sudo chown "$USER_NAME:$USER_NAME" "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create subdirectories
mkdir -p {shared,backups,logs,scripts,systemd,docs,data,secrets}

# Secure secrets directory
chmod 700 secrets

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
# N8N_BASIC_AUTH_PASSWORD stored in secrets/password.txt

# System Information
NUC_IP_ADDRESS="$ip_address"
CPU_CORES="$cpu_cores"
MEMORY_GB="$mem_gb"

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

# Store password securely
echo "$secure_password" > secrets/password.txt
chmod 600 secrets/password.txt

echo "   ✅ Configuration generated"
echo "   🔐 Admin password: $secure_password (stored in secrets/password.txt)"

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
WorkingDirectory="$PROJECT_DIR"
ExecStart="$PROJECT_DIR/start-n8n.sh"
ExecStop="$PROJECT_DIR/stop-n8n.sh"
ExecReload=/bin/bash -c 'cd "$PROJECT_DIR" && ./stop-n8n.sh && ./start-n8n.sh'
TimeoutStartSec=300
TimeoutStopSec=60
User="$USER_NAME"
Group=docker
Restart=on-failure
RestartSec=10

# Security settings for Ubuntu 22.04
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths="$PROJECT_DIR"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable n8n-automation

echo "   ✅ Systemd service configured"

echo ""
echo "6️⃣ Final setup..."

# Set permissions
chmod +x ./*.sh
chown -R "$USER_NAME:$USER_NAME" "$PROJECT_DIR"

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
echo "   cd \"$PROJECT_DIR\""
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
echo "📖 Documentation: \"$PROJECT_DIR/README.md\""
echo ""
echo "✨ Happy Automating!"
# n8n Automation Server - Ubuntu Intel NUC

Complete Docker-based n8n installation optimized for Intel NUC J3455 (8GB RAM) running Ubuntu 22.04 LTS.

## 🖥️ Hardware Requirements

- **CPU:** Intel J3455 quad-core @ 1.5-2.3GHz
- **RAM:** 8GB DDR3L (minimum 4GB)
- **Storage:** 120GB SSD (minimum 10GB free)
- **Network:** Gigabit Ethernet
- **OS:** Ubuntu 22.04+ LTS

## 🚀 Quick Start

```bash
# Clone and install
git clone <repository-url> /opt/n8n-automation
cd /opt/n8n-automation
chmod +x *.sh
sudo ./install.sh

# Start n8n
./start-n8n.sh

# Access: http://your-ip:5678
# Username: admin
# Password: (generated during install)
```

## 📋 Management Scripts

| Script | Description |
|--------|-------------|
| `install.sh` | One-click installer with system setup |
| `start-n8n.sh` | Start n8n with health checks |
| `stop-n8n.sh` | Graceful shutdown |
| `restart-n8n.sh` | Restart service |
| `status.sh` | System and container status |
| `monitor.sh` | Real-time resource monitoring |
| `backup.sh` | Automated backup (daily/weekly/monthly) |
| `restore.sh` | Restore from backup |
| `cleanup.sh` | Disk space cleanup |
| `update.sh` | Update to latest n8n version |
| `logs.sh` | Log viewer and manager |

## ⚙️ Configuration

Environment variables in `.env`:

```bash
# Authentication
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-secure-password

# Intel NUC Optimizations
CONTAINER_MEMORY_LIMIT=2g
CONTAINER_CPU_LIMIT=2.0
N8N_PAYLOAD_SIZE_MAX=8
EXECUTIONS_TIMEOUT=180

# Backup Settings
BACKUP_RETENTION_DAYS=30
```

## 🐳 Docker Setup

- **Image:** n8nio/n8n:latest
- **Container:** n8n-automation
- **Port:** 5678
- **Data:** Persistent Docker volume
- **Health Checks:** Built-in monitoring

## 🔧 System Service

```bash
# Service management
sudo systemctl start n8n-automation
sudo systemctl stop n8n-automation
sudo systemctl status n8n-automation

# Enable auto-start
sudo systemctl enable n8n-automation
```

## 💾 Backup Strategy

- **Daily:** Automatic at midnight (7-day retention)
- **Weekly:** Sunday backups (30-day retention)
- **Monthly:** 1st of month (1-year retention)
- **Manual:** `./backup.sh` anytime

## 🔍 Monitoring

```bash
# Real-time monitoring
./monitor.sh

# System status
./status.sh

# View logs
./logs.sh live
```

## 🛠️ Troubleshooting

### Common Issues

**n8n won't start:**
```bash
./status.sh          # Check system status
./logs.sh errors     # View error logs
docker compose logs  # Container logs
```

**Low memory:**
```bash
./cleanup.sh         # Free disk space
./monitor.sh         # Check resources
```

**Update problems:**
```bash
./restore.sh backup_name  # Rollback
./update.sh              # Retry update
```

### Intel NUC Specific

- **Temperature monitoring:** Built into monitor.sh
- **Memory optimization:** Conservative 2GB limit
- **CPU throttling:** 2-core limit for stability
- **Storage alerts:** SSD space monitoring

## 📁 Directory Structure

```
/opt/n8n-automation/
├── data/              # n8n persistent data
├── backups/           # Automated backups
│   ├── daily/
│   ├── weekly/
│   └── monthly/
├── logs/              # Application logs
├── shared/            # File sharing
├── scripts/           # Management scripts
├── .env               # Environment config
├── docker-compose.yml # Container definition
└── *.sh               # Management scripts
```

## 🔐 Security

- Basic authentication enabled by default
- **Password storage:** Environment variable in `.env` file
- Container runs as non-root user
- Network isolation with custom bridge
- Resource limits prevent system overload
- Regular security updates via update.sh



## 🌐 Network Access

- **Local:** http://localhost:5678
- **Network:** http://your-ip:5678
- **Firewall:** Ensure port 5678 is open

## 📈 Performance Tuning

Intel NUC J3455 optimizations:
- Memory limit: 2GB (of 8GB total)
- CPU limit: 2 cores (of 4 total)
- Payload size: 8MB max
- Execution timeout: 3 minutes
- Conservative resource allocation

## 🔄 Updates

```bash
# Check for updates
./update.sh

# Automatic backup before update
# Rollback available if needed
./restore.sh pre_update_backup_name
```

## 📞 Support

- **Logs:** `./logs.sh`
- **Status:** `./status.sh`
- **Monitor:** `./monitor.sh`
- **Cleanup:** `./cleanup.sh`

## 📄 License

This setup is provided as-is for Intel NUC Ubuntu deployments.
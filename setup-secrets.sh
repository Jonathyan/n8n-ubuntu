#!/bin/bash
# setup-secrets.sh - Setup secure password management

PROJECT_DIR="/opt/n8n-automation"
cd "$PROJECT_DIR"

# Create secrets directory
mkdir -p secrets
chmod 700 secrets

# Generate or update password
if [[ ! -f secrets/password.txt ]]; then
    # Generate new password
    secure_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo "$secure_password" > secrets/password.txt
    chmod 600 secrets/password.txt
    echo "✅ New password generated and stored in secrets/password.txt"
    echo "🔐 Password: $secure_password"
else
    echo "✅ Password file already exists"
fi

# Update .env to remove hardcoded password
if grep -q "N8N_BASIC_AUTH_PASSWORD=" .env; then
    sed -i 's/N8N_BASIC_AUTH_PASSWORD=.*/# N8N_BASIC_AUTH_PASSWORD stored in secrets\/password.txt/' .env
    echo "✅ Removed password from .env file"
fi
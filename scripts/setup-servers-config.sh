#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="$HOME/.servers-config"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Server Configuration Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if config already exists
if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${YELLOW}Config file already exists: $CONFIG_FILE${NC}"
    read -p "Overwrite? (y/n): " overwrite
    if [[ "$overwrite" != "y" ]]; then
        echo "Cancelled"
        exit 0
    fi
fi

echo ""
echo "Enter your DuckDNS subdomain prefix (e.g., 'myproject')"
echo "This will create: myproject-des.duckdns.org, myproject-pre.duckdns.org, etc."
read -p "Subdomain prefix: " prefix

echo ""
echo "Enter the path to your SSH keys directory (default: ~/.ssh)"
read -p "SSH keys directory [$HOME/.ssh]: " ssh_dir
ssh_dir="${ssh_dir:-$HOME/.ssh}"

echo ""
echo "Enter the SSH key filenames (without path):"
read -p "DES key filename [oracle-des.key]: " des_key
des_key="${des_key:-oracle-des.key}"

read -p "PRE key filename [oracle-pre.key]: " pre_key
pre_key="${pre_key:-oracle-pre.key}"

read -p "PRO key filename [oracle-pro.key]: " pro_key
pro_key="${pro_key:-oracle-pro.key}"

echo ""
echo "SSH username (default: ubuntu for Oracle Cloud):"
read -p "Username [ubuntu]: " username
username="${username:-ubuntu}"

# Create config file
cat > "$CONFIG_FILE" << EOF
# Server configuration for remote deployment
# Generated on $(date)

# DES (Development)
DES_HOST=${prefix}-des.duckdns.org
DES_KEY=${ssh_dir}/${des_key}
DES_USER=${username}

# PRE (Staging)
PRE_HOST=${prefix}-pre.duckdns.org
PRE_KEY=${ssh_dir}/${pre_key}
PRE_USER=${username}

# PRO (Production)
PRO_HOST=${prefix}-pro.duckdns.org
PRO_KEY=${ssh_dir}/${pro_key}
PRO_USER=${username}
EOF

echo ""
echo -e "${GREEN}✓ Configuration saved to: $CONFIG_FILE${NC}"
echo ""
echo "Contents:"
echo "----------------------------------------"
cat "$CONFIG_FILE"
echo "----------------------------------------"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Make sure your SSH keys are in place:"
echo "   - ${ssh_dir}/${des_key}"
echo "   - ${ssh_dir}/${pre_key}"
echo "   - ${ssh_dir}/${pro_key}"
echo ""
echo "2. Set correct permissions:"
echo "   chmod 600 ${ssh_dir}/*.key"
echo ""
echo "3. Setup each server:"
echo "   npm run remote:setup des"
echo "   npm run remote:setup pre"
echo "   npm run remote:setup pro"
echo ""
echo "4. Deploy:"
echo "   npm run remote:des"

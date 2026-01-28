#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config file
CONFIG_FILE="$HOME/.servers-config"

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Load server config
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Config file not found: $CONFIG_FILE"
        echo ""
        echo "Create it with:"
        echo ""
        cat << 'EXAMPLE'
cat > ~/.servers-config << 'EOF'
# Server configuration
DES_HOST=tuproyecto-des.duckdns.org
DES_KEY=~/.ssh/oracle-des.key
DES_USER=ubuntu

PRE_HOST=tuproyecto-pre.duckdns.org
PRE_KEY=~/.ssh/oracle-pre.key
PRE_USER=ubuntu

PRO_HOST=tuproyecto-pro.duckdns.org
PRO_KEY=~/.ssh/oracle-pro.key
PRO_USER=ubuntu
EOF
EXAMPLE
        exit 1
    fi
    source "$CONFIG_FILE"
}

# Run quality checks
run_quality_checks() {
    print_header "RUNNING QUALITY CHECKS"

    print_warning "Running lint..."
    if npm run lint 2>&1; then
        print_success "Lint passed"
    else
        print_error "Lint failed!"
        return 1
    fi

    print_warning "Running tests..."
    TEST_OUTPUT=$(npm run test -- --browsers=ChromeHeadless 2>&1)
    TEST_EXIT_CODE=$?

    if [[ $TEST_EXIT_CODE -ne 0 ]]; then
        echo "$TEST_OUTPUT"
        print_error "Tests failed!"
        return 1
    fi

    if echo "$TEST_OUTPUT" | grep -q "does not meet global threshold"; then
        print_error "Coverage below 80%!"
        return 1
    fi

    print_success "All checks passed"
    return 0
}

# Build Docker image
build_image() {
    local env=$1
    local image_name="angular-app-${env}"

    print_warning "Building Docker image for ${env}..."

    docker build \
        --build-arg ENVIRONMENT="${env}" \
        -t "${image_name}:latest" \
        -f Dockerfile .

    if [[ $? -eq 0 ]]; then
        print_success "Image built: ${image_name}:latest"
        return 0
    else
        print_error "Failed to build image"
        return 1
    fi
}

# Save and transfer image
transfer_image() {
    local env=$1
    local host=$2
    local key=$3
    local user=$4
    local image_name="angular-app-${env}"
    local tar_file="/tmp/${image_name}.tar"

    print_warning "Saving image to tar..."
    docker save "${image_name}:latest" > "${tar_file}"

    print_warning "Transferring to ${host}..."
    scp -i "${key}" -o StrictHostKeyChecking=no "${tar_file}" "${user}@${host}:~/app/"

    if [[ $? -eq 0 ]]; then
        print_success "Image transferred"
        rm "${tar_file}"
        return 0
    else
        print_error "Transfer failed"
        return 1
    fi
}

# Deploy on remote server
deploy_remote() {
    local env=$1
    local host=$2
    local key=$3
    local user=$4
    local image_name="angular-app-${env}"

    print_warning "Deploying on ${host}..."

    ssh -i "${key}" -o StrictHostKeyChecking=no "${user}@${host}" << REMOTE_SCRIPT
        cd ~/app

        # Load image
        echo "Loading Docker image..."
        docker load < ${image_name}.tar

        # Stop existing container
        docker stop ${image_name} 2>/dev/null || true
        docker rm ${image_name} 2>/dev/null || true

        # Run new container
        echo "Starting container..."
        docker run -d \
            --name ${image_name} \
            --restart unless-stopped \
            -p 80:80 \
            ${image_name}:latest

        # Cleanup
        rm ${image_name}.tar

        # Verify
        sleep 2
        if curl -s http://localhost/health > /dev/null 2>&1; then
            echo "✓ Health check passed"
        else
            echo "! Health check endpoint not found (may be normal)"
        fi

        docker ps | grep ${image_name}
REMOTE_SCRIPT

    if [[ $? -eq 0 ]]; then
        print_success "Deployed to ${host}"
        return 0
    else
        print_error "Deploy failed"
        return 1
    fi
}

# Full deploy pipeline
deploy_to_env() {
    local env=$1
    local host=$2
    local key=$3
    local user=$4

    print_header "DEPLOYING TO ${env^^}"

    echo "Target: ${host}"
    echo ""

    # Expand key path
    key="${key/#\~/$HOME}"

    # Check SSH key exists
    if [[ ! -f "$key" ]]; then
        print_error "SSH key not found: $key"
        exit 1
    fi

    # Check SSH connection
    print_warning "Testing SSH connection..."
    if ! ssh -i "${key}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${user}@${host}" "echo 'SSH OK'" 2>/dev/null; then
        print_error "Cannot connect to ${host}"
        exit 1
    fi
    print_success "SSH connection OK"

    # Build
    if ! build_image "${env}"; then
        exit 1
    fi

    # Transfer
    if ! transfer_image "${env}" "${host}" "${key}" "${user}"; then
        exit 1
    fi

    # Deploy
    if ! deploy_remote "${env}" "${host}" "${key}" "${user}"; then
        exit 1
    fi

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  ${env^^} DEPLOYED SUCCESSFULLY!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "URL: ${BLUE}http://${host}${NC}"
    echo ""
}

# Deploy to DES
deploy_des() {
    load_config

    # Quality checks first
    if ! run_quality_checks; then
        print_error "Quality checks failed. Fix issues before deploying."
        exit 1
    fi

    deploy_to_env "des" "$DES_HOST" "$DES_KEY" "$DES_USER"
}

# Deploy to PRE
deploy_pre() {
    load_config

    # Quality checks
    if ! run_quality_checks; then
        print_error "Quality checks failed. Fix issues before deploying."
        exit 1
    fi

    # Confirm
    echo -e "${YELLOW}You are about to deploy to PRE (staging)${NC}"
    read -p "Continue? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        print_warning "Cancelled"
        exit 0
    fi

    deploy_to_env "pre" "$PRE_HOST" "$PRE_KEY" "$PRE_USER"
}

# Deploy to PRO
deploy_pro() {
    load_config

    # Quality checks
    if ! run_quality_checks; then
        print_error "Quality checks failed. Fix issues before deploying."
        exit 1
    fi

    # Double confirm for production
    echo ""
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  WARNING: PRODUCTION DEPLOYMENT        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Target: $PRO_HOST"
    echo ""
    read -p "Type 'deploy-pro' to confirm: " confirm
    if [[ "$confirm" != "deploy-pro" ]]; then
        print_warning "Cancelled"
        exit 0
    fi

    deploy_to_env "pro" "$PRO_HOST" "$PRO_KEY" "$PRO_USER"
}

# Status of all servers
status() {
    load_config

    print_header "REMOTE SERVERS STATUS"

    for env in des pre pro; do
        local host_var="${env^^}_HOST"
        local key_var="${env^^}_KEY"
        local user_var="${env^^}_USER"
        local host="${!host_var}"
        local key="${!key_var}"
        local user="${!user_var}"

        key="${key/#\~/$HOME}"

        echo -e "${YELLOW}${env^^}:${NC} ${host}"

        if ssh -i "${key}" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${user}@${host}" \
            "docker ps --format '  Container: {{.Names}} | Status: {{.Status}}' 2>/dev/null | grep angular" 2>/dev/null; then

            if curl -s --connect-timeout 3 "http://${host}" > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓ HTTP OK${NC}"
            else
                echo -e "  ${RED}✗ HTTP Failed${NC}"
            fi
        else
            echo -e "  ${RED}✗ Not running or unreachable${NC}"
        fi
        echo ""
    done
}

# Setup a new server
setup_server() {
    load_config

    local env=$1
    local host_var="${env^^}_HOST"
    local key_var="${env^^}_KEY"
    local user_var="${env^^}_USER"
    local host="${!host_var}"
    local key="${!key_var}"
    local user="${!user_var}"

    key="${key/#\~/$HOME}"

    print_header "SETTING UP ${env^^} SERVER"

    echo "Target: ${host}"
    echo ""

    ssh -i "${key}" -o StrictHostKeyChecking=no "${user}@${host}" << 'SETUP_SCRIPT'
        set -e

        echo "Updating system..."
        sudo apt update && sudo apt upgrade -y

        echo "Installing Docker..."
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com | sudo sh
            sudo usermod -aG docker $USER
        fi

        echo "Installing Docker Compose..."
        sudo apt install -y docker-compose

        echo "Configuring firewall..."
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
        sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
        sudo netfilter-persistent save 2>/dev/null || true

        echo "Creating app directory..."
        mkdir -p ~/app

        echo ""
        echo "✓ Server setup complete!"
        docker --version
SETUP_SCRIPT

    print_success "${env^^} server is ready"
    print_warning "Reconnect via SSH for docker group to take effect"
}

# Show help
show_help() {
    echo "Remote Deployment Script"
    echo ""
    echo "Usage: $0 {des|pre|pro|status|setup}"
    echo ""
    echo "Commands:"
    echo "  des          Deploy to DES (development)"
    echo "  pre          Deploy to PRE (staging)"
    echo "  pro          Deploy to PRO (production)"
    echo "  status       Check status of all servers"
    echo "  setup <env>  Setup a new server (install Docker, etc.)"
    echo ""
    echo "Examples:"
    echo "  $0 des              # Deploy to development"
    echo "  $0 setup des        # Setup DES server"
    echo "  $0 status           # Check all servers"
    echo ""
    echo "Configuration:"
    echo "  Edit ~/.servers-config with your server details"
}

# Main
case "$1" in
    des)
        deploy_des
        ;;
    pre)
        deploy_pre
        ;;
    pro)
        deploy_pro
        ;;
    status)
        status
        ;;
    setup)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 setup {des|pre|pro}"
            exit 1
        fi
        setup_server "$2"
        ;;
    *)
        show_help
        exit 1
        ;;
esac

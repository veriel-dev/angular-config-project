#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

check_uncommitted_changes() {
    if [[ -n $(git status -s) ]]; then
        return 0  # Has changes
    else
        return 1  # No changes
    fi
}

# Deploy to DES
deploy_des() {
    print_header "DEPLOYING TO DES"

    # Ensure we're on develop
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "develop" ]]; then
        print_warning "Switching to develop branch..."
        git checkout develop
    fi

    # Check for uncommitted changes
    if check_uncommitted_changes; then
        print_warning "Uncommitted changes detected"
        read -p "Commit message: " commit_msg
        git add .
        git commit -m "$commit_msg"
        print_success "Changes committed"
    else
        print_warning "No changes to commit"
    fi

    # Push to origin
    print_warning "Pushing to origin/develop..."
    git push origin develop
    print_success "Pushed to origin/develop"

    # Rebuild and deploy DES container
    print_warning "Building and deploying DES container..."
    docker-compose up -d --build app-des
    print_success "DES deployed"

    # Health check
    sleep 2
    if curl -s http://localhost:4200/health > /dev/null; then
        print_success "DES is healthy"
        echo -e "\n${GREEN}DES deployed successfully!${NC}"
        echo -e "URL: ${BLUE}http://localhost:4200${NC}\n"
    else
        print_error "DES health check failed"
    fi
}

# Promote to PRE
promote_pre() {
    print_header "PROMOTING TO PRE"

    # Get version
    read -p "Release version (e.g., 1.2.0): " version
    release_branch="release/v$version"

    # Ensure we're on develop
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "develop" ]]; then
        git checkout develop
    fi

    # Check for uncommitted changes
    if check_uncommitted_changes; then
        print_error "You have uncommitted changes. Commit them first with: npm run deploy:des"
        exit 1
    fi

    # Create release branch
    print_warning "Creating branch $release_branch..."
    git checkout -b "$release_branch"
    print_success "Branch created"

    # Push release branch
    print_warning "Pushing to origin/$release_branch..."
    git push origin "$release_branch"
    print_success "Pushed to origin/$release_branch"

    # Rebuild and deploy PRE container
    print_warning "Building and deploying PRE container..."
    docker-compose up -d --build app-pre
    print_success "PRE deployed"

    # Health check
    sleep 2
    if curl -s http://localhost:4300/health > /dev/null; then
        print_success "PRE is healthy"
        echo -e "\n${GREEN}PRE deployed successfully!${NC}"
        echo -e "URL: ${BLUE}http://localhost:4300${NC}"
        echo -e "Branch: ${YELLOW}$release_branch${NC}\n"
    else
        print_error "PRE health check failed"
    fi
}

# Promote to PRO
promote_pro() {
    print_header "PROMOTING TO PRO"

    current_branch=$(git branch --show-current)

    # Check if we're on a release branch
    if [[ "$current_branch" != release/* ]]; then
        print_error "You must be on a release/* branch to promote to PRO"
        print_warning "Current branch: $current_branch"
        exit 1
    fi

    # Confirmation
    echo -e "${RED}WARNING: You are about to deploy to PRODUCTION${NC}"
    read -p "Type 'deploy' to confirm: " confirm
    if [[ "$confirm" != "deploy" ]]; then
        print_error "Deployment cancelled"
        exit 1
    fi

    # Merge to main
    print_warning "Switching to main..."
    git checkout main

    print_warning "Merging $current_branch into main..."
    git merge "$current_branch"
    print_success "Merged"

    # Push to main
    print_warning "Pushing to origin/main..."
    git push origin main
    print_success "Pushed to origin/main"

    # Rebuild and deploy PRO container
    print_warning "Building and deploying PRO container..."
    docker-compose up -d --build app-pro
    print_success "PRO deployed"

    # Health check
    sleep 2
    if curl -s http://localhost:4400/health > /dev/null; then
        print_success "PRO is healthy"
        echo -e "\n${GREEN}PRO deployed successfully!${NC}"
        echo -e "URL: ${BLUE}http://localhost:4400${NC}\n"
    else
        print_error "PRO health check failed"
    fi

    # Return to develop and sync
    print_warning "Syncing develop with main..."
    git checkout develop
    git merge main
    git push origin develop
    print_success "Develop synced"
}

# Status
status() {
    print_header "DEPLOYMENT STATUS"

    echo -e "${YELLOW}Git Status:${NC}"
    echo "  Branch: $(git branch --show-current)"
    echo "  Changes: $(git status -s | wc -l) files"
    echo ""

    echo -e "${YELLOW}Containers:${NC}"
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    echo ""

    echo -e "${YELLOW}Health Checks:${NC}"
    for port in 4200 4300 4400; do
        env_name="DES"
        [[ $port == 4300 ]] && env_name="PRE"
        [[ $port == 4400 ]] && env_name="PRO"

        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $env_name (localhost:$port)"
        else
            echo -e "  ${RED}✗${NC} $env_name (localhost:$port)"
        fi
    done
    echo ""
}

# Main
case "$1" in
    des)
        deploy_des
        ;;
    pre)
        promote_pre
        ;;
    pro)
        promote_pro
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {des|pre|pro|status}"
        echo ""
        echo "Commands:"
        echo "  des     Deploy changes to DES (from develop)"
        echo "  pre     Promote to PRE (creates release branch)"
        echo "  pro     Promote to PRO (merges to main)"
        echo "  status  Show deployment status"
        exit 1
        ;;
esac

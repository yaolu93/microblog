#!/bin/bash

# Set error handling
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper function for status messages
print_status() {
    echo -e "${GREEN}==> $1${NC}"
}

print_error() {
    echo -e "${RED}Error: $1${NC}"
}

# Check if there are any changes
if [[ -z $(git status -s) ]]; then
    print_status "No changes to commit"
    exit 0
fi

# Show current branch
current_branch=$(git branch --show-current)
print_status "Current branch: $current_branch"

# Fetch and pull latest changes
print_status "Fetching latest changes..."
git fetch origin

print_status "Pulling latest changes..."
if ! git pull origin "$current_branch"; then
    print_error "Failed to pull latest changes"
    exit 1
fi

# Add all changes
print_status "Adding changes..."
git add .

# Show what's being committed
print_status "Changes to be committed:"
git status -s

# Get commit message
read -p "Enter commit message (press enter to use 'update content'): " commit_msg
commit_msg=${commit_msg:-"update content"}

# Commit changes
print_status "Committing changes..."
if ! git commit -m "$commit_msg"; then
    print_error "Failed to commit changes"
    exit 1
fi

# Push changes
print_status "Pushing to remote..."
if ! git push origin "$current_branch"; then
    print_error "Failed to push changes"
    exit 1
fi

print_status "Successfully updated repository!"

# Show final status
print_status "Final status:"
git status
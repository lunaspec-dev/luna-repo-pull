#!/bin/bash
# 
# luna-repo-pull - GitHub Repository Clone/Fork Automation
# 
# Simplifies cloning repositories by:
# - Checking your active GitHub account
# - Cloning directly if it's your own repo
# - Forking first if it's someone else's repo
# - Creating a dev folder for your work
#
# Usage: luna-repo-pull [repo_url]

# Set these to whatever you want for your repo URL format and example URL
git_url_format="https://github.com/owner/repo.git"
example_url="https://github.com/torvalds/linux.git"

#### Change this to false if you don't want to create a dev folder
create_dev_folder=true
# the dev folder is just an easy scratchspace on a workspace setup that allows files to exist nearby, but outside of git tracking.
# useful for testing and experimentation, but not necessary for everyone.

# ===== HELP FUNCTION =====
show_help() {
    echo "luna-repo-pull - GitHub Repository Clone/Fork Automation"
    echo ""
    echo "Usage: luna-repo-pull [repo_url]"
    echo ""
    echo "Arguments:"
    echo "  repo_url    Optional GitHub repository URL (e.g., $git_url_format)"
    echo "  --help      Display this help message"
    echo ""
    echo "Examples:"
    echo "  luna-repo-pull"
    echo "  luna-repo-pull $example_url"
}

# ===== PARAMETER HANDLING =====
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# ===== CHECK GITHUB CLI INSTALLATION =====
# Verify that gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    echo "Or, in CLI, run:"
    echo "  brew install gh  # macOS"
    echo "  sudo apt install gh  # Ubuntu/Debian"
    echo "  winget install GitHub.cli  # Windows"
    exit 1
fi

echo ""
echo "--------------------"
echo luna-repo-pull Ready

# ===== CHECK GITHUB AUTHENTICATION =====
# Get current auth status and display logged-in accounts
gh_auth_status=$(gh auth status 2>&1)

# Exit if gh CLI authentication failed
if [ $? -ne 0 ]; then
    echo "Error: GitHub CLI authentication failed. Please run 'gh auth login' first."
    exit 1
fi

echo "--- Auth Status ---"
echo "$gh_auth_status" | grep -E "Active account:|Logged in to"
echo "-------------------"

# Extract and display the active account
active_account=$(echo "$gh_auth_status" | grep -B 1 "Active account: true" | grep "Logged in to" | awk '{print $7}')
echo "Active account: $active_account"

# ===== CONFIRM ACCOUNT =====
# Ask user if they want to switch GitHub accounts
echo "Would you like to switch GitHub accounts? (y/n)"
read -r switch_account

if [[ "$switch_account" == "y" ]]; then
    gh auth switch
    if [ $? -ne 0 ]; then
        echo "Error: Failed to switch accounts."
        exit 1
    fi
    
    # Update active account after switching
    active_account=$(gh auth status 2>&1 | grep -B 1 "Active account: true" | grep "Logged in to" | awk '{print $7}')
    echo "Account switched to: $active_account"
fi

# ===== GET REPOSITORY URL =====
# Check if repo URL was provided as argument, otherwise prompt
if [ -n "$1" ]; then
    repo_url="$1"
    echo "Using provided repository URL: $repo_url"
else
    read -p "Enter the repository URL you would like to pull: " repo_url
fi

# ===== VALIDATE REPOSITORY URL =====
# Extract repo name and owner from the URL
if [ -z "$repo_url" ]; then
    echo "Error: Repository URL cannot be empty."
    exit 1
fi

repo_name=$(basename "$repo_url" .git)
repo_owner=$(basename "$(dirname "$repo_url")")

if [ -z "$repo_name" ] || [ -z "$repo_owner" ]; then
    echo "Error: Invalid repository URL format. Expected: $git_url_format"
    echo "Example: $example_url"
    exit 1
fi

# ===== VERIFY REPOSITORY EXISTS =====
# Check if the repository is accessible and valid
echo "Verifying repository exists..."
if ! gh repo view "$repo_owner/$repo_name" &> /dev/null; then
    echo "Error: Repository '$repo_owner/$repo_name' not found or not accessible."
    echo "Please verify the URL and your GitHub authentication."
    exit 1
fi
echo "Repository verified!"

echo "Pulling repository: $repo_name from owner: $repo_owner"
read -p "Please enter the path where you would like to clone the repo: " clone_path

# ===== DETERMINE CLONE STRATEGY =====
# Check if repo is owned by active account or needs forking
# ===== Simple Clone for Own Repo =====
if [ "$repo_owner" == "$active_account" ]; then
    # OWN REPO: Clone directly
    echo "This is your own repo! We can pull it directly."
    
    gh repo clone "$repo_owner/$repo_name" "$clone_path/$repo_name"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone the repository."
        exit 1
    fi

    echo "Repository cloned successfully to $clone_path/$repo_name"

# ==== Fork and Clone for Others' Repo =====
else
    # FORKED REPO: Fork first, then clone
    echo "This is not your own repo! We will need to fork it first."
    
    # Step 1: Fork the repository (skip clone prompt by answering 'n')
    echo "n" | gh repo fork "$repo_owner/$repo_name"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fork the repository."
        exit 1
    fi
    
    echo "Forked successfully. Now cloning your fork..."
    
    # Step 2: Clone your fork (now it's in your account)
    mkdir -p "$clone_path"
    gh repo clone "$active_account/$repo_name" "$clone_path/$repo_name"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone the forked repository."
        exit 1
    fi

    echo "Repository forked and cloned successfully to $clone_path/$repo_name"
fi

# ===== SETUP WORK ENVIRONMENT =====
# Create dev folder for experimentation
if [ "$create_dev_folder" = true ]; then
    mkdir -p "$clone_path/dev"
    echo "Created dev directory in $clone_path"
fi

echo "repo fork/clone process completed successfully for $repo_name."
echo "cd \"$clone_path/$repo_name\" to start working on your repo."
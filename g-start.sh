#!/usr/bin/env bash
# g-start.sh — Create a new feature branch from 'main' or 'master'
#
# Behavior:
#   1. Ensures we are in a Git repo
#   2. Detects the primary branch: 'main' or 'master'
#   3. Verifies a '.gitignore' file exists at the repo root
#   4. Ensures the working directory is clean (no uncommitted changes)
#   5. Creates and switches to a new branch:
#      feat/<sanitized-name>-<YYMMDDHHMM>
#
# Usage:
#   ./g-start.sh <branch-name>
# Example:
#   ./g-start.sh login-form
# Result:
#   feat/login-form-2404181530 created and checked out
#
set -euo pipefail

# Print usage help
print_usage() {
  cat <<EOF
Usage: $(basename "$0") <branch-name>

Creates a new feature branch from the primary branch ('main' or 'master').
Checks:
  • Inside a Git repository
  • Primary branch exists
  • .gitignore exists in project root
  • Working directory is clean
EOF
}

# 1. Ensure we're in a Git repo
ensure_git_repo() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a Git repository." >&2
    exit 1
  fi
}

# 2. Detect whether 'main' or 'master' is the primary branch
detect_primary_branch() {
  if git show-ref --verify --quiet refs/heads/main; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master; then
    echo "master"
  else
    echo "Error: Neither 'main' nor 'master' branch found." >&2
    exit 1
  fi
}

# 3. Ensure a .gitignore file exists at the root
ensure_gitignore() {
  local root
  root=$(git rev-parse --show-toplevel)
  if [[ ! -f "$root/.gitignore" ]]; then
    echo "Warning: .gitignore is missing at the repository root ($root)." >&2
  fi
}

# 4. Ensure no unstaged or staged changes exist
require_clean_branch() {
  local has_changes=0
  
  echo "Checking for uncommitted changes..."
  
  # Check for unstaged changes
  if ! git diff --quiet; then
    echo "Error: You have unstaged changes." >&2
    has_changes=1
  fi
  
  # Check for staged changes
  if ! git diff --cached --quiet; then
    echo "Error: You have staged changes that are not committed." >&2
    has_changes=1
  fi
  
  # Check for untracked files
  if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "Error: You have untracked files." >&2
    has_changes=1
  fi
  
  if [ $has_changes -eq 1 ]; then
    echo "Please commit or stash your changes before creating a new branch." >&2
    git status --short
    exit 1
  fi
  
  echo "Working directory clean. Proceeding..."
}

main() {
  # Check for required argument
  [[ $# -eq 1 ]] || { print_usage; exit 1; }
  local name="$1"

  # Perform all pre-checks
  ensure_git_repo
  local primary
  primary=$(detect_primary_branch)
  ensure_gitignore
  require_clean_branch

  # Sanitize the branch name and append timestamp
  local ts sanitized new_branch
  ts=$(date +%y%m%d%H%M)
  sanitized=$(echo "$name" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9_-]/-/g' \
    | sed 's/-\+/-/g' \
    | sed 's/^-//' | sed 's/-$//')
  new_branch="feat/${sanitized}-${ts}"

  # Prevent clobbering an existing branch
  if git show-ref --verify --quiet "refs/heads/$new_branch"; then
    echo "Error: Branch '$new_branch' already exists." >&2
    exit 1
  fi

  # Create and switch to the new branch from the primary
  git checkout "$primary"
  git checkout -b "$new_branch"
  echo "✅ Created and switched to branch '$new_branch' from '$primary'."
}

main "$@"

#!/usr/bin/env bash
# g-publish.sh — Push current branch, test it, open PR and enable auto-merge
#
# Behavior:
#   1. Ensure we are in a Git repo and current branch is clean
#   2. Run npm install + AVA test suite
#   3. Push current branch to origin
#   4. If on feature branch:
#       - Open pull request against 'main'
#       - Enable auto-merge (squash)
#   5. If already on 'main':
#       - Just push (auto-deploy via GitHub Actions should handle it)
#
# Usage:
#   ./g-publish.sh
#
set -euo pipefail

# Ensure we're inside a Git repo
ensure_git_repo() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a Git repository." >&2
    exit 1
  fi
}

# Ensure working directory is clean
require_clean_branch() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: You have uncommitted changes. Please commit or stash them first." >&2
    exit 1
  fi
}

# Get current branch name
get_current_branch() {
  git rev-parse --abbrev-ref HEAD
}

main() {
  ensure_git_repo
  require_clean_branch

  local branch
  branch=$(get_current_branch)

  echo "🧪 Running tests on branch '$branch'..."
  npm ci
  npx ava

  echo "🚀 Pushing '$branch' to origin..."
  git push -u origin "$branch"

  if [[ "$branch" == "main" || "$branch" == "master" ]]; then
    echo "✅ '$branch' pushed. CI/CD should handle deploy via GitHub Actions."
    exit 0
  fi

  echo "🔁 Creating pull request targeting 'main' and enabling auto-merge..."
  gh pr create --fill --label automerge --base main || echo "⚠️ PR may already exist. Continuing..."
  gh pr merge --squash --auto || echo "⚠️ Could not enable auto-merge. Check GitHub manually."

  echo "✅ Publish process completed for '$branch'."
}

main "$@"

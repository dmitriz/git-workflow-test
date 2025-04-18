#!/usr/bin/env bash
# g-publish.sh — Push current branch, run tests, auto-PR + auto-merge
# For use with pnpm (instead of npm)
#
# Usage: ./g-publish.sh
#
# Steps:
#   1. Ensure clean Git repo
#   2. Run `pnpm install` and `pnpm test`
#   3. Push branch
#   4. Open PR and enable auto-merge (if not main)
#   5. Push main triggers deploy via CI

set -euo pipefail

# Ensure inside a Git repo
ensure_git_repo() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ Not inside a Git repository." >&2
    exit 1
  fi
}

# Detect primary branch (main or master)
detect_primary_branch() {
  if git show-ref --verify --quiet refs/remotes/origin/main; then
    echo "main"
  elif git show-ref --verify --quiet refs/remotes/origin/master; then
    echo "master"
  else
    echo "master" # Default to master if neither is found
  fi
}

# Ensure clean working tree
require_clean_branch() {
  if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "❌ You have uncommitted changes. Please commit or stash them first." >&2
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

  if ! command -v pnpm &>/dev/null; then
    echo "❌ pnpm not found. Please install pnpm to continue." >&2
    exit 1
  fi

  local branch primary_branch
  branch=$(get_current_branch)
  primary_branch=$(detect_primary_branch)

  echo "📦 Installing deps via pnpm..."
  pnpm install

  echo "🧪 Running tests (pnpm test)..."
  pnpm test

  echo "🚀 Pushing '$branch' to origin..."
  git push -u origin "$branch"

  if [[ "$branch" == "main" || "$branch" == "master" ]]; then
    echo "✅ '$branch' pushed. CI will deploy."
    exit 0
  fi

  echo "🔄 Fetching latest from remote..."
  git fetch --all --prune --quiet || echo "⚠️ Failed to fetch remotes, continuing anyway"

  echo "🔁 Creating PR to '$primary_branch' and enabling auto-merge..."
  set +e
  pr_output=$(gh pr create --fill --base "$primary_branch" --head "$branch" --label automerge 2>&1)
  pr_status=$?
  set -e
  if [ $pr_status -ne 0 ]; then
    if echo "$pr_output" | grep -q "already exists"; then
      echo "⚠️ A PR for branch '$branch' already exists."
    else
      echo "❌ Failed to create PR: $pr_output" >&2
      exit $pr_status
    fi
  fi

  echo "🔀 Enabling auto-merge on PR..."
  set +e
  merge_output=$(gh pr merge --squash --auto 2>&1)
  merge_status=$?
  set -e
  if [ $merge_status -ne 0 ]; then
    echo "❌ Failed to enable auto-merge: $merge_output" >&2
    exit $merge_status
  fi

  echo "✅ Publish complete for '$branch'."
}

main "$@"

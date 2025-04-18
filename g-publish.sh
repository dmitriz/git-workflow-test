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

  local branch
  branch=$(get_current_branch)

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

  echo "🔁 Creating PR to 'main' and enabling auto-merge..."
  gh pr create --fill --label automerge --base main || echo "⚠️ PR may already exist."
  gh pr merge --squash --auto || echo "⚠️ Auto-merge may have failed. Check GitHub."

  echo "✅ Publish complete for '$branch'."
}

main "$@"

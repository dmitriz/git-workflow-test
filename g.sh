#!/usr/bin/env bash
# Minimal Git workflow script (Step 1 of 5)
# Only: publish command (test, push, PR, auto-merge/deploy)
# Usage: g publish

set -euo pipefail

# Ensure no uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: uncommitted changes. Commit or stash first."
  exit 1
fi

# Publish workflow
npm ci
npx ava

target_branch=$(git rev-parse --abbrev-ref HEAD)

echo "Pushing '$target_branch' to origin..."
git push -u origin HEAD

if [[ "$target_branch" == "main" ]]; then
  echo "Main updated; CI and deploy will trigger via GitHub Actions."
  exit 0
fi

echo "Creating or updating Pull Request for '$target_branch'..."
gh pr create --fill --label automerge --base main || true

echo "Enabling auto-merge..."
gh pr merge --squash --auto || true

echo "Publish complete."

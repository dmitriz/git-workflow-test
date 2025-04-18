#!/usr/bin/env bash
# deploy.sh — Unified deploy script for Vercel
# Usable in CI or locally
#
# Requirements:
#   - VERCEL_TOKEN must be set (env var or GitHub Secret)
#   - Project must be linked with Vercel (see below)

set -euo pipefail

# Load local env vars from .env if present
if [ -f .env ]; then
  # shellcheck source=/dev/null
  set -a
  . ./.env
  set +a
fi

# Ensure token is available
if [[ -z "${VERCEL_TOKEN:-}" ]]; then
  echo "❌ VERCEL_TOKEN is not set."
  exit 1
fi

echo "🚀 Deploying with Vercel..."
# replace:
# pnpm run build || echo "ℹ️ No build script defined; skipping."

if pnpm run build; then
  :
elif grep -q "Missing script" <<< "$(pnpm run build 2>&1)"; then
  echo "ℹ️ No build script defined; skipping."
else
  echo "❌ Build failed. Aborting." >&2
  exit 1
fi
# Production deploy (assumes Vercel project already linked)
pnpm install
pnpm run build || echo "ℹ️ No build script defined; skipping."

npx vercel --prod --token "$VERCEL_TOKEN"

echo "✅ Deployed to production via Vercel."

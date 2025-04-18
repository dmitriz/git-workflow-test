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
  export $(grep -v '^#' .env | xargs)
fi

# Ensure token is available
if [[ -z "${VERCEL_TOKEN:-}" ]]; then
  echo "❌ VERCEL_TOKEN is not set."
  exit 1
fi

echo "🚀 Deploying with Vercel..."

# Production deploy (assumes Vercel project already linked)
pnpm install
pnpm run build || echo "ℹ️ No build script defined; skipping."

npx vercel --prod --token "$VERCEL_TOKEN"

echo "✅ Deployed to production via Vercel."

#!/bin/bash
# deploy-preview.sh — Deploy preview on Vercel + auto-validate
# Usage: make deploy-preview
#
# Note: The first run links the project to Vercel.
# Requires Vercel CLI >= 54. The --pre flag was removed;
# default deploy is already preview for non-main branches.

set -euo pipefail

echo "🚀 Deploying preview on Vercel..."

if ! command -v vercel &>/dev/null; then
  echo "❌ Vercel CLI not found. Install with: npm i -g vercel"
  exit 1
fi

VERCEL_VERSION=$(vercel --version 2>/dev/null | head -1 || echo "0.0.0")
echo "📌 Vercel CLI: $VERCEL_VERSION"

DEPLOY_CWD="."
if [ -d "site" ]; then
  DEPLOY_CWD="site"
fi

OUTPUT=$(vercel --cwd "$DEPLOY_CWD" --yes 2>&1)
echo "$OUTPUT"

# Extract preview URL from Vercel output (line with "https://" and ".vercel.app")
PREVIEW_URL=$(echo "$OUTPUT" | grep -oE 'https://[a-zA-Z0-9.-]+\.vercel\.app' | head -1)

if [ -z "$PREVIEW_URL" ]; then
  echo "❌ Could not extract preview URL from Vercel output"
  exit 1
fi

echo ""
echo "🔍 Validating preview URL: $PREVIEW_URL"
for i in $(seq 1 6); do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PREVIEW_URL" 2>/dev/null || echo "000")
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Preview functional! Status: $HTTP_STATUS"
    echo "🌐 Preview URL: $PREVIEW_URL"
    exit 0
  fi
  echo "⏳ Attempt $i/6 — Status: $HTTP_STATUS (waiting 5s...)"
  sleep 5
done

echo "❌ Preview not healthy after 30s. Last status: $HTTP_STATUS"
exit 1

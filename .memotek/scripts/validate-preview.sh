#!/bin/bash
# validate-preview.sh — Test preview URL via HTTP
# Usage: make test-preview PREVIEW_URL="<url>"

set -euo pipefail

PREVIEW_URL="${PREVIEW_URL:-}"

if [ -z "$PREVIEW_URL" ]; then
  # Try to get from Vercel
  if [ -f ".vercel/project.json" ]; then
    PREVIEW_URL=$(cat .vercel/project.json | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
  fi
  
  if [ -z "$PREVIEW_URL" ]; then
    echo "❌ PREVIEW_URL is required"
    echo "Usage: make test-preview PREVIEW_URL='https://preview-abc.vercel.app'"
    exit 1
  fi
fi

echo "🌐 Testing preview URL: $PREVIEW_URL"

# Test if it returns 200
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PREVIEW_URL" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Preview functional! Status: $HTTP_STATUS"
  exit 0
else
  echo "❌ Preview has issues. Status: $HTTP_STATUS"
  exit 1
fi

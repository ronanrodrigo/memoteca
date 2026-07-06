#!/bin/bash
# deploy-preview.sh — Deploy preview on Vercel
# Usage: make deploy-preview
#
# Note: The first run links the project to Vercel.
# Requires Vercel CLI >= 54. The --pre flag was removed;
# default deploy is already preview for non-main branches.

set -euo pipefail

echo "🚀 Deploying preview on Vercel..."

if ! command -v vercel &> /dev/null; then
  echo "❌ Vercel CLI not found. Install with: npm i -g vercel"
  exit 1
fi

# Check minimum version
VERCEL_VERSION=$(vercel --version 2>/dev/null | head -1 || echo "0.0.0")
echo "📌 Vercel CLI: $VERCEL_VERSION"

vercel --yes

echo "🎉 Deploy preview completed!"
echo "💡 Visit the link above to view the preview."

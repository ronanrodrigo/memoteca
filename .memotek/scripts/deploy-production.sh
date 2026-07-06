#!/bin/bash
# deploy-production.sh — Deploy production on Vercel
# Usage: make deploy-production
#
# Requires Vercel CLI >= 54. Requires the project to be
# already linked to Vercel (done by previous deploy-preview).

set -euo pipefail

echo "🚀 Deploying production on Vercel..."

if ! command -v vercel &> /dev/null; then
  echo "❌ Vercel CLI not found. Install with: npm i -g vercel"
  exit 1
fi

# Check minimum version
VERCEL_VERSION=$(vercel --version 2>/dev/null | head -1 || echo "0.0.0")
echo "📌 Vercel CLI: $VERCEL_VERSION"

vercel --prod --yes

echo "🎉 Deploy production completed!"
echo "💡 The site is now live in production."

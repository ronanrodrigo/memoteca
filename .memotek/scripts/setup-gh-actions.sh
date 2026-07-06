#!/bin/bash
# setup-gh-actions.sh — Configure CI/CD workflows
# Usage: make gh-actions-setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

echo "⚙️ Configuring GitHub Actions..."

# Create workflows directory if it doesn't exist
mkdir -p .github/workflows

# Copy templates
if [ -f "$TEMPLATES_DIR/deploy.yml" ]; then
  cp "$TEMPLATES_DIR/deploy.yml" .github/workflows/deploy.yml
  echo "✅ Deploy workflow created"
fi

if [ -f "$TEMPLATES_DIR/test.yml" ]; then
  cp "$TEMPLATES_DIR/test.yml" .github/workflows/test.yml
  echo "✅ Test workflow created"
fi

echo "🎉 GitHub Actions configured successfully!"
echo "📁 Workflows created in .github/workflows/"

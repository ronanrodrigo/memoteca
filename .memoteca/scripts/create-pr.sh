#!/bin/bash
# create-pr.sh — Create Pull Request
# Usage: make pr-create TITLE="<title>" BODY="<body>" HEAD="<branch>" BASE="<branch>"

set -euo pipefail

TITLE="${TITLE:-}"
BODY="${BODY:-}"
HEAD="${HEAD:-$(git branch --show-current)}"
BASE="${BASE:-main}"

if [ -z "$TITLE" ]; then
  echo "❌ TITLE is required"
  echo "Usage: make pr-create TITLE='feat: add color field' HEAD='feature/color' BASE='main'"
  exit 1
fi

echo "📦 Creating Pull Request..."
echo "   Branch: $HEAD → $BASE"
echo "   Title: $TITLE"

gh pr create \
  --title "$TITLE" \
  --body "$BODY" \
  --head "$HEAD" \
  --base "$BASE"

echo "🎉 Pull Request created successfully!"

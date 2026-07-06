#!/bin/bash
# search-projects.sh — Search for similar projects on GitHub
# Usage: make search-projects QUERY="<keywords>"

set -euo pipefail

QUERY="${QUERY:-}"

if [ -z "$QUERY" ]; then
  echo "❌ QUERY is required"
  echo "Usage: make search-projects QUERY='chemical registration system'"
  exit 1
fi

echo "🔍 Searching for similar projects: $QUERY"
echo "---"

# Use gh search repos
gh search repos "$QUERY" --limit 10 --sort stars --json fullName,stargazersCount,description,url \
  --template '{{range .}}{{.fullName}} | ⭐ {{.stargazersCount}} | {{.description}} | {{.url}}{{"\n"}}{{end}}'

echo ""
echo "📊 Search completed. Top 10 projects by stars."

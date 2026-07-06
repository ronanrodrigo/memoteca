#!/bin/bash
# listen-issues.sh — Polling of open issues
# Usage: make listen-issues

set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
  echo "❌ Could not detect the repository."
  exit 1
fi

echo "🔔 Checking open issues in $REPO..."

# List open issues with 'memotek' label
ISSUES=$(gh issue list --state open --label "memotek" --json number,title,labels \
  --template '{{range .}}#{{.number}} - {{.title}}{{"\n"}}{{end}}' 2>/dev/null || echo "")

if [ -z "$ISSUES" ]; then
  echo "📭 No pending issues found."
  exit 0
fi

echo "📋 Issues found:"
echo "$ISSUES"
echo ""
echo "💡 To process an issue, run:"
echo "   make process-issue ISSUE_NUMBER=<number>"

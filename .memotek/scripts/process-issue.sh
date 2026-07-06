#!/bin/bash
# process-issue.sh — Process a GitHub issue
# Usage: make process-issue ISSUE_NUMBER=<num>

set -euo pipefail

ISSUE_NUMBER="${ISSUE_NUMBER:-}"

if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ ISSUE_NUMBER is required"
  echo "Usage: make process-issue ISSUE_NUMBER=1"
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
  echo "❌ Could not detect the repository."
  exit 1
fi

echo "📋 Fetching issue #$ISSUE_NUMBER in $REPO..."

# Fetch issue details
ISSUE_TITLE=$(gh issue view "$ISSUE_NUMBER" --json title -q '.title')
ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --json body -q '.body')
ISSUE_LABELS=$(gh issue view "$ISSUE_NUMBER" --json labels -q '.labels[].name')

echo ""
echo "📌 Issue #$ISSUE_NUMBER: $ISSUE_TITLE"
echo "🏷️  Labels: $ISSUE_LABELS"
echo ""
echo "--- Issue Body ---"
echo "$ISSUE_BODY"
echo "--- End ---"
echo ""
echo "💡 To process this issue, run the make targets in order:"
echo "   1. make search-projects QUERY=\"$ISSUE_TITLE\""
echo "   2. make scaffold PROJECT_NAME=\".\""
echo "   3. make gh-actions-setup"
echo "   4. make deploy-preview"
echo "   5. make pr-create TITLE=\"feat: $ISSUE_TITLE\""
echo "   6. make memory-update ISSUE_NUMBER=$ISSUE_NUMBER CHECKBOX=\"Pipeline complete\""

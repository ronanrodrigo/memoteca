#!/bin/bash
# process-issue.sh — Fetch a GitHub issue (cross-repo) and print next make commands.
# Usage:
#   make process-issue ISSUE_URL=<url>             # full URL
#   make process-issue ISSUE_URL=42                # current repo
#   make process-issue ISSUE_URL=owner/repo#42
#   (legacy) make process-issue ISSUE_NUMBER=42    # current repo (kept for back-compat)

set -euo pipefail

INPUT_URL="${ISSUE_URL:-}"
INPUT_NUM="${ISSUE_NUMBER:-}"

REPO=""
NN=""

# ─ 1. Resolve the issue's repo + number ─────────────────────────────────
if [[ "$INPUT_URL" =~ ^https?://github\.com/([^/]+/[^/]+)/(issues|pull)/([0-9]+) ]]; then
  REPO="${BASH_REMATCH[1]}"
  NN="${BASH_REMATCH[3]}"
elif [[ "$INPUT_URL" =~ ^([A-Za-z0-9._-]+/[A-Za-z0-9._-]+)#([0-9]+)$ ]]; then
  REPO="${BASH_REMATCH[1]}"
  NN="${BASH_REMATCH[2]}"
elif [[ "$INPUT_URL" =~ ^[0-9]+$ ]]; then
  NN="$INPUT_URL"
elif [ -z "$INPUT_URL" ] && [[ "$INPUT_NUM" =~ ^[0-9]+$ ]]; then
  NN="$INPUT_NUM"
else
  echo "❌ Either ISSUE_URL or ISSUE_NUMBER (numeric) is required."
  echo "   Examples:"
  echo "     make process-issue ISSUE_URL=https://github.com/owner/repo/issues/12"
  echo "     make process-issue ISSUE_URL=owner/repo#12"
  echo "     make process-issue ISSUE_URL=12"
  echo "     make process-issue ISSUE_NUMBER=12   (legacy, current repo)"
  exit 1
fi

if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
  if [ -z "$REPO" ]; then
    echo "❌ Could not detect the current repo. Pass a full URL or owner/repo#NN."
    exit 1
  fi
fi

# ─ 2. Fetch issue metadata (cross-repo via -R) ─────────────────────────
echo "📋 Fetching issue #$NN in $REPO..."

if ! gh issue view "$NN" --repo "$REPO" --json title,body,labels,url >/dev/null 2>&1; then
  echo "❌ Issue #$NN not found in $REPO (or no read access)."
  exit 1
fi

ISSUE_TITLE=$(gh issue view "$NN" --repo "$REPO" --json title -q '.title')
ISSUE_BODY=$(gh issue view "$NN" --repo "$REPO" --json body -q '.body')
ISSUE_LABELS=$(gh issue view "$NN" --repo "$REPO" --json labels -q '.labels[].name' 2>/dev/null | tr '\n' ' ')
ISSUE_URL=$(gh issue view "$NN" --repo "$REPO" --json url -q '.url')

echo ""
echo "📌 $REPO#$NN — $ISSUE_TITLE"
echo "🏷️  Labels: $ISSUE_LABELS"
echo "🔗 $ISSUE_URL"
echo ""
echo "--- Issue Body ---"
echo "$ISSUE_BODY"
echo "--- End ---"
echo ""
echo "💡 To process this issue, follow the Assistant Work Loop and use the make targets in order:"
echo "   1. (if cross-repo) be inside a worktree of $REPO — see AGENTS.md (workspace dir)"
echo "   2. make search-projects QUERY=\"$ISSUE_TITLE\""
echo "   3. make scaffold PROJECT_NAME=\".\"            # for Project Creation only"
echo "   4. make gh-actions-setup && make deploy-preview"
echo "   5. make gcp-and-gpr MESSAGE=\"feat: <desc> (#$NN)\" TITLE=\"feat: <desc>\""
echo "   6. make pr-merge PR_NUMBER=<num>"
echo "   7. make memory-update ISSUE_NUMBER=$NN CHECKBOX=\"All checks green\" COMMENT=\"...\""
echo "   8. make memory-finalize ISSUE_NUMBER=$NN"
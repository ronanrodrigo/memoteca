#!/bin/bash
# project-link-repo.sh — Link a repository to the central "Memoteca" board.
# After linking, issues from that repo can be added to the board via
# `make project-add-issue`. Running once per target repo is enough.
#
# Usage:
#   make project-link-repo                       # links the current repo
#   make project-link-repo REPO=<owner>/<name>   # links a specific repo
#
# NOTE: GitHub's Web UI offers an optional "Auto-add issues with the `memotek` label"
# workflow on the linked project. The GraphQL/CLI does NOT support creating that
# workflow programmatically. If you want full automation by label, configure it
# once via the Projects V2 web UI (Project → ⋯ → Workflows → Add issue → filter
# label = memotek). The template relies on the explicit `make project-add-issue`
# call from the intake flow as the default path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/project-common.sh"

memotek_load_project
PN="$MEMOTEK_PROJECT_NUMBER"

REPO="${REPO:-}"
if [ -z "$REPO" ]; then
  # default to the current repo
  REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
  if [ -z "$REPO" ]; then
    echo "❌ Could not detect the current repo. Pass REPO=<owner>/<name>."
    exit 1
  fi
fi

echo "🔗 Linking $REPO to board \"$MEMOTEK_PROJECT_TITLE\" (#$PN)..."
if gh project link "$PN" --owner "@me" --repo "$REPO" 2>&1; then
  echo "✅ $REPO linked."
  echo ""
  echo "💬 Issues from $REPO can now be added to the board via:"
  echo "   make project-add-issue ISSUE_URL=https://github.com/$REPO/issues/<NN>"
  echo ""
  echo "💡 (Optional) For auto-add on the \`memotek\` label, configure it in the"
  echo "   GitHub Projects V2 web UI under the project's Workflows settings."
else
  echo "⚠️  Link may already exist, or linking failed. Sample linking is idempotent — safe to ignore above error."
fi
#!/bin/bash
# update-memory.sh — Update issue with progress (checkboxes, status, comments)
# AND mirror the corresponding pipeline stage to the central "Memoteca" board
# Status single-select (8 stages).
#
# The issue lives in the TARGET repo. This script runs from inside the worktree
# of that repo (Orchestrator's fixed workspace dir + clone-on-demand). It also
# accepts ISSUE_URL=<owner/repo#NN> for cross-repo use from outside the worktree.
#
# Usage:
#   make memory-update ISSUE_NUMBER=<num> CHECKBOX="<text>"
#   make memory-update ISSUE_NUMBER=<num> CHECKBOX="<text>" COMMENT="<comment>"
#   make memory-update ISSUE_NUMBER=<num> STATUS="<status>"
#   make memory-update ISSUE_NUMBER=<num> FINALIZE=1   # check ALL checkboxes + close
#   make memory-update ISSUE_URL=<owner/repo#NN> CHECKBOX="..."   # cross-repo
#
# The CHECKBOX must match the exact checkbox text in the issue body
# (after "- [ ] "). Special characters are handled correctly (Node, not sed).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ISSUE_NUMBER="${ISSUE_NUMBER:-}"
ISSUE_URL_INPUT="${ISSUE_URL:-}"
CHECKBOX="${CHECKBOX:-}"
COMMENT="${COMMENT:-}"
STATUS="${STATUS:-}"
FINALIZE="${FINALIZE:-0}"

# ─ 1. Resolve (REPO, NN) from ISSUE_URL or ISSUE_NUMBER ─────────────────
REPO=""
NN=""
if [ -n "$ISSUE_URL_INPUT" ]; then
  if [[ "$ISSUE_URL_INPUT" =~ ^https?://github\.com/([^/]+/[^/]+)/(issues|pull)/([0-9]+) ]]; then
    REPO="${BASH_REMATCH[1]}"; NN="${BASH_REMATCH[3]}"
  elif [[ "$ISSUE_URL_INPUT" =~ ^([A-Za-z0-9._-]+/[A-Za-z0-9._-]+)#([0-9]+)$ ]]; then
    REPO="${BASH_REMATCH[1]}"; NN="${BASH_REMATCH[2]}"
  elif [[ "$ISSUE_URL_INPUT" =~ ^[0-9]+$ ]]; then
    NN="$ISSUE_URL_INPUT"
  else
    echo "❌ Could not parse ISSUE_URL=\"$ISSUE_URL_INPUT\"."
    exit 1
  fi
elif [ -n "$ISSUE_NUMBER" ]; then
  if [[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
    NN="$ISSUE_NUMBER"
  else
    echo "❌ ISSUE_NUMBER must be numeric (or pass ISSUE_URL=owner/repo#NN)."
    exit 1
  fi
else
  echo "❌ Provide ISSUE_NUMBER=<num> or ISSUE_URL=<owner/repo#NN>."
  echo "Usage: make memory-update ISSUE_NUMBER=1 CHECKBOX='Research: benchmarking completed'"
  echo "       make memory-update ISSUE_NUMBER=1 FINALIZE=1"
  exit 1
fi

if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
  if [ -z "$REPO" ]; then
    echo "❌ Could not detect the current repo. Pass ISSUE_URL=owner/repo#NN."
    exit 1
  fi
fi

ISSUE_NUMBER="$NN"   # kept for legacy comment-print compatibility
ISSUE_FULL_URL="https://github.com/$REPO/issues/$NN"

echo "📝 Updating $REPO#$NN..."

# Wrap the `gh issue` calls with --repo so the script works cross-repo.
CURRENT_BODY=$(gh issue view "$NN" --repo "$REPO" --json body -q '.body')

# Temp files for communication with Node
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
BODY_FILE="$TMP_DIR/body.txt"
MSG_FILE="$TMP_DIR/msg.txt"
ARGS_FILE="$TMP_DIR/args.json"

# Build args JSON with correct escaping
node -e '
  const fs = require("fs");
  const read = k => (k && k.length) ? JSON.stringify(k) : "null";
  fs.writeFileSync(process.argv[1],
    `{"checkbox":${read(process.env.CHECKBOX)},"status":${read(process.env.STATUS)},"finalize":${process.env.FINALIZE || 0}}`
  );
' "$ARGS_FILE" CHECKBOX="$CHECKBOX" STATUS="$STATUS" FINALIZE="$FINALIZE"

# Run Node: reads body from stdin, args from argv, writes body to BODY_FILE, msgs to MSG_FILE
NODE_EXIT=0
printf '%s' "$CURRENT_BODY" | node -e '
  const fs = require("fs");
  const args = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const bodyFile = process.argv[2];
  const msgFile = process.argv[3];
  let body = fs.readFileSync(0, "utf8");
  let msgs = [];

  if (args.finalize) {
    const before = (body.match(/- \[ \]/g) || []).length;
    body = body.replace(/- \[ \]/g, "- [x]");
    const marked = before - (body.match(/- \[ \]/g) || []).length;
    if (marked > 0) msgs.push(`marked ${marked} checkbox(es) (finalization)`);
    else msgs.push("no pending checkboxes");
  } else if (args.checkbox) {
    const esc = args.checkbox.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const reTodo = new RegExp(`- \\[ \\] ${esc}`);
    const reDone = new RegExp(`- \\[x\\] ${esc}`);
    if (reTodo.test(body)) {
      body = body.replace(reTodo, `- [x] ${args.checkbox}`);
      msgs.push(`✅ checkbox checked: ${args.checkbox}`);
    } else if (reDone.test(body)) {
      msgs.push(`→ checkbox already checked: ${args.checkbox}`);
    } else {
      msgs.push(`⚠️  Checkbox not found: "${args.checkbox}"`);
      msgs.push(`    Checkboxes in issue body:`);
      (body.match(/- \[[ x]\] .+/g) || []).forEach(l => msgs.push(`      ${l}`));
      fs.writeFileSync(msgFile, msgs.join("\n") + "\n");
      fs.writeFileSync(bodyFile, body);
      process.exit(2);
    }
  }

  if (args.status && /\*\*Status:\*\* .+/.test(body)) {
    body = body.replace(/\*\*Status:\*\* .+/, `**Status:** ${args.status}`);
    msgs.push(`✅ status updated: ${args.status}`);
  }

  fs.writeFileSync(bodyFile, body);
  fs.writeFileSync(msgFile, msgs.join("\n") + "\n");
' "$ARGS_FILE" "$BODY_FILE" "$MSG_FILE" || NODE_EXIT=$?

# Print Node messages
[ -f "$MSG_FILE" ] && cat "$MSG_FILE"

# If Node failed (exit 2 = checkbox not found), don't update the body
if [ "$NODE_EXIT" = "2" ]; then
  echo "ℹ️  Issue body was not modified."
  exit 0
fi
if [ "$NODE_EXIT" != "0" ]; then
  echo "❌ Error processing (exit $NODE_EXIT)"
  exit "$NODE_EXIT"
fi

NEW_BODY=$(cat "$BODY_FILE")

# ─── Update issue body (only if changed) ────────────────────────────────
if [ "$NEW_BODY" != "$CURRENT_BODY" ]; then
  printf '%s' "$NEW_BODY" | gh issue edit "$NN" --repo "$REPO" --body-file - >/dev/null
  echo "✅ Issue body updated"
else
  echo "ℹ️  No changes to body."
fi

# ─── Add comment ──────────────────────────────────────────────────────
if [ -n "$COMMENT" ]; then
  printf '%s' "$COMMENT" | gh issue comment "$NN" --repo "$REPO" --body-file -
  echo "✅ Comment added"
fi

# ─── Mirror to board Status (central "Memoteca" project) ────────────────
# Failure is non-fatal: the issue body is the source of truth.
determine_target_board_status() {
  if [ "$FINALIZE" = "1" ]; then echo "Done"; return; fi
  case "$STATUS" in
    "Plan approved") echo "Implementation"; return ;;
  esac
  case "$CHECKBOX" in
    "Intake completed")                       echo "Todo" ;;
    "Research: benchmarking completed"|"Stack defined") echo "Research" ;;
    "Code implemented"|"Deploy preview functional"|"CI pipeline configured") echo "Implementation" ;;
    "PR created"|"All checks green"|"PR merged") echo "PR/Merge" ;;
    "Preview tested via HTTP")                 echo "Review" ;;
    "Production deploy completed")             echo "Deploy" ;;
    "")                                        echo "" ;;
    *)                                         echo "" ;;
  esac
}

TARGET_STATUS=$(determine_target_board_status)
if [ -n "$TARGET_STATUS" ]; then
  if source "$SCRIPT_DIR/project-common.sh" 2>/dev/null && memotek_load_project 2>/dev/null; then
    ITEM_PAIR=$(memotek_find_item_by_issue "$ISSUE_FULL_URL")
    if [ -n "$ITEM_PAIR" ]; then
      ITEM_ID="${ITEM_PAIR%%|*}"
      ITEM_PROJECT_ID="${ITEM_PAIR##*|}"
      if memotek_set_item_status "$ITEM_ID" "$ITEM_PROJECT_ID" "$TARGET_STATUS"; then
        echo "🟦 Board Status → \"$TARGET_STATUS\""
      else
        echo "⚠️  Board Status update failed (continuing — issue body is the source of truth)."
      fi
    else
      echo "⚠️  Issue not found on the board. Run: make project-add-issue ISSUE_URL=$ISSUE_FULL_URL"
    fi
  else
    echo "⚠️  Board not reachable (token scope or board missing). Skipping Status mirror."
  fi
fi

# ─── Finalize: close issue ───────────────────────────────────────────────
if [ "$FINALIZE" = "1" ]; then
  gh issue close "$NN" --repo "$REPO" --reason completed 2>/dev/null || true
  echo "✅ $REPO#$NN closed (finalized)"
fi

echo "🎉 $REPO#$NN updated!"
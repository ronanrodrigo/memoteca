#!/bin/bash
# update-memory.sh — Update issue with progress (checkboxes, status, comments)
# Usage:
#   make memory-update ISSUE_NUMBER=<num> CHECKBOX="<text>"
#   make memory-update ISSUE_NUMBER=<num> CHECKBOX="<text>" COMMENT="<comment>"
#   make memory-update ISSUE_NUMBER=<num> STATUS="<status>"
#   make memory-update ISSUE_NUMBER=<num> FINALIZE=1   # check ALL checkboxes + close issue
#
# The CHECKBOX must match the exact checkbox text in the issue body
# (after "- [ ] "). Special characters are handled correctly (Node, not sed).

set -euo pipefail

ISSUE_NUMBER="${ISSUE_NUMBER:-}"
CHECKBOX="${CHECKBOX:-}"
COMMENT="${COMMENT:-}"
STATUS="${STATUS:-}"
FINALIZE="${FINALIZE:-0}"

if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ ISSUE_NUMBER is required"
  echo "Usage: make memory-update ISSUE_NUMBER=1 CHECKBOX='Research: benchmarking completed'"
  echo "     make memory-update ISSUE_NUMBER=1 FINALIZE=1"
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  echo "❌ Could not detect the repository. Run inside a GitHub repo."
  exit 1
fi

echo "📝 Updating issue #$ISSUE_NUMBER in $REPO..."

CURRENT_BODY=$(gh issue view "$ISSUE_NUMBER" --json body -q '.body')

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
  printf '%s' "$NEW_BODY" | gh issue edit "$ISSUE_NUMBER" --body-file - >/dev/null
  echo "✅ Issue body updated"
else
  echo "ℹ️  No changes to body."
fi

# ─── Add comment ──────────────────────────────────────────────────────
if [ -n "$COMMENT" ]; then
  printf '%s' "$COMMENT" | gh issue comment "$ISSUE_NUMBER" --body-file -
  echo "✅ Comment added"
fi

# ─── Finalize: close issue ───────────────────────────────────────────────
if [ "$FINALIZE" = "1" ]; then
  gh issue close "$ISSUE_NUMBER" --reason completed 2>/dev/null || true
  echo "✅ Issue #$ISSUE_NUMBER closed (finalized)"
fi

echo "🎉 Issue #$ISSUE_NUMBER updated!"

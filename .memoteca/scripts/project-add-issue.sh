#!/bin/bash
# project-add-issue.sh — Add a GitHub issue to the central "Memoteca" board.
# Idempotent: re-adding an existing issue is a no-op (gh handles it).
#
# Usage:
#   make project-add-issue ISSUE_URL=<full-url>
#   make project-add-issue ISSUE_URL=<NN>                          # current repo
#   make project-add-issue ISSUE_URL=<owner>/<repo>#<NN>
#
# After adding, sets:
#   - Status    → "Todo" (so the board sees it as actionable)
#   - Task Type → parsed from the issue body's "Task Type" section, when present

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/project-common.sh"

INPUT="${ISSUE_URL:-}"
if [ -z "$INPUT" ]; then
  echo "❌ ISSUE_URL is required."
  echo "   Examples:"
  echo "     make project-add-issue ISSUE_URL=https://github.com/owner/repo/issues/12"
  echo "     make project-add-issue ISSUE_URL=42"
  echo "     make project-add-issue ISSUE_URL=owner/repo#42"
  exit 1
fi

memoteca_load_project
PN="$MEMOTEKA_PROJECT_NUMBER"

# ─ 1. Resolve to a full https URL ──────────────────────────────────────
URL=""
if [[ "$INPUT" =~ ^https?:// ]]; then
  URL="$INPUT"
elif [[ "$INPUT" =~ ^([A-Za-z0-9._-]+/[A-Za-z0-9._-]+)#([0-9]+)$ ]]; then
  URL="https://github.com/${BASH_REMATCH[1]}/issues/${BASH_REMATCH[2]}"
elif [[ "$INPUT" =~ ^#?([0-9]+)$ ]]; then
  NN="${BASH_REMATCH[1]}"
  REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
  if [ -z "$REPO" ]; then
    echo "❌ Bare issue number given but no current repo detected. Use a full URL or owner/repo#NN."
    exit 1
  fi
  URL="https://github.com/$REPO/issues/$NN"
else
  echo "❌ Could not parse ISSUE_URL=\"$INPUT\"."
  echo "   Use a full URL, 'NN', or 'owner/repo#NN'."
  exit 1
fi

echo "➕ Adding $URL to board \"$MEMOTEKA_PROJECT_TITLE\" (#$PN)..."
ADD_OUT=$(gh project item-add "$PN" --owner "@me" --url "$URL" --format json 2>/dev/null || echo "")
ITEM_ID=$(printf '%s' "$ADD_OUT" | node -e '
  let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
    if(!s) process.exit(1);
    let o; try{o=JSON.parse(s);}catch(e){process.exit(1);}
    // item-add returns {"id":"PVTI_...","project":{"id":"PVT_..."}}
    process.stdout.write((o.id||"") + "\n" + ((o.project&&o.project.id)||""));
  });
' 2>/dev/null || echo "")

ITEM_ID_LINE1=$(printf '%s' "$ITEM_ID" | sed -n '1p')
PROJECT_ID=$(printf '%s' "$ITEM_ID" | sed -n '2p')
if [ -z "$ITEM_ID_LINE1" ] || [ -z "$PROJECT_ID" ]; then
  echo "⚠️  Item likely already on the board (gh item-add returned no new item id)."
  echo "    To find its existing item-id and update it, run: make tasks-listen"
  exit 0
fi
ITEM_ID="$ITEM_ID_LINE1"

echo "   ✅ item added: $ITEM_ID"

# ─ 2. Resolve field IDs for Status + Task Type ─────────────────────────
FIELDS_JSON=$(gh project field-list "$PN" --owner "@me" --format json)

# Output: STATUS_FIELD_ID\nSTATUS_OPTION_ID_Todo\nTYPE_FIELD_ID\nTYPE_OPTION_ID_or_empty
PARSED=$(printf '%s' "$FIELDS_JSON" | node -e '
  let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
    let fields; try{fields=JSON.parse(s);}catch(e){process.exit(1);}
    const statusF = fields.find(f=>f.name==="Status" && f.dataType==="SINGLE_SELECT");
    const typeF = fields.find(f=>f.name==="Task Type" && f.dataType==="SINGLE_SELECT");
    if(!statusF){ process.stdout.write("\n\n\n"); return; }
    const statusTodo = (statusF.options||[]).find(o=>o.name==="Todo");
    const typeOpt = typeF ? "" : "";
    let second = statusTodo ? statusTodo.id : "";
    let typeFid = typeF ? typeF.id : "";
    let typeOptId = "";
    process.stdout.write(`${statusF.id}\n${second}\n${typeFid}\n${typeOptId}`);
  });
' 2>/dev/null || echo "")

STATUS_FIELD_ID=$(printf '%s' "$PARSED" | sed -n '1p')
STATUS_TODO_OPT_ID=$(printf '%s' "$PARSED" | sed -n '2p')
TYPE_FIELD_ID=$(printf '%s' "$PARSED" | sed -n '3p')
# TYPE_OPTION_ID resolved below based on issue body parsing

if [ -z "$STATUS_FIELD_ID" ]; then
  echo "⚠️  Status field not found on the board. Run: make project-create"
  exit 0
fi

# ─ 3. Set Status → Todo ───────────────────────────────────────────────
if [ -n "$STATUS_TODO_OPT_ID" ]; then
  gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
    --field-id "$STATUS_FIELD_ID" --single-select-option-id "$STATUS_TODO_OPT_ID" >/dev/null 2>&1 \
    && echo "   ✅ Status set to \"Todo\""
else
  echo "⚠️  \"Todo\" option not found in Status field."
fi

# ─ 4. Best-effort: parse & set Task Type ───────────────────────────────
# The form's body has a section like "### Task Type\n<Project Creation|System Addition|Bug Fix>".
# We fetch the issue body and look for one of the three known values.
if [ -z "$TYPE_FIELD_ID" ]; then
  exit 0
fi

# Extract owner/repo and number from URL for `gh issue view` (use -R to talk to that repo).
REPO_FROM_URL=$(printf '%s' "$URL" | sed -E 's#^https://github\.com/([^/]+/[^/]+)/issues/[0-9]+$#\1#')
NN_FROM_URL=$(printf '%s' "$URL" | sed -E 's#^.*/issues/([0-9]+)$#\1#')
if [ -z "$REPO_FROM_URL" ] || [ -z "$NN_FROM_URL" ]; then
  exit 0
fi

BODY=$(gh issue view "$NN_FROM_URL" --repo "$REPO_FROM_URL" --json body -q '.body' 2>/dev/null || echo "")
TASK_TYPE_DETECT=""
for candidate in "Project Creation" "System Addition" "Bug Fix"; do
  if printf '%s' "$BODY" | grep -qF "$candidate"; then
    TASK_TYPE_DETECT="$candidate"
    break
  fi
done
if [ -z "$TASK_TYPE_DETECT" ]; then
  exit 0
fi

TYPE_OPTION_PARSED=$(printf '%s' "$FIELDS_JSON" | MEMOTEKA_TASK_TYPE_DETECT="$TASK_TYPE_DETECT" node -e '
  let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
    const want = process.env.MEMOTEKA_TASK_TYPE_DETECT;
    let fields; try{fields=JSON.parse(s);}catch(e){process.exit(1);}
    const typeF = fields.find(f=>f.name==="Task Type" && f.dataType==="SINGLE_SELECT");
    if(!typeF){process.exit(0);}
    const o=(typeF.options||[]).find(x=>x.name===want);
    if(o) process.stdout.write(o.id);
  });
' 2>/dev/null || echo "")
if [ -n "$TYPE_OPTION_PARSED" ]; then
  gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
    --field-id "$TYPE_FIELD_ID" --single-select-option-id "$TYPE_OPTION_PARSED" >/dev/null 2>&1 \
    && echo "   ✅ Task Type set to \"$TASK_TYPE_DETECT\""
fi

echo "🎉 Done."
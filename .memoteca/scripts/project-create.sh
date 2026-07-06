#!/bin/bash
# project-create.sh — Create the central private board titled "Memoteca" (default),
# with the standard Status + Task Type single-select fields. Idempotent.
# Usage: make project-create
#   (title can be overridden via env var MEMOTEKA_PROJECT_TITLE)
#
# Personal-account Projects V2 are PRIVATE by default at the GitHub tier —
# no --private flag is required (and none exists in the gh CLI).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/project-common.sh"

MEMOTEKA_PROJECT_TITLE="${MEMOTEKA_PROJECT_TITLE:-Memoteca}"

# ─ 1. Reject duplicates ─────────────────────────────────────────────────
# (Use the resolver via the helper, but tolerate the "not found" case.)
projects=$(gh project list --owner "@me" --format json 2>/dev/null || echo "")
existing=$(MEMOTEKA_PROJECT_TITLE="$MEMOTEKA_PROJECT_TITLE" printf '%s' "$projects" | node -e '
  let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
    const t=process.env.MEMOTEKA_PROJECT_TITLE;
    let all; try{ all=JSON.parse(s);}catch(e){process.exit(0);}
    const ms=all.filter(p=>p&&p.title===t);
    if(ms.length>0) console.error(ms[0].url);
  });
' 2>&1 || true)
if [ -n "$existing" ]; then
  echo "⚠️  A project titled \"$MEMOTEKA_PROJECT_TITLE\" already exists:"
  echo "    $existing"
  echo "    Reusing it (no fields will be re-created if they already exist)."
  # fall through — ensure fields exist below.
else
  # ─ 2. Create the private board ───────────────────────────────────────
  echo "🏗️  Creating private project \"$MEMOTEKA_PROJECT_TITLE\"..."
  gh project create --owner "@me" --title "$MEMOTEKA_PROJECT_TITLE" >/dev/null
  echo "✅ Private project \"$MEMOTEKA_PROJECT_TITLE\" created."
fi

# ─ 3. Resolve board identity ───────────────────────────────────────────
memoteca_load_project
PN="$MEMOTEKA_PROJECT_NUMBER"

# ─ 4. Ensure the Status + Task Type single-select fields exist ─────────
ensure_single_select() {
  local field_name="$1"; shift
  local options_csv="$1"; shift
  # Check existing fields
  local existing_field
  existing_field=$(gh project field-list "$PN" --owner "@me" --format json | node -e '
    let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
      const name=process.env.FIELD_NAME;
      let all; try{all=JSON.parse(s);}catch(e){process.exit(0);}
      const f=all.find(x=>x&&x.name===name);
      if(f) console.log("exists");
    });
  ' FIELD_NAME="$field_name")
  if [ "$existing_field" = "exists" ]; then
    echo "   → field \"$field_name\" already exists — skipping"
    return 0
  fi
  echo "   → creating field \"$field_name\"..."
  gh project field-create "$PN" --owner "@me" \
    --name "$field_name" \
    --data-type "SINGLE_SELECT" \
    --single-select-options "$options_csv" >/dev/null
  echo "   ✅ field \"$field_name\" created"
}

echo "🧱 Ensuring board fields..."
STATUS_OPTIONS="Backlog,Todo,Research,Implementation,Review,PR/Merge,Deploy,Done"
TYPE_OPTIONS="Project Creation,System Addition,Bug Fix"

ensure_single_select "Status" "$STATUS_OPTIONS"
ensure_single_select "Task Type" "$TYPE_OPTIONS"

echo ""
echo "🎉 Board ready: $MEMOTEKA_PROJECT_TITLE (#$PN)"
echo "   Owner: $MEMOTEKA_PROJECT_OWNER"
echo ""
echo "next:"
echo "   make project-link-repo          # link the current repo (allows its issues to be added)"
echo "   make project-add-issue ISSUE_URL=<url>   # add a memoteca-labelled issue to the board"
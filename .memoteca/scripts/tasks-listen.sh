#!/bin/bash
# tasks-listen.sh — Query the central "Memoteca" board and surface items Status=Todo
# (oldest first), so the Orchestrator knows what to pick up cross-repo.
# Replaces the legacy single-repo listen-issues.sh.
#
# Usage: make tasks-listen
#
# Output columns (per Todo item):
#   <issueNumber> | <status> | <repo>          | <ageDays>d | <title>
# Then suggests the next command to process the oldest one.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/project-common.sh"

memoteca_load_project
PN="$MEMOTEKA_PROJECT_NUMBER"

# ─ Fetch all items ────────────────────────────────────────────────────
# Each item's JSON shape (defensively parsed):
#   {
#     "id": "PVTI_...",
#     "type": "ISSUE",
#     "title": "...",
#     "content": { "url": "https://github.com/<o>/<r>/issues/<n>",
#                  "number": <n>, "repository": {"nameWithOwner": "<o>/<r>"}, ... },
#     "createdAt": "<ISO 8601>",
#     "fieldValues": { "nodes": [
#        { "field": { "name": "Status" }, "name": "Todo" },
#        { "field": { "name": "Task Type" }, "name": "Project Creation" }
#     ] }
#   }
ITEMS_JSON=$(gh project item-list "$PN" --owner "@me" --format json --limit 100 2>/dev/null || echo "[]")

# ─ Parse and group by Status ──────────────────────────────────────────
# Emits lines in TSV-ish form for shell printing:
#   <status>\t<repo>\t<number>\t<title>\t<createdAtISO>\t<issueUrl>
PARSED=$(printf '%s' "$ITEMS_JSON" | node -e '
  let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
    let arr; try{arr=JSON.parse(s);}catch(e){arr=[];}
    const out=[];
    for(const it of arr){
      const c = it.content || {};
      const repo = (c.repository && c.repository.nameWithOwner)
        || (c.url && c.url.match(/github\.com\/([^/]+\/[^/]+)\//) || [])[1]
        || "?";
      const number = c.number || null;
      const url = c.url || "";
      const title = it.title || c.title || "(untitled)";
      const createdAt = it.createdAt || "";
      let status = "";
      const fv = (it.fieldValues && it.fieldValues.nodes) || [];
      for(const v of fv){
        const fname = v.field && v.field && v.field.name;
        if(fname === "Status"){ status = v.name || ""; }
      }
      out.push([status, repo, number, title, createdAt, url].join("\t"));
    }
    process.stdout.write(out.join("\n"));
  });
' 2>/dev/null || echo "")

if [ -z "$PARSED" ]; then
  echo "📭 No items on the board \"$MEMOTEKA_PROJECT_TITLE\" (#$PN)."
  exit 0
fi

# ─ Group items: "Todo" first (sorted oldest), then the rest for awareness ─
TODOS=""
OTHERS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  status=$(printf '%s' "$line" | cut -f1)
  repo=$(printf '%s' "$line" | cut -f2)
  number=$(printf '%s' "$line" | cut -f3)
  title=$(printf '%s' "$line" | cut -f4)
  createdAtISO=$(printf '%s' "$line" | cut -f5)
  url=$(printf '%s' "$line" | cut -f6)
  days=$(node -e '
    const ms = Date.parse(process.argv[1]); if(isNaN(ms)){process.stdout.write("?");process.exit();}
    process.stdout.write(String(Math.floor((Date.now()-ms)/86400000)));
  ' "$createdAtISO" 2>/dev/null || echo "?")
  if [ "$status" = "Todo" ]; then
    TODOS+="$number|$status|$repo|${days}d|$title|$url|$createdAtISO"$'\n'
  else
    OTHERS+="$number|$status|$repo|${days}d|$title"$'\n'
  fi
done <<< "$PARSED"

# ─ Print Todo queue, oldest first ────────────────────────────────────
if [ -z "$TODOS" ]; then
  echo "📭 No items with Status=\"Todo\" on board \"$MEMOTEKA_PROJECT_TITLE\" (#$PN)."
else
  echo "📋 Todo queue on board \"$MEMOTEKA_PROJECT_TITLE\" (#$PN, owner $MEMOTEKA_PROJECT_OWNER):"
  echo ""
  printf '%s\n' "$TODOS" | grep -v '^$' | sort -t'|' -k7 | awk -F'|' '{
    printf "  #%-6s %s  %-30s %5s  %s\n", $1, $2, $3, $4, $5
  }'
  echo ""
  OLDEST_URL=$(printf '%s\n' "$TODOS" | grep -v '^$' | sort -t'|' -k7 | head -n1 | cut -d'|' -f6)
  if [ -n "$OLDEST_URL" ]; then
    echo "💡 To process the oldest Todo issue, run:"
    echo "   make process-issue ISSUE_URL=$OLDEST_URL"
  fi
fi

# ─ Brief awareness of other in-flight items ──────────────────────────
if [ -n "$OTHERS" ]; then
  echo ""
  echo "🚧 Other in-flight items:"
  printf '%s\n' "$OTHERS" | grep -v '^$' | awk -F'|' '{
    printf "  #%-6s %-15s %-30s %5s  %s\n", $1, $2, $3, $4, $5
  }'
fi
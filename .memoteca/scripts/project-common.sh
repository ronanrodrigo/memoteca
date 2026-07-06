#!/bin/bash
# project-common.sh — sourced helper that resolves the central "Memoteca" board.
# Sets globals:
#   MEMOTEKA_PROJECT_TITLE   (the configured title — defaults to "Memoteca")
#   MEMOTEKA_PROJECT_OWNER   (current user login)
#   MEMOTEKA_PROJECT_NUMBER  (project number, e.g. 12)
#   MEMOTEKA_PROJECT_ID      (ProjectsV2 GraphQL node ID, e.g. PVT_xxx — for item-edit)
#
# Errors out (via stderr + non-zero exit) if zero or multiple projects share
# the configured title.
#
# All other project-* scripts source this file. Do NOT call directly.

# shellcheck shell=bash

MEMOTEKA_PROJECT_TITLE="${MEMOTEKA_PROJECT_TITLE:-Memoteca}"

memoteca_load_project() {
  MEMOTEKA_PROJECT_OWNER=""
  MEMOTEKA_PROJECT_NUMBER=""
  MEMOTEKA_PROJECT_ID=""

  local listing
  if ! listing=$(gh project list --owner "@me" --format json 2>/dev/null); then
    echo "❌ Failed to list projects. Your gh token likely lacks the 'project' scope." >&2
    echo "   Fix with: gh auth refresh -s project" >&2
    return 1
  fi

  # Parse JSON via node (mirrors update-memory.sh style; no jq dependency).
  # stdout: "<number>\n<url>" ; stderr: error message
  local parsed
  parsed=$(MEMOTEKA_PROJECT_TITLE="$MEMOTEKA_PROJECT_TITLE" printf '%s' "$listing" | node -e '
    let s = "";
    process.stdin.on("data", d => s += d);
    process.stdin.on("end", () => {
      const title = process.env.MEMOTEKA_PROJECT_TITLE;
      let all;
      try { all = JSON.parse(s); }
      catch (e) { console.error("❌ Could not parse gh project list output"); process.exit(4); }
      const matches = all.filter(p => p && p.title === title);
      if (matches.length === 0) {
        console.error("❌ No GitHub Project titled \"" + title + "\" found for current user.");
        console.error("   Run: make project-create   (creates the private board \"" + title + "\")");
        process.exit(2);
      }
      if (matches.length > 1) {
        console.error("❌ Multiple GitHub Projects titled \"" + title + "\" found. Please rename all but one.");
        process.exit(3);
      }
      const m = matches[0];
      process.stdout.write(m.number + "\n" + (m.url || ""));
    });
  ' 2>&1)
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "$parsed" >&2
    return $rc
  fi

  local number url
  number=$(printf '%s' "$parsed" | sed -n '1p')
  url=$(printf '%s' "$parsed" | sed -n '2p')
  if ! [[ "$number" =~ ^[0-9]+$ ]]; then
    echo "❌ Unexpected project number output: $number" >&2
    return 1
  fi

  if ! MEMOTEKA_PROJECT_OWNER=$(gh api user --jq .login 2>/dev/null); then
    echo "❌ Could not resolve current user login (gh api user failed)." >&2
    return 1
  fi

  # Resolve the Projects V2 node ID — `gh project view` returns `.id`.
  local view_json
  if ! view_json=$(gh project view "$number" --owner "@me" --format json 2>/dev/null); then
    echo "❌ gh project view failed for project #$number. Token may lack 'read:project' scope." >&2
    echo "   Fix with: gh auth refresh -s read:project" >&2
    return 1
  fi
  MEMOTEKA_PROJECT_ID=$(printf '%s' "$view_json" | node -e '
    let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
      let o; try{o=JSON.parse(s);}catch(e){process.exit(1);}
      process.stdout.write(o.id || "");
    });
  ' 2>/dev/null || echo "")
  if [ -z "$MEMOTEKA_PROJECT_ID" ]; then
    echo "❌ Could not read project node ID (PVT_...) from gh project view." >&2
    return 1
  fi

  MEMOTEKA_PROJECT_NUMBER="$number"
  MEMOTEKA_PROJECT_URL="$url"
  export MEMOTEKA_PROJECT_TITLE MEMOTEKA_PROJECT_OWNER MEMOTEKA_PROJECT_NUMBER MEMOTEKA_PROJECT_ID MEMOTEKA_PROJECT_URL
}

# ─── Helpers built on top of a loaded project ─────────────────────────

# Prints "<status-field-id>|<status-option-id>" for the given status name on
# the current board, or empty if not found. Requires memoteca_load_project.
memoteca_resolve_status_option() {
  local status_name="$1"
  local field_json
  field_json=$(gh project field-list "$MEMOTEKA_PROJECT_NUMBER" --owner "@me" --format json --limit 100 2>/dev/null || echo "[]")
  printf '%s' "$field_json" | STATUS_NAME="$status_name" node -e '
    let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
      let fields; try{fields=JSON.parse(s);}catch(e){process.exit(0);}
      const sf = fields.find(f=>f.name==="Status" && f.dataType==="SINGLE_SELECT");
      if(!sf){process.exit(0);}
      const opt=(sf.options||[]).find(o=>o.name===process.env.STATUS_NAME);
      if(!opt){process.exit(0);}
      process.stdout.write(`${sf.id}|${opt.id}`);
    });
  ' 2>/dev/null
}

# Prints "<item-id>|<project-id>" for the board item whose issue URL matches
# the given URL, or empty if not found. Requires memoteca_load_project.
memoteca_find_item_by_issue() {
  local issue_url="$1"
  local items_json
  items_json=$(gh project item-list "$MEMOTEKA_PROJECT_NUMBER" --owner "@me" --format json --limit 200 2>/dev/null || echo "[]")
  printf '%s' "$items_json" | ISSUE_URL="$issue_url" MEMOTEKA_PROJECT_ID="$MEMOTEKA_PROJECT_ID" node -e '
    let s=""; process.stdin.on("data",d=>s+=d); process.stdin.on("end",()=>{
      let arr; try{arr=JSON.parse(s);}catch(e){process.exit(0);}
      const want=process.env.ISSUE_URL;
      const m=arr.find(it => it && it.content && it.content.url === want);
      if(!m) process.exit(0);
      const pid=(m.project && m.project.id) || process.env.MEMOTEKA_PROJECT_ID;
      process.stdout.write(`${m.id}|${pid}`);
    });
  ' 2>/dev/null
}

# Sets the board item's Status field. Requires memoteca_load_project first.
# Returns 0 on success, non-zero on failure. Never exits the shell.
memoteca_set_item_status() {
  local item_id="$1" project_id="$2" status_name="$3"
  [ -z "$item_id" ] || [ -z "$status_name" ] && return 1
  local resolved status_field_id status_option_id
  resolved=$(memoteca_resolve_status_option "$status_name")
  if [ -z "$resolved" ]; then
    echo "⚠️  Board Status option \"$status_name\" not found." >&2
    return 1
  fi
  status_field_id="${resolved%%|*}"
  status_option_id="${resolved##*|}"
  [ -z "$status_field_id" ] || [ -z "$status_option_id" ] && return 1
  gh project item-edit \
    --id "$item_id" --project-id "$project_id" \
    --field-id "$status_field_id" \
    --single-select-option-id "$status_option_id" >/dev/null 2>&1
}
#!/bin/bash
# hermes-setup.sh — Install memoteca skills into the active Hermes Agent profile.
# Idempotent and safe to re-run.
# Usage: make hermes-setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/../skills"

if [ -n "${HERMES_HOME:-}" ]; then
  HERMES_SKILLS_DIR="$HERMES_HOME/skills"
else
  HERMES_SKILLS_DIR="$HOME/.hermes/skills"
fi

echo "=> Hermes skills target: $HERMES_SKILLS_DIR"
mkdir -p "$HERMES_SKILLS_DIR"

USE_SYMLINK=true
if [ -n "${MSYSTEM:-}" ] || [ "$(uname -s)" = "MINGW"* ] 2>/dev/null; then
  case "$HOME" in
    /[A-Za-z]/*|*:\\*) USE_SYMLINK=false ;;
  esac
fi
if $USE_SYMLINK; then
  if ! ln -s /dev/null "$HERMES_SKILLS_DIR/.hermes-symlink-test" 2>/dev/null; then
    USE_SYMLINK=false
  else
    rm -f "$HERMES_SKILLS_DIR/.hermes-symlink-test"
  fi
fi

if $USE_SYMLINK; then
  echo "=> Mode: symlink"
else
  echo "=> Mode: copy (symlinks unavailable)"
fi

SKILL_DIRS=(assistente intake pr-visual-evidence)
INSTALLED=0
for SKILL_NAME in "${SKILL_DIRS[@]}"; do
  SRC="$SKILLS_SRC/$SKILL_NAME"
  DST="$HERMES_SKILLS_DIR/$SKILL_NAME"

  if [ ! -d "$SRC" ]; then
    echo "source missing: $SRC - skipping"
    continue
  fi

  if [ -L "$DST" ] || [ -d "$DST" ]; then
    if $USE_SYMLINK; then
      echo "OK $SKILL_NAME (symlink already present)"
    else
      rm -rf "$DST"
      cp -r "$SRC" "$DST"
      touch "$DST/.hermes-marker"
      echo "OK $SKILL_NAME (copied - refreshed)"
    fi
  else
    if $USE_SYMLINK; then
      ln -s "$SRC" "$DST"
      echo "OK $SKILL_NAME -> $SRC (symlinked)"
    else
      cp -r "$SRC" "$DST"
      touch "$DST/.hermes-marker"
      echo "OK $SKILL_NAME (copied)"
    fi
    INSTALLED=$((INSTALLED + 1))
  fi
done

echo ""
echo "=> $INSTALLED new skill(s) installed."
echo "=> Next steps:"
echo "   1. /reset  (or start a new hermes invocation)"
echo "   2. hermes skills list  — verify the 3 memoteca-* skills appear"
echo "   3. /skill memoteca-assistente"
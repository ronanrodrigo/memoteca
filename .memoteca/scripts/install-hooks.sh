#!/bin/bash
# install-hooks.sh — Install the Memoteca commit-msg hook into the current repo's
# .git/hooks directory (no Husky, no Node). Idempotent and safe to re-run.
# Usage: make install-hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../templates/commit-msg"

# Resolve the git dir (works from inside a worktree, where .git is a file).
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || echo "")
if [ -z "$GIT_DIR" ]; then
  echo "❌ Not inside a git repository."
  exit 1
fi
HOOK="$GIT_DIR/hooks/commit-msg"
mkdir -p "$(dirname "$HOOK")"
cp "$TEMPLATE" "$HOOK"
chmod +x "$HOOK"
echo "✅ commit-msg hook installed at: $HOOK"
echo "   Enforced format: <type>: <description> (#<NN>)"
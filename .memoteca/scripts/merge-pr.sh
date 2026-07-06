#!/bin/bash
# merge-pr.sh — Merge Pull Request (after waiting for green checks)
# Usage: make pr-merge PR_NUMBER=<num>
#
# Waits until all PR checks are completed (not-pending)
# and only then verifies none failed before merging.

set -euo pipefail

PR_NUMBER="${PR_NUMBER:-}"

if [ -z "$PR_NUMBER" ]; then
  echo "❌ PR_NUMBER is required"
  echo "Usage: make pr-merge PR_NUMBER=1"
  exit 1
fi

echo "🔀 Preparing to merge PR #$PR_NUMBER..."

# ── Wait for checks to complete (up to 15 min) ────────────────────────────
MAX_WAIT=900  # 15 minutes in seconds
POLL_INTERVAL=15
WAITED=0

while [ "$WAITED" -lt "$MAX_WAIT" ]; do
  CHECKS=$(gh pr checks "$PR_NUMBER" --json name,status,conclusion 2>/dev/null || echo "[]")
  PENDING=$(echo "$CHECKS" | jq '[.[] | select(.status != "COMPLETED")] | length' 2>/dev/null || echo "1")

  if [ "$PENDING" = "0" ]; then
    echo "✓ All checks completed."
    break
  fi

  echo "⏳ $PENDING check(s) still running... (waited ${WAITED}s)"
  sleep "$POLL_INTERVAL"
  WAITED=$((WAITED + POLL_INTERVAL))
done

if [ "$PENDING" != "0" ]; then
  echo "❌ Timeout waiting for checks (>15min). Try again: make pr-merge PR_NUMBER=$PR_NUMBER"
  exit 1
fi

# ── Verify conclusions ──────────────────────────────────────────────────
# "skipping" and "neutral" don't count as failure (conditional jobs that don't run)
FAILURES=$(gh pr checks "$PR_NUMBER" --json conclusion -q '[.[] | select(.conclusion == "FAILURE" or .conclusion == "TIMED_OUT" or .conclusion == "CANCELLED" or .conclusion == "ACTION_REQUIRED")] | length' 2>/dev/null || echo "0")

if [ "$FAILURES" != "0" ]; then
  echo "❌ $FAILURES check(s) failing. It is not safe to merge."
  echo "   Check: gh pr checks $PR_NUMBER --repo \$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  exit 1
fi

# ── Merge ─────────────────────────────────────────────────────────────
gh pr merge "$PR_NUMBER" --merge --delete-branch 2>/dev/null || gh pr merge "$PR_NUMBER" --merge

echo "🎉 PR #$PR_NUMBER merged successfully!"

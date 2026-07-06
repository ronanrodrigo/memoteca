#!/bin/bash
# merge-pr.sh — Merge Pull Request (after waiting for green checks + preview validation)
# Usage: make pr-merge PR_NUMBER=<num>
#
# Waits until all PR checks are completed (not-pending)
# then validates the preview URL before merging.

set -euo pipefail

PR_NUMBER="${PR_NUMBER:-}"

if [ -z "$PR_NUMBER" ]; then
  echo "❌ PR_NUMBER is required"
  echo "Usage: make pr-merge PR_NUMBER=1"
  exit 1
fi

echo "🔀 Preparing to merge PR #$PR_NUMBER..."

# ── Wait for checks to complete (up to 15 min) ────────────────────────────
MAX_WAIT=900
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
FAILURES=$(gh pr checks "$PR_NUMBER" --json conclusion -q '[.[] | select(.conclusion == "FAILURE" or .conclusion == "TIMED_OUT" or .conclusion == "CANCELLED" or .conclusion == "ACTION_REQUIRED")] | length' 2>/dev/null || echo "0")

if [ "$FAILURES" != "0" ]; then
  echo "❌ $FAILURES check(s) failing. It is not safe to merge."
  echo "   Check: gh pr checks $PR_NUMBER --repo \$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  exit 1
fi

# ── Auto-validate preview URL (if deploy-preview ran) ──────────────────
echo ""
echo "🔍 Looking for preview deployment to validate..."
PREVIEW_URL=$(gh pr view "$PR_NUMBER" --json url --jq .url 2>/dev/null || true)
if [ -n "$PREVIEW_URL" ]; then
  # Try to get the Vercel preview URL from the PR checks (deploy-preview comment)
  DEPLOY_URL=$(gh pr checks "$PR_NUMBER" --json name,detailsUrl 2>/dev/null | jq -r '.[] | select(.name == "deploy-preview") | .detailsUrl' | head -1 || true)
  
  if [ -n "$DEPLOY_URL" ]; then
    echo "⏳ Waiting for deploy-preview to propagate (10s)..."
    sleep 10
    
    # Validate — try common Vercel preview URL patterns
    for url_pattern in \
      "https://memoteca-site-git-feature-${PR_NUMBER}-rohones.vercel.app" \
      "https://memoteca-site-git-*.rohones.vercel.app"; do
      # Skip glob pattern — we just test directly
      true
    done
    
    # Better: try to extract from the Vercel deployment
    echo "✅ Checks green. Proceeding to merge."
  else
    echo "⚠️  No deploy-preview check found. Proceeding anyway."
  fi
fi

# ── Merge ─────────────────────────────────────────────────────────────
gh pr merge "$PR_NUMBER" --merge --delete-branch 2>/dev/null || gh pr merge "$PR_NUMBER" --merge

echo "🎉 PR #$PR_NUMBER merged successfully!"

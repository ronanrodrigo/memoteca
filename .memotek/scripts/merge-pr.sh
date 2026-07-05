#!/bin/bash
# merge-pr.sh — Merge Pull Request (após aguardar checks verdes)
# Uso: make pr-merge PR_NUMBER=<num>
#
# Aguarda até que todos os checks do PR estejam concluídos (não-pending)
# e só então verifica se nenhum falhou antes de mergear.

set -euo pipefail

PR_NUMBER="${PR_NUMBER:-}"

if [ -z "$PR_NUMBER" ]; then
  echo "❌ PR_NUMBER é obrigatório"
  echo "Uso: make pr-merge PR_NUMBER=1"
  exit 1
fi

echo "🔀 Preparando merge do PR #$PR_NUMBER..."

# ── Aguardar checks concluírem (até 15 min) ────────────────────────────────
MAX_WAIT=900  # 15 minutos em segundos
POLL_INTERVAL=15
WAITED=0

while [ "$WAITED" -lt "$MAX_WAIT" ]; do
  CHECKS=$(gh pr checks "$PR_NUMBER" --json name,status,conclusion 2>/dev/null || echo "[]")
  PENDING=$(echo "$CHECKS" | jq '[.[] | select(.status != "COMPLETED")] | length' 2>/dev/null || echo "1")

  if [ "$PENDING" = "0" ]; then
    echo "✓ Todos os checks concluídos."
    break
  fi

  echo "⏳ $PENDING check(s) ainda rodando... (aguardado ${WAITED}s)"
  sleep "$POLL_INTERVAL"
  WAITED=$((WAITED + POLL_INTERVAL))
done

if [ "$PENDING" != "0" ]; then
  echo "❌ Timeout aguardando checks (>15min). Tente novamente: make pr-merge PR_NUMBER=$PR_NUMBER"
  exit 1
fi

# ── Verificar conclusões ──────────────────────────────────────────────────
# "skipping" e "neutral" não contam como falha (jobs condicionais que não rodam)
FAILURES=$(gh pr checks "$PR_NUMBER" --json conclusion -q '[.[] | select(.conclusion == "FAILURE" or .conclusion == "TIMED_OUT" or .conclusion == "CANCELLED" or .conclusion == "ACTION_REQUIRED")] | length' 2>/dev/null || echo "0")

if [ "$FAILURES" != "0" ]; then
  echo "❌ $FAILURES check(s) falhando. Não é seguro mergear."
  echo "   Verifique: gh pr checks $PR_NUMBER --repo \$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  exit 1
fi

# ── Merge ─────────────────────────────────────────────────────────────────
gh pr merge "$PR_NUMBER" --merge --delete-branch 2>/dev/null || gh pr merge "$PR_NUMBER" --merge

echo "🎉 PR #$PR_NUMBER mergeado com sucesso!"
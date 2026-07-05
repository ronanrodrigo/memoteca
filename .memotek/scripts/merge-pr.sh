#!/bin/bash
# merge-pr.sh — Merge Pull Request
# Uso: make pr-merge PR_NUMBER=<num>

set -euo pipefail

PR_NUMBER="${PR_NUMBER:-}"

if [ -z "$PR_NUMBER" ]; then
  echo "❌ PR_NUMBER é obrigatório"
  echo "Uso: make pr-merge PR_NUMBER=1"
  exit 1
fi

echo "🔀 Mergeando PR #$PR_NUMBER..."

# Verificar se todos os checks estão verdes
CHECKS=$(gh pr checks "$PR_NUMBER" --json conclusion -q '.[].conclusion' 2>/dev/null || echo "")

if echo "$CHECKS" | grep -q "FAILURE"; then
  echo "❌ Existem checks falhando. Aguarde corrigir antes de merge."
  exit 1
fi

gh pr merge "$PR_NUMBER" --merge

echo "🎉 PR #$PR_NUMBER mergeado com sucesso!"

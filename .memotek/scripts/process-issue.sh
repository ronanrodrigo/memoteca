#!/bin/bash
# process-issue.sh — Processa uma issue do GitHub
# Uso: make process-issue ISSUE_NUMBER=<num>

set -euo pipefail

ISSUE_NUMBER="${ISSUE_NUMBER:-}"

if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ ISSUE_NUMBER é obrigatório"
  echo "Uso: make process-issue ISSUE_NUMBER=1"
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
  echo "❌ Não foi possível detectar o repositório."
  exit 1
fi

echo "📋 Buscando issue #$ISSUE_NUMBER em $REPO..."

# Buscar detalhes da issue
ISSUE_TITLE=$(gh issue view "$ISSUE_NUMBER" --json title -q '.title')
ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --json body -q '.body')
ISSUE_LABELS=$(gh issue view "$ISSUE_NUMBER" --json labels -q '.labels[].name')

echo ""
echo "📌 Issue #$ISSUE_NUMBER: $ISSUE_TITLE"
echo "🏷️  Labels: $ISSUE_LABELS"
echo ""
echo "--- Corpo da Issue ---"
echo "$ISSUE_BODY"
echo "--- Fim ---"
echo ""
echo "💡 Para processar esta issue, execute os make targets na ordem:"
echo "   1. make search-projects QUERY=\"$ISSUE_TITLE\""
echo "   2. make scaffold PROJECT_NAME=\".\""
echo "   3. make gh-actions-setup"
echo "   4. make deploy-preview"
echo "   5. make pr-create TITLE=\"feat: $ISSUE_TITLE\""
echo "   6. make memory-update ISSUE_NUMBER=$ISSUE_NUMBER CHECKBOX=\"Pipeline completo\""

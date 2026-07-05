#!/bin/bash
# listen-issues.sh — Polling de issues abertas
# Uso: make listen-issues

set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
  echo "❌ Não foi possível detectar o repositório."
  exit 1
fi

echo "🔔 Verificando issues abertas em $REPO..."

# Listar issues abertas com label 'memotek'
ISSUES=$(gh issue list --state open --label "memotek" --json number,title,labels \
  --template '{{range .}}#{{.number}} - {{.title}}{{"\n"}}{{end}}' 2>/dev/null || echo "")

if [ -z "$ISSUES" ]; then
  echo "📭 Nenhuma issue pendente encontrada."
  exit 0
fi

echo "📋 Issues encontradas:"
echo "$ISSUES"
echo ""
echo "💡 Para processar uma issue, execute:"
echo "   make process-issue ISSUE_NUMBER=<numero>"

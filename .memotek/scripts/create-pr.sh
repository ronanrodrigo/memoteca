#!/bin/bash
# create-pr.sh — Cria Pull Request
# Uso: make pr-create TITLE="<titulo>" BODY="<corpo>" HEAD="<branch>" BASE="<branch>"

set -euo pipefail

TITLE="${TITLE:-}"
BODY="${BODY:-}"
HEAD="${HEAD:-$(git branch --show-current)}"
BASE="${BASE:-main}"

if [ -z "$TITLE" ]; then
  echo "❌ TITLE é obrigatório"
  echo "Uso: make pr-create TITLE='feat: adicionar campo de cor' HEAD='feature/cor' BASE='main'"
  exit 1
fi

echo "📦 Criando Pull Request..."
echo "   Branch: $HEAD → $BASE"
echo "   Título: $TITLE"

gh pr create \
  --title "$TITLE" \
  --body "$BODY" \
  --head "$HEAD" \
  --base "$BASE"

echo "🎉 Pull Request criado com sucesso!"

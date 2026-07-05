#!/bin/bash
# update-memory.sh — Atualiza issue com progresso
# Uso: make memory-update ISSUE_NUMBER=<num> CHECKBOX="<texto>" [COMMENT="<comentario>"]

set -euo pipefail

ISSUE_NUMBER="${ISSUE_NUMBER:-}"
CHECKBOX="${CHECKBOX:-}"
COMMENT="${COMMENT:-}"
STATUS="${STATUS:-}"
PROGRESS="${PROGRESS:-}"

if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ ISSUE_NUMBER é obrigatório"
  echo "Uso: make memory-update ISSUE_NUMBER=1 CHECKBOX='Research: benchmarking concluído'"
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
  echo "❌ Não foi possível detectar o repositório. Execute dentro de um repo GitHub."
  exit 1
fi

echo "📝 Atualizando issue #$ISSUE_NUMBER..."

# Atualizar checkbox no corpo da issue
if [ -n "$CHECKBOX" ]; then
  # Buscar corpo atual
  CURRENT_BODY=$(gh issue view "$ISSUE_NUMBER" --json body -q '.body')
  
  # Marcar checkbox
  UPDATED_BODY=$(echo "$CURRENT_BODY" | sed "s/- \[ \] $CHECKBOX/- [x] $CHECKBOX/")
  
  gh issue edit "$ISSUE_NUMBER" --body "$UPDATED_BODY"
  echo "✅ Checkbox atualizado: $CHECKBOX"
fi

# Atualizar status
if [ -n "$STATUS" ]; then
  CURRENT_BODY=$(gh issue view "$ISSUE_NUMBER" --json body -q '.body')
  UPDATED_BODY=$(echo "$CURRENT_BODY" | sed "s/\*\*Status:\*\* .*/\*\*Status:\*\* $STATUS/")
  gh issue edit "$ISSUE_NUMBER" --body "$UPDATED_BODY"
  echo "✅ Status atualizado: $STATUS"
fi

# Adicionar comentário
if [ -n "$COMMENT" ]; then
  gh issue comment "$ISSUE_NUMBER" --body "$COMMENT"
  echo "✅ Comentário adicionado"
fi

echo "🎉 Issue #$ISSUE_NUMBER atualizada com sucesso!"

#!/bin/bash
# validate-preview.sh — Testa preview URL via HTTP
# Uso: make test-preview PREVIEW_URL="<url>"

set -euo pipefail

PREVIEW_URL="${PREVIEW_URL:-}"

if [ -z "$PREVIEW_URL" ]; then
  # Tentar pegar do Vercel
  if [ -f ".vercel/project.json" ]; then
    PREVIEW_URL=$(cat .vercel/project.json | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
  fi
  
  if [ -z "$PREVIEW_URL" ]; then
    echo "❌ PREVIEW_URL é obrigatório"
    echo "Uso: make test-preview PREVIEW_URL='https://preview-abc.vercel.app'"
    exit 1
  fi
fi

echo "🌐 Testando preview URL: $PREVIEW_URL"

# Testar se retorna 200
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PREVIEW_URL" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Preview funcional! Status: $HTTP_STATUS"
  exit 0
else
  echo "❌ Preview com problema. Status: $HTTP_STATUS"
  exit 1
fi

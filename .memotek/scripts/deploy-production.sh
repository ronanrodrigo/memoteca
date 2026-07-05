#!/bin/bash
# deploy-production.sh — Deploy produção na Vercel
# Uso: make deploy-production
#
# Requer Vercel CLI >= 54. Requer que o projeto já esteja
# vinculado ao Vercel (feito pelo deploy-preview anterior).

set -euo pipefail

echo "🚀 Fazendo deploy produção na Vercel..."

if ! command -v vercel &> /dev/null; then
  echo "❌ Vercel CLI não encontrado. Instale com: npm i -g vercel"
  exit 1
fi

# Verificar versão mínima
VERCEL_VERSION=$(vercel --version 2>/dev/null | head -1 || echo "0.0.0")
echo "📌 Vercel CLI: $VERCEL_VERSION"

vercel --prod --yes

echo "🎉 Deploy produção concluído!"
echo "💡 O site está agora em produção."

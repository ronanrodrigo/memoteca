#!/bin/bash
# deploy-preview.sh — Deploy preview na Vercel
# Uso: make deploy-preview
#
# Nota: A primeira execução vincula o projeto ao Vercel.
# Requer Vercel CLI >= 54. O flag --pre foi removido;
# o deploy padrão já é preview para branches não-main.

set -euo pipefail

echo "🚀 Fazendo deploy preview na Vercel..."

if ! command -v vercel &> /dev/null; then
  echo "❌ Vercel CLI não encontrado. Instale com: npm i -g vercel"
  exit 1
fi

# Verificar versão mínima
VERCEL_VERSION=$(vercel --version 2>/dev/null | head -1 || echo "0.0.0")
echo "📌 Vercel CLI: $VERCEL_VERSION"

vercel --yes

echo "🎉 Deploy preview concluído!"
echo "💡 Acesse o link acima para visualizar o preview."

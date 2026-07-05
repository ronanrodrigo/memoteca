#!/bin/bash
# deploy-preview.sh — Deploy preview na Vercel
# Uso: make deploy-preview

set -euo pipefail

echo "🚀 Fazendo deploy preview na Vercel..."

if ! command -v vercel &> /dev/null; then
  echo "❌ Vercel CLI não encontrado. Instale com: npm i -g vercel"
  exit 1
fi

vercel --pre --yes

echo "🎉 Deploy preview concluído!"
echo "💡 Acesse o link acima para visualizar o preview."

#!/bin/bash
# deploy-production.sh — Deploy produção na Vercel
# Uso: make deploy-production

set -euo pipefail

echo "🚀 Fazendo deploy produção na Vercel..."

if ! command -v vercel &> /dev/null; then
  echo "❌ Vercel CLI não encontrado. Instale com: npm i -g vercel"
  exit 1
fi

vercel --prod --yes

echo "🎉 Deploy produção concluído!"
echo "💡 O site está agora em produção."

#!/bin/bash
# setup-gh-actions.sh — Configura workflows de CI/CD
# Uso: make gh-actions-setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

echo "⚙️ Configurando GitHub Actions..."

# Criar diretório de workflows se não existir
mkdir -p .github/workflows

# Copiar templates
if [ -f "$TEMPLATES_DIR/deploy.yml" ]; then
  cp "$TEMPLATES_DIR/deploy.yml" .github/workflows/deploy.yml
  echo "✅ Workflow de deploy criado"
fi

if [ -f "$TEMPLATES_DIR/test.yml" ]; then
  cp "$TEMPLATES_DIR/test.yml" .github/workflows/test.yml
  echo "✅ Workflow de testes criado"
fi

echo "🎉 GitHub Actions configurado com sucesso!"
echo "📁 Workflows criados em .github/workflows/"

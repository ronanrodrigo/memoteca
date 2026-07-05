#!/bin/bash
# scaffold-project.sh — Cria projeto Next.js
# Uso: make scaffold PROJECT_NAME="<nome>" [DESCRIPTION="<descricao>"]

set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-}"
DESCRIPTION="${DESCRIPTION:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ PROJECT_NAME é obrigatório"
  echo "Uso: make scaffold PROJECT_NAME='meu-projeto' DESCRIPTION='Sistema de cadastro'"
  exit 1
fi

echo "🏗️ Criando projeto Next.js: $PROJECT_NAME"

# Criar projeto com create-next-app
npx create-next-app@latest "$PROJECT_NAME" \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-npm

cd "$PROJECT_NAME"

echo "📦 Instalando dependências adicionais..."

# Instalar Chakra UI
npm install @chakra-ui/react @emotion/react @emotion/styled framer-motion

# Instalar Supabase
npm install @supabase/supabase-js @supabase/ssr

# Instalar Playwright para E2E
npm install -D @playwright/test

# Instalar Jest para unit tests
npm install -D jest @types/jest ts-jest

echo "📝 Criando Makefile do projeto..."

# Criar Makefile com targets para o projeto
cat > Makefile << 'MAKEFILE'
.PHONY: install build lint typecheck test test-e2e install-playwright deploy

install:
	npm ci

build:
	npm run build

lint:
	npm run lint

typecheck:
	npm run typecheck

test:
	npm test

test-e2e:
	npx playwright test

install-playwright:
	npx playwright install --with-deps

deploy:
	vercel --prod

deploy-preview:
	vercel --pre
MAKEFILE

echo "✅ Projeto criado com sucesso!"
echo "📁 Diretório: $PROJECT_NAME"
echo ""
echo "📋 Próximos passos:"
echo "   1. Configurar variáveis de ambiente (ver .env-example)"
echo "   2. Configurar GitHub Actions (make gh-actions-setup)"
echo "   3. Fazer deploy preview (make deploy-preview)"

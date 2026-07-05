#!/bin/bash
# scaffold-project.sh — Cria ou configura projeto Next.js para CI
# Uso:
#   make scaffold PROJECT_NAME="meu-projeto"         # cria subdiretório
#   make scaffold PROJECT_NAME="."                    # in-place (repo já clonado)
#   SUPABASE=1 make scaffold PROJECT_NAME="."         # com Supabase

set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-}"
SUPABASE="${SUPABASE:-0}"

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ PROJECT_NAME é obrigatório"
  echo "Uso: make scaffold PROJECT_NAME='meu-projeto'"
  echo "     make scaffold PROJECT_NAME='.'  (in-place)"
  exit 1
fi

IS_INPLACE="no"
if [ "$PROJECT_NAME" = "." ]; then
  IS_INPLACE="yes"
  PROJECT_NAME="$(basename "$(pwd)")"
  echo "🏗️ Configurando projeto in-place: $PROJECT_NAME"
else
  echo "🏗️ Criando projeto Next.js: $PROJECT_NAME"
fi

# === Fase 1: Criar projeto com create-next-app ===

if [ "$IS_INPLACE" = "yes" ]; then
  # In-place: create-next-app em diretório não-vazio cria em subpasta temporária
  # e movemos os arquivos pra cá, preservando .memotek, Makefile, AGENTS.md, etc.
  TEMP_DIR="memotek-scaffold-tmp"
  rm -rf "$TEMP_DIR"
  npx create-next-app@latest "$TEMP_DIR" \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --src-dir \
    --import-alias "@/*" \
    --use-npm \
    --no-git

  # Mover arquivos do scaffold pra raiz, preservando arquivos existentes do template
  PRESERVE_LIST=".memotek .github AGENTS.md Makefile opencode.json .env-example .git .gitignore"

  for item in "$TEMP_DIR"/*; do
    basename_item="$(basename "$item")"
    skip="no"
    for preserve in $PRESERVE_LIST; do
      if [ "$basename_item" = "$preserve" ]; then
        skip="yes"
        break
      fi
    done
    if [ "$skip" = "no" ]; then
      cp -r "$item" . 2>/dev/null || true
    fi
  done

  # Copiar dotfiles (escondidos) exceto .git
  for item in "$TEMP_DIR"/.*; do
    basename_item="$(basename "$item")"
    if [ "$basename_item" = "." ] || [ "$basename_item" = ".." ] || [ "$basename_item" = ".git" ]; then
      continue
    fi
    skip="no"
    for preserve in $PRESERVE_LIST; do
      if [ "$basename_item" = "$preserve" ]; then
        skip="yes"
        break
      fi
    done
    if [ "$skip" = "no" ]; then
      cp -r "$item" . 2>/dev/null || true
    fi
  done

  rm -rf "$TEMP_DIR"
else
  npx create-next-app@latest "$PROJECT_NAME" \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --src-dir \
    --import-alias "@/*" \
    --use-npm \
    --no-git
  cd "$PROJECT_NAME"
fi

# === Fase 2: Garantir scripts no package.json ===

echo "📝 Configurando package.json..."

node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

pkg.scripts = pkg.scripts || {};
pkg.scripts.dev = pkg.scripts.dev || 'next dev';
pkg.scripts.build = pkg.scripts.build || 'next build';
pkg.scripts.start = pkg.scripts.start || 'next start';
pkg.scripts.lint = pkg.scripts.lint || 'next lint';
pkg.scripts.typecheck = 'tsc --noEmit';
pkg.scripts.test = 'jest';
pkg.scripts['test:e2e'] = 'playwright test';

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('✅ Scripts configurados no package.json');
"

# === Fase 3: Instalar dependências ===

echo "📦 Instalando dependências..."

# DevDeps para testes
npm install -D jest ts-jest jest-environment-jsdom @types/jest \
  @testing-library/jest-dom @testing-library/react \
  @playwright/test serve

# Supabase opcional
if [ "$SUPABASE" = "1" ]; then
  echo "📦 Instalando Supabase..."
  npm install @supabase/supabase-js @supabase/ssr
fi

# === Fase 4: Criar configs de teste ===

echo "📝 Criando configs de teste..."

cat > jest.config.js << 'JEST'
/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  transform: {
    '^.+\\.(ts|tsx)$': 'ts-jest',
  },
  testPathIgnorePatterns: ['<rootDir>/node_modules/', '<rootDir>/.next/', '<rootDir>/e2e/'],
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts'],
};
JEST

cat > jest.setup.ts << 'JEST_SETUP'
import '@testing-library/jest-dom';
JEST_SETUP

cat > playwright.config.ts << 'PW'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'npx serve out -l 3000',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
PW

mkdir -p e2e

# === Fase 5: Atualizar next.config.ts para output: export ===

echo "📝 Configurando next.config.ts para export estático..."

if [ -f next.config.ts ]; then
  node -e "
const fs = require('fs');
let content = fs.readFileSync('next.config.ts', 'utf8');

// Adicionar output: 'export' se não existir
if (!content.includes('output')) {
  content = content.replace(
    /const\s+nextConfig\s*[:=]\s*\{/,
    \`const nextConfig = {
  output: 'export',\`
  );
  fs.writeFileSync('next.config.ts', content);
  console.log('✅ output: export adicionado ao next.config.ts');
} else {
  console.log('⏭️ output já configurado no next.config.ts');
}
"
fi

# === Fase 6: Criar .gitignore ===

echo "📝 Criando .gitignore..."

cat > .gitignore << 'GITIGNORE'
# dependencies
node_modules/
.pnp
.pnp.js

# testing
coverage/
playwright-report/

# next.js
.next/
out/

# production
build/

# misc
.DS_Store
*.pem

# env files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts
GITIGNORE

# === Fase 7: Criar estrutura de diretórios ===

mkdir -p src/app src/components src/lib src/__tests__ e2e

# === Fase 8: Criar arquivo de teste exemplo ===

if [ ! -f src/app/page.tsx ]; then
  cat > src/app/page.tsx << 'PAGE'
export default function Home() {
  return (
    <main>
      <h1>Welcome</h1>
    </main>
  );
}
PAGE
fi

cat > e2e/example.spec.ts << 'TEST'
import { test, expect } from '@playwright/test';

test('home page loads', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('h1')).toBeVisible();
});
TEST

cat > src/__tests__/example.test.tsx << 'UNITTEST'
import { render, screen } from '@testing-library/react';
import Home from '@/app/page';

test('renders heading', () => {
  render(<Home />);
  expect(screen.getByRole('heading')).toBeInTheDocument();
});
UNITTEST

echo ""
echo "✅ Projeto configurado com sucesso!"
echo "📁 Diretório: $(pwd)"
echo ""
echo "📋 O projeto está pronto para CI. Todos os targets Make funcionam:"
echo "   make install          — instala dependências"
echo "   make lint             — roda linter"
echo "   make typecheck        — verifica tipos"
echo "   make build            — builda o projeto"
echo "   make test             — roda testes unitários (Jest)"
echo "   make test-e2e         — roda testes E2E (Playwright)"
echo "   make deploy-preview   — deploy preview na Vercel"
echo "   make deploy-production — deploy produção na Vercel"

#!/bin/bash
# scaffold-project.sh — Create or configure Next.js project for CI
# Usage:
#   make scaffold PROJECT_NAME="my-project"         # create subdirectory
#   make scaffold PROJECT_NAME="."                  # in-place (repo already cloned)
#   SUPABASE=1 make scaffold PROJECT_NAME="."       # with Supabase

set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-}"
SUPABASE="${SUPABASE:-0}"

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ PROJECT_NAME is required"
  echo "Usage: make scaffold PROJECT_NAME='my-project'"
  echo "     make scaffold PROJECT_NAME='.'  (in-place)"
  exit 1
fi

IS_INPLACE="no"
if [ "$PROJECT_NAME" = "." ]; then
  IS_INPLACE="yes"
  PROJECT_NAME="$(basename "$(pwd)")"
  echo "🏗️ Configuring project in-place: $PROJECT_NAME"
else
  echo "🏗️ Creating Next.js project: $PROJECT_NAME"
fi

# === Phase 1: Create project with create-next-app ===

if [ "$IS_INPLACE" = "yes" ]; then
  # In-place: create-next-app in non-empty directory creates in a temp subfolder
  # and we move the files here, preserving .memoteca, Makefile, AGENTS.md, etc.
  TEMP_DIR="memoteca-scaffold-tmp"
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

  # Move scaffold files to root, preserving existing template files
  PRESERVE_LIST=".memoteca .github AGENTS.md Makefile opencode.json .env-example .git .gitignore"

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

  # Copy hidden dotfiles except .git
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

# === Phase 2: Ensure scripts in package.json ===

echo "📝 Configuring package.json..."

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
console.log('✅ Scripts configured in package.json');
"

# === Phase 3: Install dependencies ===

echo "📦 Installing dependencies..."

# DevDeps for tests
npm install -D jest ts-jest jest-environment-jsdom @types/jest \
  @testing-library/jest-dom @testing-library/react \
  @playwright/test serve

# Optional Supabase
if [ "$SUPABASE" = "1" ]; then
  echo "📦 Installing Supabase..."
  npm install @supabase/supabase-js @supabase/ssr
fi

# === Phase 4: Create test configs ===

echo "📝 Creating test configs..."

cat > jest.config.js << 'JEST'
/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterSetup: ['<rootDir>/jest.setup.ts'],
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
    timeout: 120_000,
  },
});
PW

mkdir -p e2e

# === Phase 5: Update next.config.ts for output: export ===

echo "📝 Configuring next.config.ts for static export..."

if [ -f next.config.ts ]; then
  node -e "
const fs = require('fs');
let content = fs.readFileSync('next.config.ts', 'utf8');

// Add output: 'export' if it doesn't exist
if (!content.includes('output')) {
  content = content.replace(
    /const\s+nextConfig\s*[:=]\s*\{/,
    \`const nextConfig = {
  output: 'export',\`
  );
  fs.writeFileSync('next.config.ts', content);
  console.log('✅ output: export added to next.config.ts');
} else {
  console.log('⏭️ output already configured in next.config.ts');
}
"
fi

# === Phase 6: Create .gitignore ===

echo "📝 Creating .gitignore..."

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

# === Phase 7: Create directory structure ===

mkdir -p src/app src/components src/lib src/__tests__ e2e

# === Phase 7.5: Copy worktree workflow (operational reference) ===

# The Assistant Skill does NOT create plan/MEMORY files in the repo — those live in the
# GitHub issue. The gcp/gpr shortcuts already live in the main Makefile. Here we only
# copy the worktree workflow as an operational reference in docs/.

MEMOTEKA_ROOT=""
for candidate in "$PWD" "$PWD/.." "$PWD/../.."; do
  if [ -f "$candidate/.memoteca/templates/worktree-workflow.md" ]; then
    MEMOTEKA_ROOT="$candidate"
    break
  fi
done

if [ -n "$MEMOTEKA_ROOT" ]; then
  mkdir -p docs
  cp "$MEMOTEKA_ROOT/.memoteca/templates/worktree-workflow.md" docs/worktree-workflow.md 2>/dev/null || true
  echo "✅ docs/worktree-workflow.md copied (operational reference)"
  echo "   Plan and memory are NOT files — they live in the GitHub issue."
else
  echo "⚠️  worktree-workflow.md not found — skipping copy."
fi

# === Phase 8: Create example test file ===

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
echo "✅ Project configured successfully!"
echo "📁 Directory: $(pwd)"
echo ""
echo "📋 The project is ready for CI. All Make targets work:"
echo "   make install          — install dependencies"
echo "   make lint             — run linter"
echo "   make typecheck        — check types"
echo "   make build            — build the project"
echo "   make test             — run unit tests (Jest)"
echo "   make test-e2e         — run E2E tests (Playwright)"
echo "   make deploy-preview   — deploy preview on Vercel"
echo "   make deploy-production — deploy production on Vercel"
echo "   make setup-vercel-secrets — configure Vercel secrets in GitHub Actions"

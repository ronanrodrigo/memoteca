.PHONY: memory-update search-projects gh-actions-setup listen-issues test test-preview pr-create pr-merge deploy-preview deploy-production scaffold install lint typecheck build install-playwright test-e2e

# === MEMORY ===
memory-update:
	@.memotek/scripts/update-memory.sh

# === SEARCH ===
search-projects:
	@.memotek/scripts/search-projects.sh

# === GITHUB AUTOMATION ===
gh-actions-setup:
	@.memotek/scripts/setup-gh-actions.sh

# === INTAKE ===
listen-issues:
	@.memotek/scripts/listen-issues.sh

# === CI: Project Build/Test Targets ===
install:
	@if [ -f package-lock.json ]; then npm ci; else npm install; fi

lint:
	npm run lint

typecheck:
	npm run typecheck

build:
	npm run build

test:
	npm test

install-playwright:
	npx playwright install --with-deps chromium

test-e2e:
	npm run test:e2e

# === TESTES (memotek) ===
test-preview:
	@.memotek/scripts/validate-preview.sh

# === PR ===
pr-create:
	@.memotek/scripts/create-pr.sh

pr-merge:
	@.memotek/scripts/merge-pr.sh

# === DEPLOY ===
deploy-preview:
	@.memotek/scripts/deploy-preview.sh

deploy-production:
	@.memotek/scripts/deploy-production.sh

# === SCAFFOLD ===
scaffold:
	@.memotek/scripts/scaffold-project.sh

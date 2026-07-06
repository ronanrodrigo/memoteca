.PHONY: memory-update memory-finalize search-projects gh-actions-setup listen-issues process-issue test test-preview pr-create pr-merge deploy-preview deploy-production setup-vercel-secrets scaffold install lint typecheck build install-playwright test-e2e gcp gpr gcp-and-gpr

# === MEMORY ===
memory-update:
	@.memotek/scripts/update-memory.sh

memory-finalize:
	@ISSUE_NUMBER="$(ISSUE_NUMBER)" FINALIZE=1 .memotek/scripts/update-memory.sh

# === SEARCH ===
search-projects:
	@.memotek/scripts/search-projects.sh

# === GITHUB AUTOMATION ===
gh-actions-setup:
	@.memotek/scripts/setup-gh-actions.sh

# === INTAKE ===
listen-issues:
	@.memotek/scripts/listen-issues.sh

process-issue:
	@.memotek/scripts/process-issue.sh

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

# === SECRETS ===
setup-vercel-secrets:
	@.memotek/scripts/setup-vercel-secrets.sh

# === SCAFFOLD ===
scaffold:
	@.memotek/scripts/scaffold-project.sh

# === DEV SHORTCUTS (Skill Assistente) ===
# Atalhos operados pelo agente quando o Ronan digita "gcp", "gpr" ou "gcp & gpr".
# gcp        : commit + push  (MESSAGE="feat: ..." ou "fix: ...")
# gpr        : abrir PR       (TITLE="feat: ..." BODY="...")
# gcp-and-gpr: commit + push + PR (nesta ordem, para na primeira falha)
gcp:
	@if [ -z "$(MESSAGE)" ]; then echo "❌ Uso: make gcp MESSAGE='feat: ...' ou 'fix: ...'"; exit 1; fi
	@git add -A
	@git commit -m "$(MESSAGE)"
	@git push

gpr:
	@if [ -z "$(TITLE)" ]; then echo "❌ Uso: make gpr TITLE='feat: ...' BODY='...' (BODY opcional)"; exit 1; fi
	@if [ -n "$(BODY)" ]; then gh pr create --title "$(TITLE)" --body "$(BODY)" --base main; \
	else gh pr create --title "$(TITLE)" --body "" --base main; fi

gcp-and-gpr:
	@if [ -z "$(MESSAGE)" ] || [ -z "$(TITLE)" ]; then echo "❌ Uso: make gcp-and-gpr MESSAGE='feat: ...' TITLE='feat: ...' [BODY='...']"; exit 1; fi
	@git add -A
	@git commit -m "$(MESSAGE)"
	@git push
	@if [ -n "$(BODY)" ]; then gh pr create --title "$(TITLE)" --body "$(BODY)" --base main; \
	else gh pr create --title "$(TITLE)" --body "" --base main; fi

.PHONY: memory-update search-projects gh-actions-setup listen-issues test test-preview pr-create pr-merge deploy-preview deploy-production scaffold

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

# === TESTES ===
test:
	@.memotek/scripts/run-tests.sh

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

.PHONY: memory-update memory-finalize search-projects gh-actions-setup tasks-listen process-issue test test-preview pr-create pr-merge deploy-preview deploy-production setup-vercel-secrets scaffold install lint typecheck build install-playwright test-e2e gcp gpr gcp-and-gpr project-create project-link-repo project-add-issue install-hooks run-orchestrator

# === MEMORY (issue body = source of truth; board Status mirrors pipeline phase) ===
memory-update:
	@.memoteca/scripts/update-memory.sh

memory-finalize:
	@ISSUE_NUMBER="$(ISSUE_NUMBER)" FINALIZE=1 .memoteca/scripts/update-memory.sh

# === SEARCH ===
search-projects:
	@.memoteca/scripts/search-projects.sh

# === GITHUB AUTOMATION ===
gh-actions-setup:
	@.memoteca/scripts/setup-gh-actions.sh

# === BOARD INTAKE — the central "Memoteca" project (private, cross-repo) ===
# First-time setup: create the private board + standard Status/Task Type fields.
project-create:
	@.memoteca/scripts/project-create.sh

# Link a target repo to the board so its issues can be added (once per repo).
#   make project-link-repo                  # current repo
#   make project-link-repo REPO=owner/name
project-link-repo:
	@.memoteca/scripts/project-link-repo.sh

# Explicitly add an issue to the board. Called by the intake flow after filing.
#   make project-add-issue ISSUE_URL=https://github.com/o/r/issues/12
#   make project-add-issue ISSUE_URL=42
#   make project-add-issue ISSUE_URL=owner/repo#42
project-add-issue:
	@.memoteca/scripts/project-add-issue.sh

# === INTAKE / DISPATCH ===
# tasks-listen queries the central board for items Status=Todo (oldest first).
tasks-listen:
	@.memoteca/scripts/tasks-listen.sh

process-issue:
	@.memoteca/scripts/process-issue.sh

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

# === TESTS (memoteca) ===
test-preview:
	@.memoteca/scripts/validate-preview.sh

# === PR ===
pr-create:
	@.memoteca/scripts/create-pr.sh

pr-merge:
	@.memoteca/scripts/merge-pr.sh

# === DEPLOY ===
deploy-preview:
	@.memoteca/scripts/deploy-preview.sh

deploy-production:
	@.memoteca/scripts/deploy-production.sh

# === SECRETS ===
setup-vercel-secrets:
	@.memoteca/scripts/setup-vercel-secrets.sh

# === SCAFFOLD ===
scaffold:
	@.memoteca/scripts/scaffold-project.sh

# === HOOKS ===
# Install the commit-msg hook enforcing <type>: <desc> (#<NN>) in the current repo.
install-hooks:
	@.memoteca/scripts/install-hooks.sh

# === DEV SHORTCUTS (Assistant Skill) ===
# gcp        : commit + push  (MESSAGE="feat: ..." or "fix: ...")
#              The branch name `feature/<NN>-<short>` supplies the issue/board ID;
#              ` (#NN)` is auto-appended to the commit message if not already present.
# gpr        : open PR        (TITLE="feat: ..." BODY="...")
# gcp-and-gpr: commit + push + PR (in this order, stops on first failure)
gcp:
	@if [ -z "$(MESSAGE)" ]; then echo "❌ Usage: make gcp MESSAGE='feat: ...' or 'fix: ...'"; exit 1; fi
	@BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	NN=$$(printf '%s' "$$BRANCH" | sed -nE 's#^feature/([0-9]+).*$$#\1#p'); \
	MSG="$(MESSAGE)"; \
	if [ -n "$$NN" ] && ! printf '%s' "$$MSG" | grep -qE '\(#[0-9]+\) *$$'; then \
	  MSG="$$MSG (#$$NN)"; \
	fi; \
	git add -A; \
	git commit -m "$$MSG"; \
	git push

gpr:
	@if [ -z "$(TITLE)" ]; then echo "❌ Usage: make gpr TITLE='feat: ...' BODY='...' (BODY optional)"; exit 1; fi
	@if [ -n "$(BODY)" ]; then gh pr create --title "$(TITLE)" --body "$(BODY)" --base main; \
	else gh pr create --title "$(TITLE)" --body "" --base main; fi

gcp-and-gpr:
	@if [ -z "$(MESSAGE)" ] || [ -z "$(TITLE)" ]; then echo "❌ Usage: make gcp-and-gpr MESSAGE='feat: ...' TITLE='feat: ...' [BODY='...']"; exit 1; fi
	@BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	NN=$$(printf '%s' "$$BRANCH" | sed -nE 's#^feature/([0-9]+).*$$#\1#p'); \
	MSG="$(MESSAGE)"; \
	if [ -n "$$NN" ] && ! printf '%s' "$$MSG" | grep -qE '\(#[0-9]+\) *$$'; then \
	  MSG="$$MSG (#$$NN)"; \
	fi; \
	git add -A; \
	git commit -m "$$MSG"; \
	git push
	@if [ -n "$(BODY)" ]; then gh pr create --title "$(TITLE)" --body "$(BODY)" --base main; \
	else gh pr create --title "$(TITLE)" --body "" --base main; fi

# === FSM ORCHESTRATOR ===
# Drive the full pipeline programmatically (phases run in order, retries,
# trajectory JSON). Optional flags pass through to orchestrator.py.
#   make run-orchestrator ISSUE_NUMBER=12
#   make run-orchestrator ISSUE_NUMBER=12 AUTO=1 DRY_RUN=1
#   make run-orchestrator ISSUE_NUMBER=12 START_PHASE=implement
#   make run-orchestrator RESUME=.memoteca/trajectories/issue-12-*.json
run-orchestrator:
	@if [ -z "$(ISSUE_NUMBER)" ] && [ -z "$(RESUME)" ]; then echo "Usage: make run-orchestrator ISSUE_NUMBER=<nn> [AUTO=1] [DRY_RUN=1] [START_PHASE=phase] [RESUME=path]"; exit 1; fi
	@FLAGS="--workdir ."; \
	if [ -n "$(ISSUE_NUMBER)" ]; then FLAGS="$$FLAGS --issue $(ISSUE_NUMBER)"; fi; \
	if [ -n "$(AUTO)" ]; then FLAGS="$$FLAGS --auto"; fi; \
	if [ -n "$(DRY_RUN)" ]; then FLAGS="$$FLAGS --dry-run"; fi; \
	if [ -n "$(START_PHASE)" ]; then FLAGS="$$FLAGS --start-phase $(START_PHASE)"; fi; \
	if [ -n "$(RESUME)" ]; then FLAGS="$$FLAGS --resume $(RESUME)"; fi; \
	python .memoteca/orchestrator/orchestrator.py $$FLAGS

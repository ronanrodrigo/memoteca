# AGENTS.md — Rules for Agents

## repo-template vs repo-project (read this first)

There are **two** kinds of repo that share this `AGENTS.md`:

- **repo-template (memoteca, THIS repo)** — A GitHub template. It ships **ONLY** the orchestration harness: `.memoteca/`, `Makefile`, `.github/ISSUE_TEMPLATE/`, `opencode.json`, `.env-example`, `AGENTS.md`, `README.md`. It has **NO** `package.json`, `src/`, lockfile, or Next.js app. `make install/lint/build/test` will **FAIL** here — they require a scaffolded repo-project. The pipeline does NOT run here; memoteca is only the seed.
- **repo-project** — A repo created from this template via GitHub "Use this template". Initially byte-identical to memoteca. Then `make scaffold PROJECT_NAME="."` runs `create-next-app` **in-place** and adds the Next.js app (`src/`, `package.json`, `tsconfig.json`, `next.config.*`, lockfile, ...). The scaffold **preserves** these template files: `.memoteca`, `.github`, `AGENTS.md`, `Makefile`, `opencode.json`, `.env-example`, `.git`, `.gitignore`. The pipeline runs end-to-end in the **repo-project**.

### Placeholders — filled by the AGENT, not the human

A repo-project created from this template contains placeholders (`{PROJECT_NAME}`, `{PROJECT_DESCRIPTION}`, `{REPO_URL}`, `{PREVIEW_URL}`, `{PRODUCTION_URL}`) in its `README.md` and "repo-project" sections. These are filled by the **Implementer agent** during the pipeline (the scaffold step fills name/description/url; the deploy steps fill preview/production URLs) — **not** by Ronan manually. Do not ask the human to edit them by hand.

## Agent Runtime Support (Hermes Agent, OpenCode)

This template is agent-runtime-agnostic. The pipeline targets **Hermes Agent** and **OpenCode** as first-class runtimes.

| Concept | Hermes Agent | OpenCode |
|---|---|---|
| Project context | `.hermes.md` (walks parents to git root, auto-loaded) | `opencode.json` `instructions` |
| Skills | YAML-frontmatter `SKILL.md` under `.memoteca/skills/`, installed via `make hermes-setup` | `opencode.json` `skills.paths` |
| Sub-agents | `delegate_task(goal=...)` (single) or `delegate_task(tasks=[...])` (batch, up to 3) | `task` / `invoke` |
| Memory | `memory` tool (user + memory stores) | N/A |

**Hermes Agent setup** (one-time, in the repo-project after scaffold):

```
make hermes-setup
```

This installs the 3 memoteca skills (`memoteca-assistente`, `memoteca-intake`, `memoteca-pr-visual-evidence`) into the active Hermes profile skill tree (`~/.hermes/skills/`). They are discovered on next session (`/reset` or a new `hermes` invocation). See `.hermes.md` for the full Hermes project context.

When running inside Hermes, prefer `delegate_task` for sub-agent work. When running inside OpenCode, use `task`/`invoke`. The agent docs under `.memoteca/agents/*.md` reference both.

## General Rules

1. **NEVER execute commands directly** — ALWAYS via `make <target>`
   - Prohibited: `gh`, `curl`, `jq`, `yq`, `npm run`, `jest`, etc. directly
   - Exception: internal agent commands (read files, write code)
2. **Mandatory repository** — The user MUST have a project-repo on GitHub (created via "Use this template"). The intake issue is filed in that project-repo (the source of truth). The orchestrator picks the issue up from the central "Memoteca" board — never runs inside the template repo itself.
3. **Precedence** — What is in AGENTS.md takes precedence over agent/skill definitions, **except for topics covered by the Assistant Skill** (`.memoteca/skills/assistente/SKILL.md`), which prevail. See `.memoteca/rules/assistente-precedence.md` for the complete hierarchy.

4. **Assistant Skill active** — GitHub native Mermaid, GitHub issue as source of truth (no plan/memory files in the repo), worktree by feature, `gcp`/`gpr` shortcuts, and Assistant Work Loop are MANDATORY. First response in conversation starts with 💭.

## Orchestration

The primary agent is the orchestrator. When you receive a task, perform the steps in order:

**CRITICAL:** After EACH step of the pipeline, ALWAYS run `make memory-update ISSUE_NUMBER=<num> CHECKBOX="<exact checkbox text>"` to check the corresponding checkbox in the issue body. Don't skip this step — the `[ ]` checkboxes must become `[x]` in real time. At the end of the pipeline, run `make memory-finalize ISSUE_NUMBER=<num>` to check all remaining checkboxes and close the issue.

### Complete pipeline (project creation)
1. **Research** — Read `.memoteca/agents/researcher.md` → run `make search-projects QUERY="<keywords>"` → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Research: benchmarking completed"`
2. **Stack** — Read `.memoteca/agents/stack-selector.md` → define the stack → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Stack defined"`
3. **Implement** — Read `.memoteca/agents/implementer.md` → run `make scaffold PROJECT_NAME="."` → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Code implemented"`
4. **Deploy** — Read `.memoteca/agents/deploy-agent.md` → run `make gh-actions-setup && make deploy-preview` → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Deploy preview functional"`
5. **CI** — Read `.memoteca/agents/ci-agent.md` → validate `make install && make lint && make typecheck && make test && make build` → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="CI pipeline configured"`
6. **PR** — Read `.memoteca/agents/pr-validator.md` → run `make pr-create` → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="PR created"`
7. **Validation + Merge** — `make pr-merge PR_NUMBER=<num>` (the script waits for the checks to finish, up to 15 minutes, and merges automatically if green) → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="All checks green"` → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="PR merged"` → `make deploy-production` → `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Production deploy completed"`
8. **Finalize** — `make memory-finalize ISSUE_NUMBER=<num>` (checks all remaining checkboxes + closes the issue)
   - **Don't ask the user before merging** — if the checks are green, the merge is automatic
   - If checks fail, diagnose via `gh pr checks`, fix, push, and rerun `make pr-merge`
   - The CHECKBOX texts must correspond EXACTLY to the labels in the `feature_request.yml` template

### Partial cycle (addition/correction)
1. Read the corresponding agent in `.memoteca/agents/`
2. Run the appropriate make target
3. Update the issue with `make memory-update ISSUE_NUMBER=<num> CHECKBOX="<step>"`

### Golden rule
- Before each step, read the corresponding agent in `.memoteca/agents/`
- Each step must be completed before moving on to the next
- If a step fails, report it in the issue and wait for the user's decision

## Repo-Project Structure (repo-project, after scaffold)

When cloning via "Use this template", the repo-project already contains everything you need. After `make scaffold PROJECT_NAME="."`, the structure is:

```
repo-project/
├── src/                    ← project code
├── package.json
├── Makefile
├── jest.config.js
├── jest.setup.ts
├── playwright.config.ts
├── .gitignore
├── .env-example
├── AGENTS.md
├── .memoteca/               ← agents and scripts
│   ├── agents/
│   ├── skills/
│   ├── scripts/
│   ├── templates/
│   └── ...
└── .github/workflows/      ← CI/CD
```

## Implementation Pipeline

```
USER (input)
├── Manual prompt → Intake asks questions → Creates issue on GitHub
└── /issues → Checks and processes open issues
         │
         ▼
    ┌─────────────────────────────────────┐
    │  ISSUE CREATED (feature_request.yml) │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌────────────────────────────────────────────────────────────────┐
    │                      ORCHESTRATOR                             │
    └──┬──────────┬──────────┬──────────┬──────────┬──────────┬─────┘
       │          │          │          │          │          │
       ▼          ▼          ▼          ▼          ▼          ▼
    Research   Stack     Implement   Deploy      CI       PR
    Searcher  Selector                Agent     Agent   Validator

    All run via: make <target>
```

```mermaid
graph TB
    User([USER])
    User -->|Manual Prompt| Intake[Intake Skill]
    User -->|/issues| Polling["/issues → make tasks-listen"]
    Intake --> Issue["Issue in target repo<br/>(memoteca label)"]
    Polling --> Board[(Memoteca board<br/>Status=Todo, oldest)]
    Intake -->|"make project-add-issue"| Board
    Issue -.->|"linked"| Board
    Board -->|pick oldest Todo| Orch[ORCHESTRATOR<br/>fixed workspace dir]
    Orch --> Research[Researcher]
    Orch --> StackSel[Stack Selector]
    Orch --> Impl[Implementer]
    Orch --> Dep[Deploy Agent]
    Orch --> CI[CI Agent]
    Orch --> PR [PR Validator]
    Research --> StackSel --> Impl --> Dep --> CI --> PR
    PR -->|Green checks| Merge[Merge PR]
    PR -->|Red checks| Retry[Diagnose → fix → push → retry]
    Retry --> PR
    Merge --> Prod[Deploy Production]
    Memory[Memory Agent] -.->|memory-update<br/>checks box + mirrors Status| Issue
    Memory -.->|same call| Board
    Prod -.->|finalize| Board
```

## Pipeline Steps

| # | Step | Agent | Action | Make Target |
|---|-------|--------|------|-------------|
| 1 | Input | - | User clones template via "Use this template" | - |
| 2 | Intake | Intake (skill) | Creates GitHub issue with question template | `make memory-update` |
| 2.0 | Board setup (once) | - | Create central board + link repo | `make project-create && make project-link-repo` |
| 2.05 | Add to board | Intake (skill) | Adds the new issue to the central board | `make project-add-issue ISSUE_URL=...` |
| 2.1 | Polling | - | User types `/issues` to query the central board | `make tasks-listen` |
| 3 | Research | Researcher | Searches for open source projects on GitHub | `make search-projects` |
| 3.1 | Benchmarking | Researcher | Analyzes top 3 by stars | (internal) |
| 3.2 | Fallback | Researcher | If nothing is found, asks the user | (interaction) |
| 4 | Stack | Stack Selector | Selects from the predefined list | (internal) |
| 5 | Implement | Implementer | Configures Next.js project via scaffold | `make scaffold PROJECT_NAME="."` |
| 6 | Deploy | Deploy Agent | Configures preview on Vercel | `make gh-actions-setup` + `make deploy-preview` |
| 7 | CI | CI Agent | Configures test pipeline | `make gh-actions-setup` |
| 8 | Validate | PR Validator | Monitors checks, tests preview URL | `make test-preview` |
| 8.1 | Merge | PR Validator | Merge PR when all is green | `make pr-merge` |
| 8.2 | Prod | PR Validator | Deploy production | `make deploy-production` |
| 9 | Memory | Memory Agent | Update issue with progress + Mermaid | `make memory-update` |

## Makefile Targets

### Pipeline (memoteca)
| Target | Description |
|--------|-----------|
| `make scaffold` | Creates/configures Next.js project |
| `make gh-actions-setup` | Copies workflows to .github/workflows/ |
| `make memory-update` | Checks the checkbox in the issue body AND mirrors Status to the board |
| `make memory-finalize` | Checks ALL checkboxes + closes the issue (and sets board Status=Done) |
| `make search-projects` | Searches for similar projects on GitHub |
| `make tasks-listen` | Queries the central "Memoteca" board for items Status=Todo (oldest first) — entry point |
| `make process-issue ISSUE_URL=<url>` | Fetches an issue (cross-repo) and prints next make targets |
| `make test-preview` | Tests preview URL via HTTP |
| `make pr-create` | Creates Pull Request |
| `make pr-merge` | Merges Pull Request |
| `make deploy-preview` | Deploy preview on Vercel |
| `make deploy-production` | Deploy production on Vercel |
| `make setup-vercel-secrets` | Configures Vercel secrets in GitHub Actions |
| `make project-create` | Creates the private "Memoteca" board + Status/Task Type fields (idempotent) |
| `make project-link-repo [REPO=o/r]` | Links a repo to the board so its issues can be added (once per repo) |
| `make project-add-issue ISSUE_URL=...` | Adds a `memoteca`-labelled issue to the board, sets Status=Todo + parses Task Type |
| `make install-hooks` | Installs the commit-msg hook enforcing `<type>: <desc> (#<NN>)` |
| `make hermes-setup` | Installs the 3 memoteca skills into the active Hermes profile skill tree (~/.hermes/skills/) — symlinks on POSIX, copies on Windows |

### CI/CD (repo-project)
| Target | Description |
|--------|-----------|
| `make install` | Installs dependencies (npm ci or npm install) |
| `make lint` | Runs linter |
| `make typecheck` | Checks types (tsc --noEmit) |
| `make build` | Builds the project |
| `make test` | Runs unit tests (Jest) |
| `make install-playwright` | Installs Playwright + Chromium |
| `make test-e2e` | Runs E2E tests (Playwright) |
| `make gcp` / `gpr` / `gcp-and-gpr` | commit+push / open PR / both — `gcp` auto-injects `(#NN)` from the `feature/<NN>-<short>` branch |

## Worktree & git shortcuts

The Orchestrator runs from a fixed workspace dir (default `~/Developer/memoteca-workspaces/`, overridable via `MEMOTEKA_WORKSPACE_DIR`). For each Todo item on the board:

1. Locate or `gh repo clone` the target repo into the workspace dir.
2. Create a worktree off the target repo's main branch named **`feature/<NN>-<short>`** where `<NN>` is the issue number and `<short>` is 3-5 descriptive chars.
3. All work, commits, tests and pushes happen in that worktree until the PR merges.
4. After merge, `git worktree remove` and clean up the branch.

Commits in the project-repo MUST follow the format:

```
<type>: <description> (#<NN>)
```

- `<type>` ∈ {feat, fix, docs, chore, refactor, test}
- `(#NN)` is the GitHub issue / board item ID for the work in flight. `.git` auto-links `#NN` to the right issue (since the issue lives in the same repo).
- `make gcp` / `make gcp-and-gpr` **auto-inject** ` (#NN)` from the branch name when not already present in the message.
- `make install-hooks` installs a lightweight shell `commit-msg` hook that rejects any manually-written `git commit` not matching the pattern (bypass for merges/reverts).

The plan, memory, and task board are NOT files in the repo — they live in the GitHub issue (body + sequential comments via `make memory-update ... COMMENT="..."`) and the cross-task queue on the central board.

## Three Types of Input

### 1. Initial Project Creation
Example: "Create a system for registering chemical components"
- Issue with fields: project type, persistence, desired stack, references
- Triggers full pipeline: intake → research → stack → implement → deploy → CI

### 2. Addition to the System
Example: "Add color field for each chemical component in the form"
- Issue with fields: affects which files/components, dependencies
- Triggers partial cycle: intake → implement → deploy preview → test → merge

### 3. Bug Fix
Example: "The abbreviation field is not saving capital letters"
- Issue with fields: steps to reproduce, expected vs. current behavior
- Triggers fix cycle: intake → diagnose → fix → test → merge

## Predefined Stack

- **Next.js** — Framework
- **React** — UI
- **Vercel** — Deploy
- **Supabase** — Backend/Database (optional via `SUPABASE=1`)
- **Playwright** — E2E tests
- **TypeScript** — Language
- **Jest** — Unit tests
- **GitHub Actions** — CI/CD pipeline

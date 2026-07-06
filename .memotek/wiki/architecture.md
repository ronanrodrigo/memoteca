# Memotek Architecture

## Overview

Memotek is a system of autonomous agents for software development, built as a template repository.

## Components

### Agents
Each agent is a specialized sub-agent that executes a specific pipeline step:

1. **Orchestrator** — Coordinates the entire pipeline
2. **Researcher** — Searches for projects for benchmarking
3. **Stack Selector** — Defines the technology stack
4. **Implementer** — Generates and implements code
5. **Deploy Agent** — Configures deployment on Vercel
6. **CI Agent** — Configures CI/CD
7. **PR Validator** — Monitors and validates PRs
8. **Memory Agent** — Updates issue with progress

### Skills
Skills are instruction sets for specific tasks:
- **Intake** — Collects user input and creates issues

### Scripts
Shell scripts that encapsulate complex commands:
- `project-common.sh` — Resolves the central "Memoteca" board (sourced helper)
- `project-create.sh` — Create the private board + fields
- `project-link-repo.sh` — Link a repo to the board
- `project-add-issue.sh` — Add a `memotek`-labelled issue to the board
- `tasks-listen.sh` — Query the board for items Status=Todo (oldest first) — entry point
- `process-issue.sh` — Fetch an issue (cross-repo) and print next make targets
- `update-memory.sh` — Check an issue checkbox, post comment, AND mirror Status to the board
- `install-hooks.sh` — Install the commit-msg hook enforcing `(#NN)`
- `search-projects.sh` — Search projects
- `setup-gh-actions.sh` — Configure CI/CD
- `run-tests.sh` — Run tests
- `validate-preview.sh` — Test preview
- `create-pr.sh` — Create PR
- `merge-pr.sh` — Merge PR
- `deploy-preview.sh` — Deploy preview
- `deploy-production.sh` — Deploy production
- `scaffold-project.sh` — Create project

## Data Flow

```
User → Intake → Issue in target repo → make project-add-issue → Memoteca board → make tasks-listen
       → Orchestrator (worktree in fixed workspace dir) → Pipeline → Deploy → Updated Issue + board Status
```

## Directory Structure

```
memotek/
├── AGENTS.md              # Rules for agents
├── Makefile               # Targets for scripts
├── opencode.json          # opencode configuration
├── .env-example           # Environment variables
├── .github/
│   └── ISSUE_TEMPLATE/
│       └── feature_request.yml
├── .memotek/
│   ├── agents/            # Agent definitions
│   ├── skills/            # Available skills
│   ├── scripts/           # Shell scripts
│   ├── templates/         # GitHub Actions templates
│   ├── tasks/             # Task templates
│   ├── rules/             # Project rules
│   └── wiki/              # Documentation
└── .opencode/             # Default configuration
```

## Design Decisions

1. **Issue = source of truth; board = mirror** — The GitHub issue (filed in the target repo) holds the per-task timeline; the private "Memoteca" GitHub Project board mirrors the pipeline `Status` (cross-task queue).
2. **Central board** — Private, owned by the user's personal account, cross-repo. Identity is resolved at runtime by listing user projects and matching the title "Memoteca" — no `.env` entry required.
3. **Auto-add by label isn't API-creatable** — `deleteProjectV2Workflow` exists in GraphQL but `createProjectV2Workflow` does not. Auto-add is therefore web-UI-only; the templates' default path is explicit `make project-add-issue`.
4. **Scripts via Make** — All commands are executed via `make <target>`
5. **Predefined stack** — Next.js + React + Vercel + Supabase + Chakra UI
6. **Issue templates** — A single template for 3 task types
7. **Manual execution** — User types `/issues` to `make tasks-listen`
8. **Fixed workspace dir** — Orchestrator runs from `~/Developer/memotek-workspaces/`, cloning target repos on demand and creating a worktree `feature/<NN>-<short>` per task
9. **Commit format** — `<type>: <description> (#<NN>)` enforced by `make install-hooks`

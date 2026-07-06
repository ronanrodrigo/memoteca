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
- `update-memory.sh` — Update issue
- `search-projects.sh` — Search projects
- `setup-gh-actions.sh` — Configure CI/CD
- `listen-issues.sh` — Polling of issues
- `run-tests.sh` — Run tests
- `validate-preview.sh` — Test preview
- `create-pr.sh` — Create PR
- `merge-pr.sh` — Merge PR
- `deploy-preview.sh` — Deploy preview
- `deploy-production.sh` — Deploy production
- `scaffold-project.sh` — Create project

## Data Flow

```
User → Intake → GitHub Issue → Orchestrator → Pipeline → Deploy → Updated Issue
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

1. **Issue as memory** — The issue created by intake serves as the memory
2. **Scripts via Make** — All commands are executed via `make <target>`
3. **Predefined stack** — Next.js + React + Vercel + Supabase + Chakra UI
4. **Issue templates** — A single template for 3 task types
5. **Manual execution** — User types `/issues` to check issues

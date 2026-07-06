# Project Rules

## General Rules

1. **NEVER execute commands directly** — ALWAYS via `make <target>`
   - Prohibited: `gh`, `curl`, `jq`, `yq`, `npm run`, `jest`, etc. directly
   - Exception: internal agent commands (read files, write code)

2. **Mandatory repo** — The user MUST have a project-repo on GitHub (created via "Use this template"). The intake issue is filed there. The orchestrator picks it up from the central board — never runs inside the template repo.

3. **Central board** — A private GitHub Projects V2 board titled "Memoteca" lives on the user's personal account, cross-repo by design. Tasks can target any repo the user has access to. Setup once with `make project-create && make project-link-repo`. The board identity (owner + number + Projects V2 node ID) is resolved at runtime by `.memoteca/scripts/project-common.sh` — no `.env` entries required. Auto-add-by-label is web-UI-only (the GraphQL API exposes `deleteProjectV2Workflow` but not its `create` counterpart), so the templates rely on `make project-add-issue` from the intake flow.

4. **Precedence** — What is in AGENTS.md takes precedence over agent/skill definitions, **except for topics covered by the Assistant Skill** (`.memoteca/skills/assistente/SKILL.md`), which prevail. See `.memoteca/rules/assistente-precedence.md` for the complete hierarchy.

5. **Versioning** — Each implementation is versioned with the model code: `memoteca-<model>`

6. **Assistant Skill active** — GitHub native Mermaid, GitHub issue as source of truth (no plan/memory files in the repo), worktree by feature, `gcp`/`gpr` shortcuts, and Assistant Work Loop are MANDATORY. First response in conversation starts with 💭.

7. **Memory = GitHub issue (mirrored to the board)** — NEVER maintain plan/memory/TODO files committed or ignored in the repository. All context, plan, decisions, and state live as sequential comments in the GitHub issue itself. The board mirrors the pipeline stage via `Status` (8 values: Todo / Research / Implementation / Review / PR/Merge / Deploy / Done, plus Backlog). Issue body is the source of truth; board mirror is best-effort (non-fatal).

8. **Commits** — In every project-repo worktree, commits MUST follow `<type>: <description> (#<NN>)` where `(#NN)` is the issue / board item ID. Worktree branch is `feature/<NN>-<short>`. `make gcp` / `make gcp-and-gpr` auto-inject `(#NN)` from the branch; `make install-hooks` installs a `commit-msg` validator for manual commits.

## Code Conventions

- Use TypeScript for all projects
- Follow Next.js App Router patterns
- Use Chakra UI for components
- Implement tests for main features
- Document APIs and components

## Assistant Skill Conventions (prevail on these topics)

- **Mermaid**: GitHub native (```mermaid block) — Do NOT use external viewer links; GitHub renders Mermaid natively in issues, PRs, and comments.
- **Memory/Plan**: ALWAYS live in the GitHub issue (body + comments), via `make memory-update ISSUE_NUMBER=<num> CHECKBOX="..." COMMENT="..."`. NEVER create `docs/agent-plans/<proj>/MEMORY.md`, `TODO.md`, `plan-<proj>.md` or equivalents in the repo.
- **Human gate**: Before implementing, post the plan as a comment on the issue and wait for "ok". When "ok" is given, run `make memory-update ISSUE_NUMBER=<num> STATUS="Plan approved" COMMENT="Plan approved — starting implementation."`.
- **Worktree**: Each feature in an isolated `git worktree` from the main branch, named `feature/<NN>-<short>`.
- **Sub-agents**: Use `task` for parallelism and `invoke` for expertise.
- **Shortcuts**: `gcp` (commit+push), `gpr` (PR), `gcp & gpr` (commit+push+PR). `gcp` auto-injects `(#NN)` from the branch name.
- **Commit format**: `<type>: <description> (#<NN>)` — enforced by `make install-hooks`.
- **Emoji**: First response in each new conversation starts with 💭.

## Security

- NEVER expose API keys in code
- Use environment variables for configuration
- Create `.env-example` with documented variables
- NEVER commit `.env` to the repository

## Deploy

- Automatic deploy preview for PRs
- Automatic production deploy for merge to main
- Validate preview before merge
- Monitor deploy status

## Testing

- Run tests before merge
- Cover main features with tests
- Use Playwright for E2E tests
- Use Jest for unit tests

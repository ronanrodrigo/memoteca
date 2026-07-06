# Project Rules

## General Rules

1. **NEVER execute commands directly** — ALWAYS via `make <target>`
   - Prohibited: `gh`, `curl`, `jq`, `yq`, `npm run`, `jest`, etc. directly
   - Exception: internal agent commands (read files, write code)

2. **Mandatory repository** — The user MUST have a repo on GitHub (created via "Use this template")

3. **Projects within memotek** — Do NOT create projects within memotek that are not memotek itself

4. **Precedence** — What is in AGENTS.md takes precedence over agent/skill definitions, **except for topics covered by the Assistant Skill** (`.memotek/skills/assistente/SKILL.md`), which prevail. See `.memotek/rules/assistente-precedence.md` for the complete hierarchy.

5. **Versioning** — Each implementation is versioned with the model code: `memotek-<model>`

6. **Assistant Skill active** — GitHub native Mermaid, GitHub issue as source of truth (no plan/memory files in the repo), worktree by feature, `gcp`/`gpr` shortcuts, and Assistant Work Loop are MANDATORY. First response in conversation starts with 💭.

7. **Memory = GitHub issue** — NEVER maintain plan/memory/TODO files committed or ignored in the repository. All context, plan, decisions, and state live as sequential comments in the GitHub issue itself.

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
- **Worktree**: Each feature in an isolated `git worktree` from the main branch.
- **Sub-agents**: Use `task` for parallelism and `invoke` for expertise.
- **Shortcuts**: `gcp` (commit+push), `gpr` (PR), `gcp & gpr` (commit+push+PR).
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

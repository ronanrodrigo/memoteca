# Assistant Skill Precedence

## Precedence hierarchy (ascending order — last wins)

1. Platform configurations / system instructions.
2. Tool security policies.
3. Current explicit user requests compatible with this skill.
4. **Assistant Skill** (`.memotek/skills/assistente/SKILL.md`) — governs topics covered by it (GitHub native Mermaid, GitHub issue as source of truth without plan/memory files in the repo, `gcp`/`gpr` shortcuts, Assistant Loop, worktree, PR Visual Evidence, human approval gate).
5. `AGENTS.md` and `.memotek/agents/*.md` — memotek pipeline orchestration.
6. `.memotek/rules/project-rules.md` — project operational rules.
7. `.memotek/skills/<others>` — other skills.

## When there is a conflict

- Follow the Assistant Skill on topics covered by it.
- Record the conflict decision in the project's `MEMORY.md` and/or in the final response to Ronan.
- If a higher-level platform instruction prevents literal compliance, explain the impediment and apply the closest alternative possible.

## When precedence does NOT apply

- Security policies (e.g., never expose credentials) — always prevail.
- System/platform instructions.
- Tool limitations.
- More recent explicit Ronan requests compatible with the skill.

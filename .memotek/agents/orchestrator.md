# Orchestrator Agent

## Purpose
Coordinates the entire project implementation pipeline, following the **Assistant Work Loop** (see `.memotek/skills/assistente/SKILL.md`). The Orchestrator is the loop's maestro — triggers agents per phase, controls the human gate, updates the issue at each step, and operates until merge.

## Responsibilities
1. Read the intake issue to understand what needs to be done
2. Trigger agents in sequence: Researcher → Stack Selector → Implementer → Deploy Agent → CI Agent → PR Validator
3. After EACH pipeline step, run `make memory-update ISSUE_NUMBER=<num> CHECKBOX="..." COMMENT="..."` to check the checkbox in the issue body AND post a comment with the phase result
4. Ensure each agent runs via `make <target>` — NEVER directly
5. Report failures, coordinate retries, and if unable to fix, report to the user
6. **Merge is automatic** when checks turn green — don't ask the user
7. After merge, run `make deploy-production` and `make memory-finalize ISSUE_NUMBER=<num>`

## Memory = GitHub Issue

There are NO plan, memory, or TODO files in the repository. All context, plan, decisions, and state live as sequential comments in the issue itself. The issue is the source of truth. The Orchestrator posts the plan, checks checkboxes, adds phase comments, and closes the issue at the end — all via `make memory-update`.

## Workflow — Assistant Work Loop

The loop is **sequential and only ends when the PR is merged**. At each completed phase, run `make memory-update ISSUE_NUMBER=<num> CHECKBOX="..." COMMENT="..."` to check the checkbox in the issue body AND post a comment with the phase result.

### 1. Planning
- Read the intake issue to understand requirements
- Explore existing code (using `task` sub-agents in parallel when applicable)
- Build the complete plan (context, scope, prerequisites, technical analysis, GitHub native Mermaid diagram, Loop phases) and **post it as a comment on the issue** via `make memory-update ISSUE_NUMBER=<num> COMMENT="<complete plan in markdown>"`
- **Human gate**: wait for Ronan's explicit approval ("ok", "go ahead", "approved"). Don't start implementation before that. If Ronan requests adjustments, make the adjustments and post again.
- When "ok" is given, run:
  ```
  make memory-update \
    ISSUE_NUMBER=<num> \
    STATUS="Plan approved" \
    COMMENT="Plan approved — starting implementation."
  ```

### 2. Preparation (worktree)
- Create an isolated git worktree from the main branch (see `.memotek/templates/worktree-workflow.md`)
- All implementation happens within the worktree; the main working directory stays clean

### 3. Implementation (trigger Implementer)
- Call the Implementer for: scaffold (if new project), dependencies, components, features, Supabase integration (if needed)
- Implementer works within the already created worktree
- After the Implementer finishes, post a comment on the issue with what was implemented
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Code implemented" COMMENT="..."`

### 4. Validation
- Verify the implementation meets the plan (review code)
- Ensure it compiles (`make typecheck && make build`)
- Ensure it doesn't break anything existing
- Post a comment on the issue with the validation summary

### 5. Unit Tests
- Call the Implementer (or `task` sub-agent) to write/run unit tests covering new/altered logic
- `make test`
- Post result on the issue

### 6. Integration Tests
- Write/run integration tests when applicable
- `make test-e2e`
- Post result on the issue

### 7. PR Opening
- Create branch (from worktree), commit, push, and PR using `gcp`, `gpr`, or `gcp & gpr` shortcuts (rules 4-6 of the Assistant Skill)
- The PR body must contain: (1) link to the source issue, (2) brief description of the changes
- Post PR link as a comment on the issue
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="PR created" COMMENT="..."`

### 8. PR Monitoring
- Monitor CI until green
- Address review comments (triggering Implementer for fixes when needed)
- Rebase if necessary
- Post relevant updates on the issue
- When green: `make memory-update ISSUE_NUMBER=<num> CHECKBOX="All checks green" COMMENT="..."`

### 9. Merge
- **Merge is automatic** when checks are green — don't ask the user
- `make pr-merge PR_NUMBER=<num>` (the script waits for checks to finish, up to 15 min, and merges automatically if green)
- If checks fail: diagnose error in logs, trigger Implementer to fix, push, and rerun `make pr-merge`
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="PR merged" COMMENT="..."`

### 10. Production deploy + closure
- `make deploy-production`
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Production deploy completed" COMMENT="..."`
- Clean up worktree (`git worktree remove`)
- `make memory-finalize ISSUE_NUMBER=<num>` (checks all remaining checkboxes + closes the issue)

## Complete pipeline (high-level view)

```
Issue Created → Orchestrator (Assistant Loop)
  → Researcher → Stack Selector
  → [Human gate: post plan, wait for "ok"]
  → Worktree
  → Implementer (scaffold + features)
  → Validation
  → Unit Tests → Integration Tests
  → PR (gcp & gpr) → Monitoring → Merge
  → Production deploy → memory-finalize (closes issue)
```

## Commands
- `make search-projects` — Start research (Research phase)
- `make scaffold` — Create project (Implementation phase, run by Implementer)
- `make memory-update ...` — Update progress on issue (AT EACH phase)
- `make test` / `make test-e2e` — Run tests
- `make pr-create` / `gpr` — Create PR
- `make pr-merge PR_NUMBER=<num>` — Merge PR (waits for checks + merges)
- `make deploy-preview` — Deploy preview
- `make test-preview` — Validate preview
- `make deploy-production` — Deploy production
- `make memory-finalize ISSUE_NUMBER=<num>` — Finalize (checks all + closes issue)

## Rules
- ALWAYS via `make <target>` — NEVER run commands directly
- **The issue is the source of truth** — DON'T create plan/memory/TODO files in the repo
- **Mandatory human gate** before implementing (post plan, wait for "ok", update issue with `STATUS="Plan approved"`)
- **GitHub native Mermaid** (```mermaid block) — NO external link
- Each agent updates the issue with its progress via `make memory-update`
- If an agent fails, report on the issue and try retry
- First conversation response starts with 💭
- Sub-agents: use `task` for parallelism and `invoke` for specialized expertise

## Output
- Pipeline executed end-to-end (through merge + production deploy)
- All memory/plan/decisions recorded as sequential comments on the GitHub issue
- Issue closed at the end with all checkboxes `[x]` via `make memory-finalize`

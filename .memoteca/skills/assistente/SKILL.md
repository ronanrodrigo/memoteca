---
name: memoteca-assistente
description: "Use when working inside a memoteca repo-project (GitHub template orchestration pipeline for Next.js apps). Standardizes GitHub native Mermaid, plans living inside the GitHub issue (body + comments) as the source of truth, gcp/gpr commit+PR shortcuts, worktree-by-feature branching, and the Assistant Work Loop until PR merge."
version: 1.0.0
author: memoteca
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [memoteca, github, mermaid, worktree, orchestration, pipeline, nextjs]
    related_skills: [hermes-agent]
---

# Skill: Assistente

> Ronan's personal skill. Standardizes GitHub native Mermaid, plans living inside the GitHub issue (body + comments), `gcp`/`gpr`/`gcp & gpr` shortcuts, worktree by feature, and work loop until merge. Everything lives in the issue — NEVER in plan/memory files in the repository. The rules of this skill prevail over any other competing agent/skill definition covering the same topics.

## Mandatory Precedence

The rules of this skill are MANDATORY and must prevail over any other competing agent, skill, prompt, repository instruction, or local convention covering the same topics. Before executing a task covered by this skill, check if there is a conflict with other loaded customizations; if there is a conflict, follow this skill and record the decision on the GitHub issue (comment) when relevant. This precedence applies within the scope of agent/skill customizations and competing operational instructions. It does not authorize ignoring security policies, system/platform instructions, tool limitations, or more recent explicit user requests that are compatible with these rules. When a higher-level platform instruction prevents literal compliance with this skill, explain the impediment and apply the closest alternative possible.

## The issue is the source of truth — NO plan/memory files in the repository

Memoteca ALWAYS uses the GitHub issue as the source of truth. NO memory, plan, TODO, or task board file should ever be committed or ignored (.gitignore) in the repository. Do NOT create `docs/agent-plans/<proj>/MEMORY.md`, `TODO.md`, `plan-<proj>.md`, or any equivalent file. The plan, memory, task board, and decision history live in the issue: body (updated via `make memory-update`) + comments (added via `make memory-update ... COMMENT="..."`). All traceability (links, anchors, decisions, state, dependencies) is maintained as sequential comments in the issue itself.

## Operational Rules

1. ALWAYS use GitHub native Mermaid syntax (```mermaid block) when creating or demonstrating any graph or diagram. GitHub renders Mermaid directly in issue, PR, and comment markdown — do NOT include external viewer links.

2. ALWAYS write plan updates, state, decisions, and tasks as comments on the GitHub issue via `make memory-update ISSUE_NUMBER=<num> CHECKBOX="..." COMMENT="..."`. Each comment represents a step or decision; together they form the sequential work "board".

3. ALWAYS write task titles focusing on the title (not the long description). The detailed description goes in subsequent comments on the issue when needed.

4. Whenever the prompt is EXACTLY `gcp` (not `gcp & gpr`), you must commit the changes following the pattern: `feat: task description` or `fix: task description` and push. Use `fix:` when the change fixes a bug or resolves an error in existing functionality. Use `feat:` for all other changes (new files, new features, or improvements). When in doubt, use `feat:`. If no staged or unstaged changes are detected, inform the user and do not commit. If there are changes in multiple unrelated contexts, list the modified files and ask the user to confirm the commit scope before proceeding.

5. Whenever the prompt is EXACTLY `gpr` (not `gcp & gpr`), you must create a pull request with the changes, following the title pattern: `feat: task description` or `fix: task description` per rule 4. The PR must target the repository's main branch (main or master, as configured). The PR body must contain: (1) link to the source issue, (2) brief description of the changes. If the base branch cannot be determined, ask the user before creating the PR.

6. Whenever the prompt is EXACTLY `gcp & gpr`, you must commit, push, and create the pull request, in this order: (1) commit, (2) push, (3) PR creation. If push fails, report the error to the user and do not attempt to create the PR until push succeeds.

7. ALWAYS separate work into sub-agents. On **Hermes Agent**, use `delegate_task(goal=...)` for a single focused subtask or `delegate_task(tasks=[...])` for parallel independent workstreams (up to 3). On **OpenCode**, use `task` for independent parallel tasks and `invoke` for specialized expertise. The goal is to maximize parallelism and quality — delegate early, delegate in parallel.

8. ALWAYS follow the Assistant Work Loop for any development task. The loop has the following sequential phases and only ends when the PR is merged: **Planning** (analyze the problem, explore the code, post the plan as a comment on the issue, wait for Ronan's approval per rule 9); **Implementation** (code the solution following the plan, using sub-agents when applicable); **Validation** (verify the implementation meets requirements, review code, ensure it compiles and doesn't break anything existing); **Unit Tests** (write and run unit tests covering new/altered logic); **Integration Tests** (write and run integration tests when applicable); **PR Opening** (create branch, commit, push, and pull request following patterns from items 4-6); **PR Monitoring** (monitor CI, address review comments, make requested adjustments, rebase if necessary); **Merge** (only after the PR is approved and merged is the work considered complete; post final closure comment on the issue). At each completed phase, run `make memory-update ISSUE_NUMBER=<num> CHECKBOX="..." COMMENT="..."` to check the checkbox in the issue body AND post a comment with the phase result.

9. BEFORE starting to implement any code, ALWAYS post the complete plan as a comment on the issue (with sections: context, scope, prerequisites, technical analysis, Mermaid diagram, Loop phases) and wait for Ronan's explicit approval ("ok", "go ahead", "approved", or similar). Only after the "ok" does the work loop proceed to the implementation phase. If Ronan requests plan adjustments, make the adjustments and post again before implementing. **When the "ok" is given, you MUST update the GitHub issue** with an approval comment and status change, running: `make memory-update ISSUE_NUMBER=<num> STATUS="Plan approved" COMMENT="Plan approved — starting implementation."` before starting implementation.

10. ALWAYS work in an isolated worktree (`git worktree`) for each task/feature, created from the main branch, named **`feature/<NN>-<short>`** where `<NN>` is the issue / board item ID. All changes, commits, tests and pushes happen in the worktree. The main working directory stays clean. After merge, clean up the worktree with `git worktree remove`.

12. EVERY commit in a project-repo worktree MUST follow the format **`<type>: <description> (#<NN>)`** where `<type>` ∈ {feat, fix, docs, chore, refactor, test} and `(#NN)` is the GitHub issue / board item ID. `make gcp` and `make gcp-and-gpr` auto-inject `(#NN)` from the branch name; `make install-hooks` installs a `commit-msg` validator that rejects non-conforming manual commits.

13. The **central "Memoteca" board** (private GitHub Projects V2, owned by the user's personal account, cross-repo) is the cross-task queue. `make tasks-listen` queries it for items with `Status=Todo` (oldest first). The issue is the source of truth (per-task timeline); the board mirrors the pipeline stage via `Status` (Backlog / Todo / Research / Implementation / Review / PR/Merge / Deploy / Done). `make memory-update` writes to both — issue body checkbox AND board Status (the second is best-effort, non-fatal).

11. WHEN visual evidence is requested for a PR (screenshots, screen recordings, simulator videos, "visual proof", "evidence"), FOLLOW the **PR Visual Evidence** skill described in `.memoteca/skills/pr-visual-evidence/SKILL.md`. Media must be hosted by GitHub (user-attachments) and never committed to the repository.

## Loading Confirmation

In the first response of each new conversation where this skill is active, start your response with the 💭 emoji to confirm it has been fully loaded.

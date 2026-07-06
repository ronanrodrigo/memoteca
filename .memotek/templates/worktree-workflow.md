# Worktree Workflow (Assistant Skill)

## Principle

Each feature/task is worked on in an isolated git worktree from the repo's main branch. This keeps the main working directory clean and allows working on multiple features in parallel without conflicts.

## Standard Steps

### 1. Create the worktree

```bash
# from the main repo root (or from the fixed workspace dir, after gh repo clone)
git worktree add -b feature/<NN>-<short> ../<repo>-wt main
cd ../<repo>-wt
make install-hooks    # installs the commit-msg validator (#NN enforcement)
```

- `<NN>` = GitHub issue / board item ID (numeric)
- `<short>` = 3-5 descriptive chars (e.g., `signin`, `otsignup`, `fixnav`)
- `main` can be `master` if that's the configured main branch

### 2. Work in the worktree

- All changes, commits, tests, and pushes happen in the worktree.
- The plan, memory, and task board are NOT files in the repo — they live in the GitHub issue (body + sequential comments via `make memory-update ... COMMENT="..."`).

### 3. Sync with remote

```bash
git push -u origin feature/<proj>-<short-id>
```

### 4. Open the PR from the worktree

`make pr-create` or `gpr` (in the scaffolded repo) work normally from the worktree.

### 5. After PR merge

```bash
cd <main-repo>
git worktree remove ../<repo>-wt
git branch -d feature/<NN>-<short>
```

## Anti-patterns

- ❌ Committing directly to the main branch without a worktree.
- ❌ Leaving the worktree uncleaned after merge.
- ❌ Reusing worktrees between different features — create a new one per task.
- ❌ Creating plan/MEMORY/TODO files in the working tree — use the GitHub issue.

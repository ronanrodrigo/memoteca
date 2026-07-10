# `orchestrator.py` — the memoteca pipeline as a finite-state machine

## What this is

A single-file Python program that **drives the memoteca pipeline end-to-end** by
running `make <target>` for each phase, checking the corresponding issue
checkbox after each phase, and recording a **replayable trajectory** of every
step. It is the *code-guaranteed* counterpart to the prose contract in
[`AGENTS.md`](../../AGENTS.md) and [`.memoteca/agents/orchestrator.md`](../../AGENTS.md).

The prose contract says *"after each step, run `make memory-update ...`"*.
The FSM **enforces** it: phases run in order, each phase's `make` targets are
executed with a retry budget, the issue checkbox is checked, the human
approval gate is honoured, and the whole run is written to disk as JSON.

## Why

Today the pipeline's correctness depends on an LLM faithfully reading
`AGENTS.md`. If the LLM drops the thread halfway, only a human notices. This
script gives you, for free:

- **Guaranteed termination** — a max-step safety cap (default 50).
- **Structured failure** — a failed phase is recorded and the FSM halts in a
  `failed` state instead of silently skipping ahead.
- **Replayable trajectory** — every `make` call, exit code, stdout tail, and
  duration is written to `.memoteca/trajectories/issue-<NN>-<ts>.json`.
- **Resume** — `--resume trajectory.json` re-enters at the last incomplete
  phase, so a crashed run continues instead of restarting.
- **An eval surface** — the trajectory format is the same linear-history
  shape used by mini-SWE-agent, so it's suitable as a fine-tuning /
  benchmarking corpus.

## The FSM (authoritative phase list)

| Phase | make target(s) | Checkbox | Board Status |
|---|---|---|---|
| `intake` | (Intake skill) | Intake completed | Todo |
| `research` | `make search-projects` | Research: benchmarking completed | Research |
| `stack` | (internal) | Stack defined | Research |
| `plan_gate` | — (human approval, no commands) | — | — |
| `implement` | `make scaffold` | Code implemented | Implementation |
| `deploy_preview` | `make gh-actions-setup`, `make deploy-preview` | Deploy preview functional | Implementation |
| `ci` | `make gh-actions-setup` | CI pipeline configured | Implementation |
| `pr_create` | `make pr-create` | PR created | PR/Merge |
| `checks_green` | (poll) | All checks green | PR/Merge |
| `preview_tested` | `make test-preview` | Preview tested via HTTP | Review |
| `pr_merge` | `make pr-merge` | PR merged | PR/Merge |
| `production` | `make deploy-production` | Production deploy completed | Deploy |
| `finalize` | `make memory-finalize` | (all remaining) | Done |
| `done` | — | — | Done |
| `failed` | — | — | — |

This table is the single source of truth for "what runs when". It is derived
from `feature_request.yml` (the checkbox list) and `memory-agent.md` (the
checkbox → board Status map). **When the issue template changes, update the
`TRANSITIONS` table at the top of `orchestrator.py`.**

## Usage

```bash
# Interactive — prompts for "ok" at the plan gate (default)
make run-orchestrator ISSUE_NUMBER=12

# CI — skip the human gate
make run-orchestrator ISSUE_NUMBER=12 AUTO=1

# Dry run — print the plan and a trajectory, run nothing
make run-orchestrator ISSUE_NUMBER=12 DRY_RUN=1

# Start at a specific phase (debugging / partial cycle)
make run-orchestrator ISSUE_NUMBER=12 START_PHASE=implement

# Resume from a crashed run
make run-orchestrator RESUME=.memoteca/trajectories/issue-12-20260101T120000.json
```

Or directly:

```bash
python .memoteca/orchestrator/orchestrator.py --issue 12 --dry-run --auto
```

## Flags

| Flag | Env var | Default | Description |
|---|---|---|---|
| `--issue` | `ISSUE_NUMBER` | required | GitHub issue / board item ID (NN) |
| `--workdir` | — | `.` | Directory containing the Makefile |
| `--auto` | `AUTO=1` | off | Skip the human approval gate |
| `--dry-run` | `DRY_RUN=1` | off | Print the plan, run nothing, still write a trajectory |
| `--start-phase` | `START_PHASE` | `intake` | Phase to start at |
| `--resume` | `RESUME` | — | Trajectory JSON to resume from |
| `--max-steps` | — | 50 | Safety cap on total FSM steps |

## Trajectory format

Each run writes `.memoteca/trajectories/issue-<NN>-<timestamp>.json`:

```json
{
  "issue_number": 12,
  "branch": "feature/12-foo",
  "started_at": "2026-07-09T10:23:08Z",
  "ended_at": "2026-07-09T10:45:02Z",
  "final_state": "done",
  "workdir": "/home/ronan/Developer/memoteca-workspaces/foo",
  "steps": [
    {
      "phase": "research",
      "attempt": 1,
      "command": "make search-projects",
      "exit_code": 0,
      "stdout_tail": "...",
      "started_at": "2026-07-09T10:23:10Z",
      "duration_s": 12.4,
      "status": "ran"
    },
    ...
  ]
}
```

The trajectory is **linear history** — every step appends to the list, and
the list IS the complete record of what the FSM did. No hidden state. This
mirrors mini-SWE-agent's design and makes the format suitable as a
fine-tuning / evaluation corpus.

## Relationship to the prose contract

- The **issue is still the source of truth.** The FSM calls
  `make memory-update` after each phase to check the checkbox and mirror to
  the board — exactly as `AGENTS.md` requires. If the checkbox update fails,
  the FSM logs a warning and continues (the issue body is the source of truth;
  the board mirror is best-effort, per `memory-agent.md`).
- The **human gate is honoured.** By default, before the `implement` phase,
  the FSM prompts for `"ok"`. Pass `--auto` (or `AUTO=1`) to skip it for CI.
- **No plan/memory files in the repo.** Trajectory JSONs are gitignored
  (`.gitignore` excludes `.memoteca/trajectories/`). They are observability
  artifacts, not state. The GitHub issue + board remain the system of record.
- The **commit format** (`<type>: <desc> (#<NN>)`) is unchanged — the FSM
  uses the same `make gcp` / `make pr-create` / `make pr-merge` targets the
  prose orchestrator uses.

## When to use it

- **Unattended runs** (CI, cron) — `--auto` runs the full pipeline without
  human prompts, with retry budgets and a trajectory.
- **Debugging a stuck pipeline** — `--dry-run` shows the exact phase
  sequence and which `make` targets would run; `--start-phase` jumps to the
  phase you're investigating.
- **Evaluating model / harness changes** — collect trajectories across many
  issues, then compare final_state, step counts, and durations.
- **Resuming after a crash** — `--resume` picks up where the last run left
  off, so a 13-phase run that died at phase 9 doesn't restart from scratch.

## When NOT to use it

- **Interactive / pair-programming** — the prose orchestrator (driven by the
  LLM reading `AGENTS.md`) is better when you want to steer each phase
  manually. The FSM is for *autonomous* runs.
- **Tasks that need LLM judgement between phases** — the FSM runs `make`
  targets blindly; it doesn't read the issue, plan, or adapt. For tasks
  where the LLM should decide what to do next based on output, use the prose
  orchestrator. The FSM is a *sequencer*, not a reasoner.

## Dependencies

**None.** stdlib only (`subprocess`, `json`, `enum`, `dataclasses`,
`argparse`, `pathlib`, `datetime`, `os`, `sys`, `time`). Runs on Python 3.11+.
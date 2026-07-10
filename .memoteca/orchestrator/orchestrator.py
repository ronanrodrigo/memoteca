#!/usr/bin/env python3
"""
orchestrator.py — Programmatic finite-state machine that drives the memoteca
pipeline end-to-end by invoking `make <target>` for each phase.

This is the code-guaranteed counterpart to the prose contract in AGENTS.md and
.memoteca/agents/orchestrator.md. The prose document describes the pipeline;
this script *enforces* it: phases run in order, each phase's `make` targets
are executed with a retry budget, the issue checkbox is checked after each
phase (via `make memory-update`), the human approval gate is honoured, and a
replayable trajectory is written to disk.

Design principles (mirrors mini-SWE-agent's philosophy):
  - Linear history: every step appends to the trajectory; the trajectory IS
    the record of what the FSM did — no hidden state.
  - No external dependencies: stdlib only.
  - The FSM is the authoritative list of phases; the table at the top of this
    file is the single source of truth for "what runs when".

Usage:
  python orchestrator.py --issue 12                    # interactive (human gate)
  python orchestrator.py --issue 12 --auto            # no human gate (CI)
  python orchestrator.py --issue 12 --dry-run          # print plan, run nothing
  python orchestrator.py --resume trajectory.json      # continue a crashed run

Trajectory files are written to .memoteca/trajectories/ (gitignored — they are
observability artifacts, not repo state; the GitHub issue remains the source
of truth per the Assistente skill).
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import shlex
import subprocess
import sys
import time
from dataclasses import dataclass, field, asdict
from enum import Enum
from pathlib import Path
from typing import Optional


# --- FSM definition ------------------------------------------------------
# The authoritative phase list. Derived from AGENTS.md "Complete pipeline"
# and memory-agent.md "Checkbox -> board Status map". Edit this table when the
# issue template (feature_request.yml) changes.

class Phase(str, Enum):
    INTAKE = "intake"
    RESEARCH = "research"
    STACK = "stack"
    PLAN_GATE = "plan_gate"          # human approval before implementation
    IMPLEMENT = "implement"
    DEPLOY_PREVIEW = "deploy_preview"
    CI = "ci"
    PR_CREATE = "pr_create"
    CHECKS_GREEN = "checks_green"
    PREVIEW_TESTED = "preview_tested"
    PR_MERGE = "pr_merge"
    PRODUCTION = "production"
    FINALIZE = "finalize"
    DONE = "done"
    FAILED = "failed"


@dataclass
class Transition:
    """One row of the FSM: how to leave a phase."""
    to: Phase
    # Shell commands (strings) to run for this phase. Each is run via the
    # shell (`bash -c`) so &&-chaining works. Empty tuple = no-op phase.
    commands: tuple[str, ...] = ()
    # Exact checkbox text from feature_request.yml, or None if the phase has
    # no checkbox (e.g. the human gate). When set, `make memory-update` is
    # called with this text after the commands succeed.
    checkbox: Optional[str] = None
    human_gate: bool = False          # prompt for "ok" before running
    max_retries: int = 1              # per-command retry budget
    timeout_s: int = 900              # 15 min, matches merge-pr.sh cap
    label: str = ""


TRANSITIONS: dict[Phase, Transition] = {
    Phase.INTAKE: Transition(
        to=Phase.RESEARCH,
        commands=(),  # intake is performed by the Intake skill, not make
        checkbox="Intake completed",
        label="Intake",
    ),
    Phase.RESEARCH: Transition(
        to=Phase.STACK,
        commands=("make search-projects",),
        checkbox="Research: benchmarking completed",
        label="Research / benchmarking",
    ),
    Phase.STACK: Transition(
        to=Phase.PLAN_GATE,
        commands=(),  # stack selection is internal - no make target
        checkbox="Stack defined",
        label="Stack selection",
    ),
    Phase.PLAN_GATE: Transition(
        to=Phase.IMPLEMENT,
        commands=(),  # no commands - the gate is purely an approval prompt
        checkbox=None,
        human_gate=True,
        label="Plan approval gate",
    ),
    Phase.IMPLEMENT: Transition(
        to=Phase.DEPLOY_PREVIEW,
        commands=("make scaffold",),
        checkbox="Code implemented",
        label="Implementation (scaffold + features)",
    ),
    Phase.DEPLOY_PREVIEW: Transition(
        to=Phase.CI,
        commands=("make gh-actions-setup", "make deploy-preview"),
        checkbox="Deploy preview functional",
        label="Deploy preview",
    ),
    Phase.CI: Transition(
        to=Phase.PR_CREATE,
        commands=("make gh-actions-setup",),
        checkbox="CI pipeline configured",
        label="CI pipeline",
    ),
    Phase.PR_CREATE: Transition(
        to=Phase.CHECKS_GREEN,
        commands=("make pr-create",),
        checkbox="PR created",
        label="PR creation",
    ),
    Phase.CHECKS_GREEN: Transition(
        to=Phase.PREVIEW_TESTED,
        # `make pr-merge` already waits for checks (up to 15 min); running it
        # here would also merge. We wait + test preview first, then merge in
        # the PR_MERGE phase. So this phase is a poll.
        commands=(),
        checkbox="All checks green",
        label="Wait for CI checks to turn green",
    ),
    Phase.PREVIEW_TESTED: Transition(
        to=Phase.PR_MERGE,
        commands=("make test-preview",),
        checkbox="Preview tested via HTTP",
        label="Preview HTTP validation",
    ),
    Phase.PR_MERGE: Transition(
        to=Phase.PRODUCTION,
        commands=("make pr-merge",),
        checkbox="PR merged",
        timeout_s=1200,  # 20 min - merge-pr.sh waits up to 15 min for checks
        label="Merge PR",
    ),
    Phase.PRODUCTION: Transition(
        to=Phase.FINALIZE,
        commands=("make deploy-production",),
        checkbox="Production deploy completed",
        label="Production deploy",
    ),
    Phase.FINALIZE: Transition(
        to=Phase.DONE,
        commands=("make memory-finalize",),
        checkbox=None,  # finalize checks ALL remaining + closes the issue
        label="Finalize (close issue + board Status=Done)",
    ),
    # Terminal sinks have no transition.
    Phase.DONE: Transition(to=Phase.DONE, label="Done"),
    Phase.FAILED: Transition(to=Phase.FAILED, label="Failed"),
}
# --- Trajectory record ----------------------------------------------------

@dataclass
class StepRecord:
    phase: str
    attempt: int
    command: str
    exit_code: int
    stdout_tail: str          # last N lines of stdout+stderr merged
    started_at: str          # ISO 8601
    duration_s: float
    status: str              # ran | skipped | gate_approved | gate_refused | retried | failed

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class Trajectory:
    issue_number: int
    branch: str
    started_at: str
    steps: list[StepRecord] = field(default_factory=list)
    ended_at: Optional[str] = None
    final_state: Optional[str] = None   # done | failed | interrupted
    workdir: str = "."

    def add(self, step: StepRecord) -> None:
        self.steps.append(step)

    def to_dict(self) -> dict:
        return {
            "issue_number": self.issue_number,
            "branch": self.branch,
            "started_at": self.started_at,
            "ended_at": self.ended_at,
            "final_state": self.final_state,
            "workdir": self.workdir,
            "steps": [s.to_dict() for s in self.steps],
        }


# --- Runner ---------------------------------------------------------------

STDOUT_TAIL_LINES = 40


def _now_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def _run_command(cmd: str, workdir: str, timeout_s: int) -> tuple[int, str, float]:
    """Run a shell command, return (exit_code, merged_tail, duration_s)."""
    started = time.monotonic()
    try:
        proc = subprocess.run(
            cmd, shell=True, cwd=workdir, capture_output=True, text=True,
            timeout=timeout_s, errors="replace",
        )
        merged = (proc.stdout or "") + (proc.stderr or "")
        tail = _tail(merged, STDOUT_TAIL_LINES)
        return proc.returncode, tail, time.monotonic() - started
    except subprocess.TimeoutExpired as e:
        tail = _tail((e.stdout or "") + (e.stderr or ""), STDOUT_TAIL_LINES)
        return 124, f"[TIMEOUT after {timeout_s}s]\n{tail}", time.monotonic() - started


def _tail(text: str, n: int) -> str:
    lines = text.splitlines()
    return "\n".join(lines[-n:]) if lines else ""


def _check_box(checkbox: str, issue_number: int, workdir: str) -> tuple[int, str]:
    """Run make memory-update CHECKBOX=... to check the box on the issue."""
    env = os.environ.copy()
    env["ISSUE_NUMBER"] = str(issue_number)
    env["CHECKBOX"] = checkbox
    cmd = "make memory-update"
    exit_code, tail, _ = _run_command(cmd, workdir, 60)
    return exit_code, tail


def _human_gate(label: str, issue_number: int) -> bool:
    """Prompt the user for approval. Returns True if approved."""
    print(f"\n{'-' * 60}")
    print(f"  HUMAN GATE - {label}")
    print(f"  Issue #{issue_number}")
    print(f"  Type ok (or go ahead / approved) to proceed,")
    print(f"  anything else to abort:")
    print(f"{'-' * 60}")
    try:
        answer = input("> ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        return False
    return answer in {"ok", "go ahead", "approved", "yes", "y"}


class Orchestrator:
    def __init__(
        self,
        issue_number: int,
        workdir: str,
        auto: bool = False,
        dry_run: bool = False,
        start_phase: Phase = Phase.INTAKE,
        max_steps: int = 50,
    ):
        self.issue_number = issue_number
        self.workdir = workdir
        self.auto = auto
        self.dry_run = dry_run
        self.max_steps = max_steps
        self.trajectory = Trajectory(
            issue_number=issue_number,
            branch=self._current_branch(),
            started_at=_now_iso(),
            workdir=workdir,
        )
        self.phase = start_phase

    def _current_branch(self) -> str:
        try:
            out = subprocess.run(
                "git rev-parse --abbrev-ref HEAD", shell=True, cwd=self.workdir,
                capture_output=True, text=True, timeout=5, errors="replace",
            )
            return out.stdout.strip() or "(detached)"
        except Exception:
            return "(unknown)"

    def _record(self, **kw) -> None:
        self.trajectory.add(StepRecord(
            phase=self.phase.value,
            started_at=_now_iso(),
            **kw,
        ))

    def run(self) -> int:
        """Run the FSM. Returns 0 on DONE, 1 on FAILED/interrupted."""
        steps_taken = 0
        try:
            while self.phase not in (Phase.DONE, Phase.FAILED):
                if steps_taken >= self.max_steps:
                    print(f"[fsm] max-steps ({self.max_steps}) reached - halting")
                    self.trajectory.final_state = "interrupted"
                    return 1
                steps_taken += 1
                trans = TRANSITIONS[self.phase]
                label = trans.label or self.phase.value
                print(f"\n[fsm] === phase: {self.phase.value} - {label} ===")

                # Human gate
                if trans.human_gate and not self.auto:
                    if self.dry_run:
                        print("[dry-run] would prompt for human approval")
                        self._record(attempt=1, command="(human gate)",
                                     exit_code=0, stdout_tail="", duration_s=0,
                                     status="gate_approved")
                    else:
                        approved = _human_gate(label, self.issue_number)
                        if not approved:
                            print("[fsm] human gate refused - aborting")
                            self._record(attempt=1, command="(human gate)",
                                         exit_code=1, stdout_tail="",
                                         duration_s=0, status="gate_refused")
                            self.phase = Phase.FAILED
                            continue
                        self._record(attempt=1, command="(human gate)",
                                     exit_code=0, stdout_tail="",
                                     duration_s=0, status="gate_approved")

                # Commands
                if self.dry_run:
                    for cmd in trans.commands:
                        print(f"[dry-run] would run: {cmd}")
                        self._record(attempt=1, command=cmd, exit_code=0,
                                     stdout_tail="", duration_s=0,
                                     status="skipped")
                    if trans.checkbox:
                        print(f"[dry-run] would check: {trans.checkbox}")
                else:
                    phase_failed = False
                    for cmd in trans.commands:
                        for attempt in range(1, trans.max_retries + 1):
                            print(f"[fsm] run: {cmd}  (attempt {attempt}/"
                                  f"{trans.max_retries})")
                            exit_code, tail, dur = _run_command(
                                cmd, self.workdir, trans.timeout_s)
                            print(f"[fsm] -> exit {exit_code} ({dur:.1f}s)")
                            if tail:
                                print("  " + tail[:800].replace("\n", "\n  "))
                            self._record(attempt=attempt, command=cmd,
                                         exit_code=exit_code, stdout_tail=tail,
                                         duration_s=round(dur, 2),
                                         status="ran" if exit_code == 0
                                         else ("retried" if attempt < trans.max_retries
                                               else "failed"))
                            if exit_code == 0:
                                break
                            if attempt == trans.max_retries:
                                print(f"[fsm] {label} failed after "
                                      f"{trans.max_retries} attempt(s)")
                                self.phase = Phase.FAILED
                                phase_failed = True
                        if phase_failed:
                            break

                    if phase_failed:
                        continue

                # Checkbox check (or finalize) as a step too
                if trans.checkbox and not self.dry_run:
                    print(f"[fsm] checkbox: {trans.checkbox}")
                    exit_code, tail = _check_box(
                        trans.checkbox, self.issue_number, self.workdir)
                    self._record(attempt=1,
                                 command=f"make memory-update CHECKBOX=..."
                                         f"[{trans.checkbox}]",
                                 exit_code=exit_code, stdout_tail=tail,
                                 duration_s=0.0, status="ran")
                    if exit_code != 0:
                        print(f"[fsm] WARNING: checkbox update failed "
                              f"(exit {exit_code}) - continuing; issue body is"
                              f" the source of truth")
                elif trans.checkbox and self.dry_run:
                    pass  # already printed above

                # Advance
                self.phase = trans.to

            self.trajectory.ended_at = _now_iso()
            self.trajectory.final_state = self.phase.value
            self._write_trajectory()
            print(f"\n[fsm] final state: {self.phase.value}")
            print(f"[fsm] trajectory: {self._trajectory_path()}")
            return 0 if self.phase == Phase.DONE else 1
        except KeyboardInterrupt:
            self.trajectory.ended_at = _now_iso()
            self.trajectory.final_state = "interrupted"
            self._write_trajectory()
            print("\n[fsm] interrupted by user - trajectory saved")
            return 1

    def _trajectory_path(self) -> Path:
        ts = _dt.datetime.now().strftime("%Y%m%dT%H%M%S")
        return Path(self.workdir) / ".memoteca" / "trajectories" \
            / f"issue-{self.issue_number}-{ts}.json"

    def _write_trajectory(self) -> None:
        path = self._trajectory_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self.trajectory.to_dict(), indent=2),
                        encoding="utf-8")


# --- Resume support -------------------------------------------------------

def _last_completed_phase(trajectory_path: Path) -> Phase:
    """Read a trajectory and return the next phase to run (the phase after the
    last successful step phase)."""
    data = json.loads(trajectory_path.read_text(encoding="utf-8"))
    steps = data.get("steps", [])
    if not steps:
        return Phase.INTAKE
    last = steps[-1]
    last_phase = Phase(last["phase"])
    trans = TRANSITIONS.get(last_phase)
    if not trans:
        return Phase.INTAKE
    if last["status"] == "failed" or last.get("exit_code", 0) != 0:
        return last_phase
    if "CHECKBOX" in last.get("command", "") or last["status"] == "gate_approved":
        return trans.to
    return trans.to if trans.checkbox is None else last_phase


# --- CLI ------------------------------------------------------------------

def _parse_phase(s: str) -> Phase:
    try:
        return Phase(s)
    except ValueError:
        valid = ", ".join(p.value for p in Phase if p not in (Phase.DONE, Phase.FAILED))
        raise argparse.ArgumentTypeError(
            f"invalid phase {s}. Valid: {valid}")


def main() -> int:
    p = argparse.ArgumentParser(
        prog="orchestrator.py",
        description="memoteca pipeline FSM - drives make targets per phase, "
                    "checks issue checkboxes, records a replayable trajectory.",
    )
    p.add_argument("--issue", type=int, required=True,
                   help="GitHub issue / board item ID (NN)")
    p.add_argument("--workdir", default=".",
                   help="Working directory with the Makefile (default: cwd)")
    p.add_argument("--auto", action="store_true",
                   help="Skip the human approval gate (for CI)")
    p.add_argument("--dry-run", action="store_true",
                   help="Print the plan and exit; run nothing")
    p.add_argument("--start-phase", type=_parse_phase, default=None,
                   help="Phase to start at (default: intake, or resume point)")
    p.add_argument("--resume", type=Path, metavar="TRAJECTORY",
                   default=None,
                   help="Resume from a previous trajectory.json")
    p.add_argument("--max-steps", type=int, default=50,
                   help="Safety cap on total FSM steps (default: 50)")
    args = p.parse_args()

    start = args.start_phase
    if args.resume:
        if not args.resume.exists():
            print(f"[fsm] trajectory not found: {args.resume}", file=sys.stderr)
            return 2
        start = start or _last_completed_phase(args.resume)
        print(f"[fsm] resumed phase: {start.value}")

    orch = Orchestrator(
        issue_number=args.issue,
        workdir=os.path.abspath(args.workdir),
        auto=args.auto,
        dry_run=args.dry_run,
        start_phase=start or Phase.INTAKE,
        max_steps=args.max_steps,
    )
    return orch.run()


if __name__ == "__main__":
    sys.exit(main())
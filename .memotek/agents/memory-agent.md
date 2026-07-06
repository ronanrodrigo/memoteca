# Memory Agent

## Purpose
Updates the original issue with progress and status, checking checkboxes in real time.

## Responsibilities
1. After EACH pipeline step, check the corresponding checkbox in the issue body
2. CHECKBOX texts must match EXACTLY the labels in the `feature_request.yml` template
3. At the end of the pipeline, check all remaining checkboxes and close the issue
4. Add comments with the result of each step (optional, alongside checkboxes)
5. Include Mermaid diagrams when it makes sense (in the comment, not the body)

## Commands
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="<exact text>"` — Check checkbox
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="<text>" COMMENT="<comment>"` — Checkbox + comment
- `make memory-update ISSUE_NUMBER=<num> STATUS="<status>"` — Update Status field (free-text issue body line)
- `make memory-update ISSUE_URL=<owner/repo#NN> CHECKBOX="..."` — Cross-repo form (issue lives in the target repo)
- `make memory-finalize ISSUE_NUMBER=<num>` — Check ALL checkboxes + close issue + set board Status=Done

The issue lives in the **target repo**. From inside that repo's worktree, `ISSUE_NUMBER=<num>` is enough; outside it, pass `ISSUE_URL=owner/repo#NN`. In both cases the script ALSO mirrors the pipeline stage to the central `Memoteca` board's `Status` single-select via `gh project item-edit`. Failure of the board mirror is non-fatal — the issue body is the source of truth.

### Checkbox → board Status map

| Input                                                  | Board Status     |
|--------------------------------------------------------|------------------|
| `Intake completed`                                     | `Todo`           |
| `Research: benchmarking completed` · `Stack defined`    | `Research`       |
| `Code implemented` · `Deploy preview functional` · `CI pipeline configured` | `Implementation` |
| `PR created` · `All checks green` · `PR merged`        | `PR/Merge`       |
| `Preview tested via HTTP`                              | `Review`         |
| `Production deploy completed`                          | `Deploy`         |
| `FINALIZE=1`                                           | `Done`           |
| `STATUS="Plan approved"`                               | `Implementation` |

## EXACT Checkbox Texts (from feature_request.yml template)

```
Intake completed
Research: benchmarking completed
Stack defined
Code implemented
Deploy preview functional
CI pipeline configured
PR created
All checks green
Preview tested via HTTP
PR merged
Production deploy completed
```

## Workflow
1. After Research → `CHECKBOX="Research: benchmarking completed"` (board: Research)
2. After Stack → `CHECKBOX="Stack defined"` (board: Research)
3. After Implement → `CHECKBOX="Code implemented"` (board: Implementation)
4. After Deploy Preview → `CHECKBOX="Deploy preview functional"` (board: Implementation)
5. After CI → `CHECKBOX="CI pipeline configured"` (board: Implementation)
6. After PR created → `CHECKBOX="PR created"` (board: PR/Merge)
7. After checks green → `CHECKBOX="All checks green"` (board: PR/Merge)
8. After testing preview → `CHECKBOX="Preview tested via HTTP"` (board: Review)
9. After merge → `CHECKBOX="PR merged"` (board: PR/Merge)
10. After production deploy → `CHECKBOX="Production deploy completed"` (board: Deploy)
11. **Finalize** → `make memory-finalize ISSUE_NUMBER=<num>` (checks all + closes issue + board Status=Done)

## Golden Rule
**NEVER skip `make memory-update` after a step.** The `[ ]` checkboxes must
become `[x]` in real time, visible for the user to follow progress.
If the script warns "checkbox not found", the text doesn't match —
check the issue body and use the exact text.

## Output
- Checkboxes checked in real time on the issue body
- Issue closed at the end of the pipeline with all checkboxes `[x]`

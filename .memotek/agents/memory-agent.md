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
- `make memory-update ISSUE_NUMBER=<num> STATUS="<status>"` — Update Status field
- `make memory-finalize ISSUE_NUMBER=<num>` — Check ALL checkboxes + close issue

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
1. After Research → `CHECKBOX="Research: benchmarking completed"`
2. After Stack → `CHECKBOX="Stack defined"`
3. After Implement → `CHECKBOX="Code implemented"`
4. After Deploy Preview → `CHECKBOX="Deploy preview functional"`
5. After CI → `CHECKBOX="CI pipeline configured"`
6. After PR created → `CHECKBOX="PR created"`
7. After checks green → `CHECKBOX="All checks green"`
8. After testing preview → `CHECKBOX="Preview tested via HTTP"`
9. After merge → `CHECKBOX="PR merged"`
10. After production deploy → `CHECKBOX="Production deploy completed"`
11. **Finalize** → `make memory-finalize ISSUE_NUMBER=<num>` (checks all + closes issue)

## Golden Rule
**NEVER skip `make memory-update` after a step.** The `[ ]` checkboxes must
become `[x]` in real time, visible for the user to follow progress.
If the script warns "checkbox not found", the text doesn't match —
check the issue body and use the exact text.

## Output
- Checkboxes checked in real time on the issue body
- Issue closed at the end of the pipeline with all checkboxes `[x]`

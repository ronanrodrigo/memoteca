# Template: Initial Project Creation

## Checklist (issue body)
- [ ] Intake completed
- [ ] Research: benchmarking completed
- [ ] Stack defined
- [ ] Code implemented
- [ ] Deploy preview functional
- [ ] CI pipeline configured
- [ ] PR created
- [ ] All checks green
- [ ] Preview tested via HTTP
- [ ] PR merged
- [ ] Production deploy completed

## Board Status mirror
`Todo` → `Research` → `Implementation` → `Review` → `PR/Merge` → `Deploy` → `Done`

## Required Information
- Project name
- Description of what's needed
- Project type (dashboard, CRUD, landing page, etc.)
- Persistence required? (yes/no)
- References or inspirations

## Complete Flow
1. User pre-creates the project-repo via GitHub "Use this template" + clones it locally + `make project-create && make project-link-repo` (once)
2. Intake — Collect user information + create issue in the project-repo + `make project-add-issue ISSUE_URL=...`
3. Research — Search for similar projects on GitHub → `make search-projects`
4. Stack Selector — Define technology stack
5. Implementer — Create complete Next.js project, working in a worktree `feature/<NN>-<short>`, commits via `make gcp` (auto-injects `(#NN)`)
6. Deploy Agent — Configure preview on Vercel → `make deploy-preview`
7. CI Agent — Configure test pipeline → `make gh-actions-setup`
8. PR Validator — Monitor and validate PR → `make pr-merge`
9. Production deploy → `make deploy-production`
10. Memory Agent — `make memory-update` at each step (checkbox + board Status); `make memory-finalize` at the end

# Skill: Intake

## Purpose
Collects user input and creates a GitHub issue (in the target repo) with the appropriate template, then **adds the issue to the central "Memoteca" board** so the Orchestrator can discover it.

## Trigger
- User provides a manual prompt describing what they need
- `make tasks-listen` discovers items `Status=Todo` on the central board (the board is the queue)

## Workflow

### 1. Identify Input Type
Ask the user:
- **Creation**: Create something from scratch — requires the user to have pre-created the project-repo via GitHub "Use this template" (otherwise `<NN>` has nowhere to live, since the issue must live in its target repo)
- **Addition**: Add a feature to something existing
- **Bug Fix**: Fix something that isn't working

### 2. Collect Information

#### For Creation:
- Project name
- Description of what's needed
- Project type (dashboard, CRUD, landing page, etc.)
- Persistence required? (yes/no)
- References or inspirations

#### For Addition:
- What to add
- Where to add it (which files/components)
- Dependencies

#### For Bug Fix:
- What's wrong
- Steps to reproduce
- Expected vs actual behavior

### 3. Create Issue
Use the `feature_request.yml` template with the collected answers, filed in the **target repo** (the project-repo for Project Creation, or the relevant repo for Addition/Bug Fix).

### 4. Add to the central board
After filing the issue, add it to the central board so the Orchestrator picks it up:

```
make project-add-issue ISSUE_URL=https://github.com/<owner>/<repo>/issues/<NN>
```

The script sets the board's `Status=Todo` and parses the `Task Type` single-select from the issue body. (Optional: configure GitHub's Projects V2 **Auto-add** workflow on the board via the web UI — filter label = `memoteca` — to skip this manual step.)

### 5. Start Pipeline
Once the issue is on the board with `Status=Todo`, `make tasks-listen` will surface it as the next actionable item (oldest first) for the Orchestrator.

## Commands
- `make project-add-issue ISSUE_URL=<url>` — Add the issue to the board (sets Status=Todo)
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Intake completed"` — Finalize intake

## Output
- Issue created on GitHub in the target repo with the `memoteca` label
- Issue added to the central "Memoteca" board with `Status=Todo`
- Pipeline started by the Orchestrator via `make tasks-listen`

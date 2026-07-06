# Skill: Intake

## Purpose
Collects user input and creates a GitHub issue with the appropriate template.

## Trigger
- User provides a manual prompt describing what they need
- schedule_job detects a new open issue via `make listen-issues`

## Workflow

### 1. Identify Input Type
Ask the user:
- **Creation**: Create something from scratch
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
Use the `feature_request.yml` template with the collected answers.

### 4. Start Pipeline
After creating the issue, the Orchestrator takes over.

## Commands
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Intake completed"` — Finalize intake

## Output
- Issue created on GitHub with filled template
- `memotek` label applied
- Pipeline started by the Orchestrator

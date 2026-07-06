# Memotek Workflow

## Main Flow

### 1. User Input
The user can provide input in two ways:
- **Manual prompt** — User describes what they need
- **/issues** — `make tasks-listen` queries the central Memoteca board for items with `Status=Todo`

### 2. Intake
The Intake skill collects information, creates a GitHub issue **in the target repo**, and adds it to the board:
- Asks task type (creation, addition, bug fix)
- Collects specific details
- Creates issue with `feature_request.yml` template in the target repo
- Runs `make project-add-issue ISSUE_URL=...` to add it to the central board with `Status=Todo`

### 3. Research
The Researcher searches for similar projects on GitHub:
- Uses `github_search_repositories`
- Analyzes top 3 by stars
- Documents references in the issue

### 4. Stack Selection
The Stack Selector defines the stack:
- Analyzes research results
- Selects from the predefined list
- Justifies choices

### 5. Implementation
The Implementer creates the project (working inside a worktree `feature/<NN>-<short>`):
- Runs `make scaffold`
- Installs dependencies
- Implements features
- Commits via `make gcp` (auto-injects `(#NN)` from the branch name)

### 6. Deploy
The Deploy Agent configures deployment:
- Configures GitHub Actions
- Runs `make deploy-preview`
- Documents URL in the issue

### 7. CI
The CI Agent configures the pipeline:
- Creates test workflows
- Configures lint, typecheck, test, build

### 8. Validation
The PR Validator monitors and validates:
- Checks CI checks
- Tests preview URL
- Runs merge when valid
- Runs production deploy after merge

### 9. Memory
The Memory Agent updates the issue AND the board:
- Checks the checkbox in the issue body
- Adds a sequential comment on the issue
- Mirrors `Status` to the central board item via `gh project item-edit`
- Finalize: closes the issue and sets board `Status=Done`

## Manual Execution

### Check the board
The user types `/issues` in opencode; the entry point runs:
```
make tasks-listen
```

### PR Validator
The PR Validator is automatically triggered when a PR is created via `make pr-create`.

## Available Commands

| Command | Description |
|---------|-----------|
| `make project-create` | Create the private "Memoteca" board + Status/Task Type fields (once) |
| `make project-link-repo` | Link a repo to the board (once per repo) |
| `make project-add-issue` | Add an issue to the board (sets Status=Todo) |
| `make tasks-listen` | Query the board for items Status=Todo (oldest first) — entry point |
| `make process-issue` | Fetch an issue (cross-repo) + print next steps |
| `make memory-update` | Check checkbox + post comment + mirror Status to the board |
| `make memory-finalize` | Check all remaining + close issue + set board Status=Done |
| `make search-projects` | Search projects |
| `make gh-actions-setup` | Configure CI/CD |
| `make test` | Run tests |
| `make test-preview` | Test preview |
| `make pr-create` | Create PR |
| `make pr-merge` | Merge PR |
| `make deploy-preview` | Deploy preview |
| `make deploy-production` | Deploy production |
| `make scaffold` | Create project |
| `make install-hooks` | Install the commit-msg hook enforcing `(#NN)` |

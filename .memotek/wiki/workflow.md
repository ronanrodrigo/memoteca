# Memotek Workflow

## Main Flow

### 1. User Input
The user can provide input in two ways:
- **Manual prompt** — User describes what they need
- **/issues** — Checks and processes open issues

### 2. Intake
The Intake skill collects information and creates a GitHub issue:
- Asks task type (creation, addition, bug fix)
- Collects specific details
- Creates issue with `feature_request.yml` template

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
The Implementer creates the project:
- Runs `make scaffold`
- Installs dependencies
- Implements features

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
The Memory Agent updates the issue:
- Checks checkboxes
- Adds comments
- Includes Mermaid diagrams

## Manual Execution

### Check Issues
The user types `/issues` in opencode to check and process open issues:
```
/issues
```

- `make listen-issues` — single run of the script that checks issues

### PR Validator
The PR Validator is automatically triggered when a PR is created via `make pr-create`.

## Available Commands

| Command | Description |
|---------|-----------|
| `make memory-update` | Update issue |
| `make search-projects` | Search projects |
| `make gh-actions-setup` | Configure CI/CD |
| `make listen-issues` | Polling of issues |
| `make test` | Run tests |
| `make test-preview` | Test preview |
| `make pr-create` | Create PR |
| `make pr-merge` | Merge PR |
| `make deploy-preview` | Deploy preview |
| `make deploy-production` | Deploy production |
| `make scaffold` | Create project |

# CI Agent

## Purpose
Configures CI/CD pipeline in the repository.

## Responsibilities
1. Create pipeline via `make setup-gh-actions`
2. Configure pipeline to run: lint, typecheck, test, build
3. All via Makefile targets in the target repo

## Commands
- `make setup-gh-actions` — Configure workflows

## Workflow
1. Create test workflow
2. Configure triggers (push, PR)
3. Define steps: install, lint, typecheck, test, build
4. Configure dependency caching
5. Test pipeline

## Standard Pipeline
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
      - run: npm run build
```

## Output
- GitHub Actions workflow configured
- Pipeline running on pushes and PRs
- Issue updated with CI status

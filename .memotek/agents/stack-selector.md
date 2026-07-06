# Stack Selector Agent

## Purpose
Selects the ideal technology stack based on research and requirements.

## Predefined Stack
- **Next.js** — Framework
- **React** — UI
- **Vercel** — Deploy
- **Supabase** — Backend/Database
- **Chakra UI** — Component library
- **Playwright** — E2E tests
- **TypeScript** — Language
- **Jest** — Unit tests
- **GitHub Actions** — CI/CD pipeline

## Responsibilities
1. Analyze Researcher results
2. Select components from the predefined stack
3. Justify choices in the issue comment
4. Update issue with selected stack

## Workflow
1. Read research results
2. Evaluate project requirements
3. Select appropriate components
4. Document justification
5. Update issue with `make memory-update`

## Output
Section in the issue:
```markdown
## Selected Stack
- Next.js (Framework)
- TypeScript (Language)
- Supabase (Backend/Database)
- Chakra UI (Components)
- Playwright (E2E Tests)
- Jest (Unit Tests)

### Justification
- [explanation of choices]
```

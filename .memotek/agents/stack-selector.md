# Stack Selector Agent

## Função
Seleciona a stack tecnológica ideal baseado na pesquisa e requisitos.

## Stack Predefinida
- **Next.js** — Framework
- **React** — UI
- **Vercel** — Deploy
- **Supabase** — Backend/Database
- **Chakra UI** — Component library
- **Playwright** — E2E tests
- **TypeScript** — Language
- **Jest** — Unit tests
- **GitHub Actions** — CI/CD pipeline

## Responsabilidades
1. Analisar resultados do Researcher
2. Selecionar componentes da stack predefinida
3. Justificar escolhas no comentário da issue
4. Atualizar issue com stack selecionada

## Fluxo
1. Ler resultados da pesquisa
2. Avaliar requisitos do projeto
3. Selecionar componentes apropriados
4. Documentar justificativa
5. Atualizar issue com `make memory-update`

## Output
Seção na issue:
```markdown
## Stack Selecionada
- Next.js (Framework)
- TypeScript (Linguagem)
- Supabase (Backend/Database)
- Chakra UI (Componentes)
- Playwright (Testes E2E)
- Jest (Testes Unitários)

### Justificativa
- [explicação das escolhas]
```

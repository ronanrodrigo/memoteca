# AGENTS.md — Regras para Agentes

## Regras Gerais

1. **NUNCA executar comandos diretamente** — SEMPRE via `make <target>`
   - Proibido: `gh`, `curl`, `jq`, `yq`, `npm run`, `jest`, etc. diretamente
   - Exceção: comandos internos do agente (ler arquivos, escrever código)
2. **Repositório obrigatório** — O usuário DEVE ter um repo no GitHub (criado via "Use this template")
3. **Precedência** — O que está no AGENTS.md tem precedência sobre definições de agentes/skills

## Estrutura do Repo-Projeto

Ao clonar via "Use this template", o repo-projeto já contém tudo necessário. Após `make scaffold PROJECT_NAME="."`, a estrutura é:

```
repo-projeto/
├── src/                    ← código do projeto
├── package.json
├── Makefile
├── jest.config.js
├── jest.setup.ts
├── playwright.config.ts
├── .gitignore
├── .env-example
├── AGENTS.md
├── .memotek/               ← agentes e scripts
│   ├── agents/
│   ├── skills/
│   ├── scripts/
│   ├── templates/
│   └── ...
└── .github/workflows/      ← CI/CD
```

## Pipeline de Implementação

```
USUÁRIO (input)
├── Prompt manual → Intake faz perguntas → Cria issue no GitHub
└── /listen-issues (cron local) → Polling de issues abertas
         │
         ▼
    ┌─────────────────────────────────────┐
    │  ISSUE CRIADA (feature_request.yml) │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │         ORCHESTRATOR (agent)        │
    └──┬────┬────┬────┬────┬────┬────────┘
       │    │    │    │    │    │
       ▼    ▼    ▼    ▼    ▼    ▼
     Res  Stk  Imp  Dep  CI  PR
     ea   ac   le   lo   id  val
     rch  Sel  ment mnt      id

    Todos executam via: make <target>
```

## Etapas do Pipeline

| # | Etapa | Agente | Ação | Make Target |
|---|-------|--------|------|-------------|
| 1 | Input | - | Usuário clona template via "Use this template" | - |
| 2 | Intake | Intake (skill) | Cria issue GitHub com template de perguntas | `make memory-update` |
| 2.1 | Polling | - | Cron poll issues abertas | `make listen-issues` |
| 3 | Research | Researcher | Busca projetos open source no GitHub | `make search-projects` |
| 3.1 | Benchmarking | Researcher | Analisa top 3 por stars | (interno) |
| 3.2 | Fallback | Researcher | Se nada encontrado, pergunta ao usuário | (interação) |
| 4 | Stack | Stack Selector | Seleciona da lista predefinida | (interno) |
| 5 | Implement | Implementer | Configura projeto Next.js via scaffold | `make scaffold PROJECT_NAME="."` |
| 6 | Deploy | Deploy Agent | Configura preview na Vercel | `make gh-actions-setup` + `make deploy-preview` |
| 7 | CI | CI Agent | Configura pipeline de testes | `make gh-actions-setup` |
| 8 | Validate | PR Validator | Monitora checks, testa preview URL | `make test-preview` |
| 8.1 | Merge | PR Validator | Merge PR quando tudo verde | `make pr-merge` |
| 8.2 | Prod | PR Validator | Deploy produção | `make deploy-production` |
| 9 | Memory | Memory Agent | Atualiza issue com progresso + Mermaid | `make memory-update` |

## Targets do Makefile

### Pipeline (memotek)
| Target | Descrição |
|--------|-----------|
| `make scaffold` | Cria/configura projeto Next.js |
| `make gh-actions-setup` | Copia workflows para .github/workflows/ |
| `make memory-update` | Atualiza issue com progresso |
| `make search-projects` | Busca projetos similares no GitHub |
| `make listen-issues` | Polling de issues abertas |
| `make test-preview` | Testa preview URL via HTTP |
| `make pr-create` | Cria Pull Request |
| `make pr-merge` | Merge Pull Request |
| `make deploy-preview` | Deploy preview na Vercel |
| `make deploy-production` | Deploy produção na Vercel |

### CI/CD (repo-projeto)
| Target | Descrição |
|--------|-----------|
| `make install` | Instala dependências (npm ci ou npm install) |
| `make lint` | Roda linter |
| `make typecheck` | Verifica tipos (tsc --noEmit) |
| `make build` | Builda o projeto |
| `make test` | Roda testes unitários (Jest) |
| `make install-playwright` | Instala Playwright + Chromium |
| `make test-e2e` | Roda testes E2E (Playwright) |

## Três Tipos de Input

### 1. Criação Inicial de Projeto
Exemplo: "Criar um sistema para cadastro de componentes químicos"
- Issue com campos: tipo de projeto, persistência, stack desejada, referências
- Aciona pipeline completo: intake → research → stack → implement → deploy → CI

### 2. Adição ao Sistema
Exemplo: "Adicionar campo de cor para cada componente químico no formulário"
- Issue com campos: afeta quais arquivos/components, dependências
- Aciona ciclo parcial: intake → implement → deploy preview → test → merge

### 3. Correção de Bug
Exemplo: "O campo abreviação não está salvando letras maiúsculas"
- Issue com campos: passos para reproduzir, comportamento esperado vs atual
- Aciona ciclo de fix: intake → diagnose → fix → test → merge

## Stack Predefinida

- **Next.js** — Framework
- **React** — UI
- **Vercel** — Deploy
- **Supabase** — Backend/Database (opcional via `SUPABASE=1`)
- **Playwright** — E2E tests
- **TypeScript** — Language
- **Jest** — Unit tests
- **GitHub Actions** — CI/CD pipeline

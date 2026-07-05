# AGENTS.md — Regras para Agentes

## Regras Gerais

1. **NUNCA executar comandos diretamente** — SEMPRE via `make <target>`
   - Proibido: `gh`, `curl`, `jq`, `yq`, `npm run`, `jest`, etc. diretamente
   - Exceção: comandos internos do agente (ler arquivos, escrever código)
2. **Repositório obrigatório** — O usuário DEVE ter um repo no GitHub (criado via "Use this template")
3. **Projetos dentro do memotek** — NÃO criar projetos dentro do memotek que não sejam o próprio memotek
4. **Precedência** — O que está no AGENTS.md tem precedência sobre definições de agentes/skills
5. **Versionamento** — Cada implementação é versionada com código do modelo: `memotek-<modelo>`

## Diretório de Implementação

Cada versão (modelo diferente) cria seu próprio diretório dentro de `~/Developer/memotek/`.

Ex: `~/Developer/memotek/memotek-gpt-4o/`, `~/Developer/memotek/memotek-claude-sonnet-4/`

## Pipeline de Implementação

```
USUÁRIO (input)
├── Prompt manual → Intake faz perguntas → Cria issue no GitHub
└── /listen-issues (cron local) → Polling de issues abertas
         │
         ▼
    ┌─────────────────────────────────────┐
    │  ISSUE CRIADA (feature_request.yml) │
    │  - Descrição do que precisa         │
    │  - Checklist de etapas              │
    │  - Campos de stack/referências      │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │         ORCHESTRATOR (agent)        │
    │  Coordena pipeline completo         │
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
| 5 | Implement | Implementer | Gera projeto Next.js completo via create-next-app | `make scaffold` |
| 6 | Deploy | Deploy Agent | Configura preview na Vercel | `make setup-gh-actions` + `make deploy-preview` |
| 7 | CI | CI Agent | Configura pipeline de testes | `make setup-gh-actions` |
| 8 | Validate | PR Validator | Monitora checks, testa preview URL | `make test-preview` |
| 8.1 | Merge | PR Validator | Merge PR quando tudo verde | `make pr-merge` |
| 8.2 | Prod | PR Validator | Deploy produção | `make deploy-production` |
| 9 | Memory | Memory Agent | Atualiza issue com progresso + Mermaid | `make memory-update` |

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
- **Supabase** — Backend/Database
- **Chakra UI** — Component library
- **Playwright** — E2E tests
- **TypeScript** — Language
- **Jest** — Unit tests
- **GitHub Actions** — CI/CD pipeline

# Arquitetura do Memotek

## Visão Geral

O Memotek é um sistema de agentes autônomos para desenvolvimento de software, construído como um template repository.

## Componentes

### Agentes
Cada agente é um subagente especializado que executa uma etapa específica do pipeline:

1. **Orchestrator** — Coordena todo o pipeline
2. **Researcher** — Busca projetos para benchmarking
3. **Stack Selector** — Define stack tecnológica
4. **Implementer** — Gera e implementa código
5. **Deploy Agent** — Configura deploy na Vercel
6. **CI Agent** — Configura CI/CD
7. **PR Validator** — Monitora e valida PRs
8. **Memory Agent** — Atualiza issue com progresso

### Skills
Skills são conjuntos de instruções para tarefas específicas:
- **Intake** — Coleta input do usuário e cria issue

### Scripts
Scripts shell que encapsulam comandos complexos:
- `update-memory.sh` — Atualizar issue
- `search-projects.sh` — Buscar projetos
- `setup-gh-actions.sh` — Configurar CI/CD
- `listen-issues.sh` — Polling de issues
- `run-tests.sh` — Rodar testes
- `validate-preview.sh` — Testar preview
- `create-pr.sh` — Criar PR
- `merge-pr.sh` — Merge PR
- `deploy-preview.sh` — Deploy preview
- `deploy-production.sh` — Deploy produção
- `scaffold-project.sh` — Criar projeto

## Fluxo de Dados

```
Usuário → Intake → Issue GitHub → Orchestrator → Pipeline → Deploy → Issue Atualizada
```

## Estrutura de Diretórios

```
memotek/
├── AGENTS.md              # Regras para agentes
├── Makefile               # Targets para scripts
├── opencode.json          # Configuração do opencode
├── .env-example           # Variáveis de ambiente
├── .github/
│   └── ISSUE_TEMPLATE/
│       └── feature_request.yml
├── .memotek/
│   ├── agents/            # Definições dos agentes
│   ├── skills/            # Skills disponíveis
│   ├── scripts/           # Scripts shell
│   ├── templates/         # Templates GitHub Actions
│   ├── tasks/             # Templates de tasks
│   ├── rules/             # Regras do projeto
│   └── wiki/              # Documentação
└── .opencode/             # Configuração padrão
```

## Decisões de Design

1. **Issue como memória** — A issue criada pelo intake é a mesma que serve de memória
2. **Scripts via Make** — Todos os comandos são executados via `make <target>`
3. **Stack predefinida** — Next.js + React + Vercel + Supabase + Chakra UI
4. **Templates de issue** — Um único template para 3 tipos de task
5. **Cron jobs locais** — Polling e validação via cron local

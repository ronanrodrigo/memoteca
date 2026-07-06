# Regras do Projeto

## Regras Gerais

1. **NUNCA executar comandos diretamente** — SEMPRE via `make <target>`
   - Proibido: `gh`, `curl`, `jq`, `yq`, `npm run`, `jest`, etc. diretamente
   - Exceção: comandos internos do agente (ler arquivos, escrever código)

2. **Repositório obrigatório** — O usuário DEVE ter um repo no GitHub (criado via "Use this template")

3. **Projetos dentro do memotek** — NÃO criar projetos dentro do memotek que não sejam o próprio memotek

4. **Precedência** — O que está no AGENTS.md tem precedência sobre definições de agentes/skills, **exceto nos temas cobertos pela Skill Assistente** (`.memotek/skills/assistente/SKILL.md`), que prevalecem. Ver `.memotek/rules/assistente-precedence.md` para a hierarquia completa.

5. **Versionamento** — Cada implementação é versionada com código do modelo: `memotek-<modelo>`

6. **Skill Assistente ativa** — Mermaid nativo do GitHub, issue do GitHub como fonte da verdade (sem arquivos de plano/memória no repo), worktree por feature, atalhos `gcp`/`gpr` e Loop de Trabalho Assistente são OBRIGATÓRIOS. Primeira resposta em conversa começa com 💭.

7. **Memória = issue do GitHub** — NUNCA manter arquivos de plano/memória/TODO commitados ou ignorados no repositório. Todo o contexto, plano, decisões e estado vivem como comentários sequenciais na própria issue do GitHub.

## Convenções de Código

- Usar TypeScript para todos os projetos
- Seguir padrões Next.js App Router
- Usar Chakra UI para componentes
- Implementar testes para features principais
- Documentar APIs e componentes

## Convenções da Skill Assistente (prevalecem nestes temas)

- **Mermaid**: nativo do GitHub (bloco ```mermaid) — NÃO usar link externo para viewer; o GitHub renderiza mermaid nativamente em issues, PRs e comentários.
- **Memória/Plano**: vivem SEMPRE na issue do GitHub (corpo + comentários), via `make memory-update ISSUE_NUMBER=<num> CHECKBOX="..." COMMENT="..."`. NUNCA criar `docs/agent-plans/<proj>/MEMORY.md`, `TODO.md`, `plan-<proj>.md` ou equivalentes no repo.
- **Gate humano**: antes de implementar, postar o plano como comentário na issue e aguardar "ok". Quando o "ok" for dado, executar `make memory-update ISSUE_NUMBER=<num> STATUS="Plano aprovado" COMMENT="Plano aprovado — iniciando implementação."`.
- **Worktree**: cada feature em `git worktree` isolada a partir da branch principal.
- **Sub-agentes**: usar `task` para paralelismo e `invoke` para expertise.
- **Atalhos**: `gcp` (commit+push), `gpr` (PR), `gcp & gpr` (commit+push+PR).
- **Emoji**: primeira resposta em cada nova conversa começa com 💭.

## Segurança

- NUNCA expor chaves de API em código
- Usar variáveis de ambiente para configuração
- Criar `.env-example` com variáveis documentadas
- NUNCA committar `.env` no repositório

## Deploy

- Deploy preview automático para PRs
- Deploy produção automático para merge na main
- Validar preview antes de merge
- Monitorar status do deploy

## Testes

- Rodar testes antes de merge
- Cobrir features principais com testes
- Usar Playwright para testes E2E
- Usar Jest para testes unitários

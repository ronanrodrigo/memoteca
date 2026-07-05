# Regras do Projeto

## Regras Gerais

1. **NUNCA executar comandos diretamente** — SEMPRE via `make <target>`
   - Proibido: `gh`, `curl`, `jq`, `yq`, `npm run`, `jest`, etc. diretamente
   - Exceção: comandos internos do agente (ler arquivos, escrever código)

2. **Repositório obrigatório** — O usuário DEVE ter um repo no GitHub (criado via "Use this template")

3. **Projetos dentro do memotek** — NÃO criar projetos dentro do memotek que não sejam o próprio memotek

4. **Precedência** — O que está no AGENTS.md tem precedência sobre definições de agentes/skills

5. **Versionamento** — Cada implementação é versionada com código do modelo: `memotek-<modelo>`

## Convenções de Código

- Usar TypeScript para todos os projetos
- Seguir padrões Next.js App Router
- Usar Chakra UI para componentes
- Implementar testes para features principais
- Documentar APIs e componentes

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

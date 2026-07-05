# CI Agent

## Função
Configura pipeline de CI/CD no repositório.

## Responsabilidades
1. Criar pipeline via `make setup-gh-actions`
2. Configurar pipeline para rodar: lint, typecheck, test, build
3. Tudo via targets Makefile no repo de destino

## Comandos
- `make setup-gh-actions` — Configurar workflows

## Fluxo
1. Criar workflow de testes
2. Configurar triggers (push, PR)
3. Definir steps: install, lint, typecheck, test, build
4. Configurar caching de dependências
5. Testar pipeline

## Pipeline Padrão
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
- GitHub Actions workflow configurado
- Pipeline rodando em pushes e PRs
- Issue atualizada com status do CI

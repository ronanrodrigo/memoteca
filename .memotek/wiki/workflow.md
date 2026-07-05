# Workflow do Memotek

## Fluxo Principal

### 1. Input do Usuário
O usuário pode fornecer input de duas formas:
- **Prompt manual** — Usuário descreve o que precisa
- **Cron /listen-issues** — Polling de issues abertas

### 2. Intake
A skill Intake coleta informações e cria issue no GitHub:
- Pergunta tipo de task (criação, adição, bug fix)
- Coleta detalhes específicos
- Cria issue com template `feature_request.yml`

### 3. Research
O Researcher busca projetos similares no GitHub:
- Usa `github_search_repositories`
- Analisa top 3 por stars
- Documenta referências na issue

### 4. Stack Selection
O Stack Selector define a stack:
- Analisa resultados da pesquisa
- Seleciona da lista predefinida
- Justifica escolhas

### 5. Implementation
O Implementer cria o projeto:
- Executa `make scaffold`
- Instala dependências
- Implementa features

### 6. Deploy
O Deploy Agent configura deploy:
- Configura GitHub Actions
- Executa `make deploy-preview`
- Documenta URL na issue

### 7. CI
O CI Agent configura pipeline:
- Cria workflows de teste
- Configura lint, typecheck, test, build

### 8. Validation
O PR Validator monitora e valida:
- Verifica checks CI
- Testa preview URL
- Executa merge quando válido
- Executa deploy produção após merge

### 9. Memory
O Memory Agent atualiza a issue:
- Marca checkboxes
- Adiciona comentários
- Inclui diagramas Mermaid

## Cron Jobs

### Listen Issues (a cada 5 minutos)
```
*/5 * * * * cd ~/Developer/memotek-mimo-v2-5-free && make listen-issues >> /tmp/memotek-listen.log 2>&1
```

### PR Validator (a cada 3 minutos)
```
*/3 * * * * cd ~/Developer/memotek-mimo-v2-5-free && make test-preview >> /tmp/memotek-pr.log 2>&1
```

## Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `make memory-update` | Atualizar issue |
| `make search-projects` | Buscar projetos |
| `make gh-actions-setup` | Configurar CI/CD |
| `make listen-issues` | Polling de issues |
| `make test` | Rodar testes |
| `make test-preview` | Testar preview |
| `make pr-create` | Criar PR |
| `make pr-merge` | Merge PR |
| `make deploy-preview` | Deploy preview |
| `make deploy-production` | Deploy produção |
| `make scaffold` | Criar projeto |

# Skill: Intake

## Função
Coleta input do usuário e cria issue no GitHub com template apropriado.

## Trigger
- Usuário fornece prompt manual descrevendo o que precisa
- schedule_job detecta nova issue aberta via `make listen-issues`

## Fluxo

### 1. Identificar Tipo de Input
Perguntar ao usuário:
- **Criação**: Criar algo do zero
- **Adição**: Adicionar feature a algo existente
- **Bug Fix**: Corrigir algo que não funciona

### 2. Coletar Informações

#### Para Criação:
- Nome do projeto
- Descrição do que precisa
- Tipo de projeto (dashboard, CRUD, landing page, etc.)
- Persistência necessária? (sim/não)
- Referências ou inspirações

#### Para Adição:
- O que adicionar
- Onde adicionar (que arquivos/components)
- Dependências

#### Para Bug Fix:
- O que está errado
- Passos para reproduzir
- Comportamento esperado vs atual

### 3. Criar Issue
Usar template `feature_request.yml` com as respostas coletadas.

### 4. Iniciar Pipeline
Após criar issue, o Orchestrator assume o controle.

## Comandos
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="Intake completo"` — Finalizar intake

## Output
- Issue criada no GitHub com template preenchido
- Label `memotek` aplicada
- Pipeline iniciado pelo Orchestrator

# Workflow de worktree (skill Assistente)

## Princípio

Cada feature/tarefa é trabalhada em uma worktree git isolada a partir da branch principal do repo. Isso mantém o working directory principal limpo e permite trabalhar múltiplas features em paralelo sem conflitos.

## Passos padrão

### 1. Criar a worktree

```bash
# a partir da raiz do repo principal
git worktree add -b feature/<proj>-<short-id> ../<proj>-wt main
cd ../<proj>-wt
```

- `<proj>` = identificador descritivo da feature/issue (ex: `ota-hermes`, `feature-x`)
- `<short-id>` = 3-5 chars descritivos (ex: `signin`, `otsignup`, `fixnav`)
- `main` pode ser `master` se for a branch principal configurada

### 2. Trabalhar na worktree

- Todas as alterações, commits, testes e pushes ocorrem na worktree.
- O plano, a memória e o board de tarefas NÃO são arquivos no repo — vivem na issue do GitHub (corpo + comentários sequenciais via `make memory-update ... COMMENT="..."`).

### 3. Sincronizar com o remote

```bash
git push -u origin feature/<proj>-<short-id>
```

### 4. Abrir o PR a partir da worktree

`make pr-create` ou `gpr` (no repo scaffolded) operam normalmente a partir da worktree.

### 5. Após merge da PR

```bash
cd <repo-principal>
git worktree remove ../<proj>-wt
git branch -d feature/<proj>-<short-id>
```

## Anti-padrões

- ❌ Commitar na branch principal direto sem worktree.
- ❌ Deixar a worktree sem limpeza após merge.
- ❌ Reaproveitar worktree entre features distintas — crie uma nova por tarefa.
- ❌ Criar arquivos de plano/MEMORY/TODO no working tree — use a issue do GitHub.
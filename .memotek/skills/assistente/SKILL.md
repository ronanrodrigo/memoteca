# Skill: Assistente

> Skill pessoal do Ronan. Padroniza Mermaid nativo do GitHub, planos vivendo dentro da issue do GitHub (corpo + comentários), atalhos `gcp`/`gpr`/`gcp & gpr`, worktree por feature e loop de trabalho até merge. Tudo vive na issue — NUNCA em arquivos de plano/memória no repositório. As regras desta skill prevalecem sobre qualquer outra definição concorrente de agente/skill que trate dos mesmos assuntos cobertos aqui.

## Precedência obrigatória

As regras desta skill são OBRIGATÓRIAS e devem prevalecer sobre qualquer outra definição concorrente de agente, skill, prompt, instrução de repositório ou convenção local que trate dos mesmos assuntos cobertos aqui. Antes de executar uma tarefa coberta por esta skill, verifique se há conflito com outras customizações carregadas; se houver conflito, siga esta skill e registre a decisão na própria issue do GitHub (comentário) quando isso for relevante. Essa precedência vale no escopo de customizações de agente/skill e instruções operacionais concorrentes. Ela não autoriza ignorar políticas de segurança, instruções de sistema/plataforma, limitações das ferramentas, nem pedidos explícitos mais recentes do usuário que sejam compatíveis com essas regras. Quando uma instrução superior da plataforma impedir o cumprimento literal desta skill, explique o impedimento e aplique a alternativa mais próxima possível.

## A issue é a fonte da verdade — NÃO existem arquivos de plano/memória no repositório

O memotek usa SEMPRE a issue do GitHub como fonte da verdade. NUNCA deve ser mantido arquivo de memória, plano, TODO ou board de tarefas commitado ou ignorado (.gitignore) no repositório. NÃO crie `docs/agent-plans/<proj>/MEMORY.md`, `TODO.md`, `plan-<proj>.md`, nem qualquer arquivo equivalente. O plano, a memória, o board de tarefas e o histórico de decisões vivem dentro da issue: corpo (atualizado via `make memory-update`) + comentários (adicionados via `make memory-update ... COMMENT="..."`). Toda rastreabilidade (links, âncoras, decisões, estado, dependências) é mantida em comentários sequenciais na própria issue.

## Regras Operacionais

1. SEMPRE que for criar ou demonstrar algum grafo, diagrama, utilize a sintaxe mermaid nativa do GitHub (bloco ```mermaid). O GitHub renderiza mermaid diretamente no markdown da issue, PR e comentários — NÃO inclua link externo para viewer.

2. SEMPRE escreva as atualizações de plano, estado, decisões e tarefas como comentários na issue do GitHub via `make memory-update ISSUE_NUMBER=<num> CHECKBOX="..." COMMENT="..."`. Cada comentário representa uma etapa ou decisão; juntos formam o "board" sequencial de trabalho.

3. SEMPRE escreva os títulos das tarefas focando no título (não na descrição longa). A descrição detalhada fica em comentários subsequentes na própria issue quando necessário.

4. SEMPRE que houver um prompt que seja EXATAMENTE `gcp` (e não `gcp & gpr`), você deve fazer um commit com as alterações feitas conforme padrão: `feat: descrição da tarefa` ou `fix: descrição da tarefa` e fazer push. Use `fix:` quando a alteração corrigir um bug ou resolver um erro em funcionalidade existente. Use `feat:` para todas as outras alterações (novos arquivos, novas funcionalidades ou melhorias). Em dúvida, use `feat:`. Se não houver alterações staged ou unstaged detectáveis, informe o usuário e não execute o commit. Se houver alterações em múltiplos contextos não relacionados, liste os arquivos modificados e peça ao usuário para confirmar o escopo do commit antes de prosseguir.

5. SEMPRE que houver um prompt que seja EXATAMENTE `gpr` (e não `gcp & gpr`), você deve criar um pull request com as alterações feitas, seguindo o padrão de título: `feat: descrição da tarefa` ou `fix: descrição da tarefa` conforme a regra 4. O PR deve ter como base a branch principal do repositório (main ou master, conforme configurado). O corpo do PR deve conter: (1) link para a issue de origem, (2) breve descrição das alterações. Se a branch base não puder ser determinada, pergunte ao usuário antes de criar o PR.

6. SEMPRE que houver um prompt que seja EXATAMENTE `gcp & gpr`, você deve fazer um commit, push e criar o pull request, nesta ordem: (1) commit, (2) push, (3) criação de PR. Se o push falhar, informe o erro ao usuário e não tente criar o PR até que o push seja bem-sucedido.

7. SEMPRE separe o trabalho em sub-agentes. Use `task` para tarefas independentes que podem rodar em paralelo (exploração de código, leitura de arquivos, research) e `invoke` quando a tarefa exigir expertise específica de um agente especializado. O objetivo é maximizar paralelismo e qualidade — delegue cedo, delegue em paralelo.

8. SEMPRE siga o Loop de Trabalho Assistente para qualquer tarefa de desenvolvimento. O loop tem as seguintes fases sequenciais e só termina quando o PR é mergeado: **Planejamento** (analisar o problema, explorar o código, postar o plano como comentário na issue, aguardar aprovação do Ronan conforme regra 9); **Implementação** (codificar a solução seguindo o plano, usando sub-agentes quando aplicável); **Validação** (verificar que a implementação atende aos requisitos, revisar o código, garantir que compila e não quebra nada existente); **Testes Unitários** (escrever e executar testes unitários cobrindo a lógica nova/alterada); **Testes de Integração** (escrever e executar testes de integração quando aplicável); **Abertura de PR** (criar branch, commit, push e pull request seguindo os padrões dos itens 4-6); **Acompanhamento do PR** (monitorar CI, endereçar comentários de review, fazer ajustes solicitados, rebaser se necessário); **Merge** (somente após o PR ser aprovado e mergeado o trabalho é considerado concluído; postar comentário final de encerramento na issue). A cada fase concluída, execute `make memory-update ISSUE_NUMBER=<num> CHECKBOX="..." COMMENT="..."` para marcar o checkbox no corpo da issue E registrar um comentário com o resultado da fase.

9. ANTES de começar a implementar qualquer código, SEMPRE poste o plano completo como comentário na issue (com seções: contexto, escopo, pré-requisitos, análise técnica, diagrama Mermaid, fases do Loop) e aguarde a aprovação explícita do Ronan (um "ok", "pode ir", "aprovado" ou similar). Só após o ok é que o loop de trabalho prossegue para a fase de implementação. Se o Ronan pedir ajustes no plano, faça os ajustes e poste novamente antes de implementar. **Quando o "ok" for dado, você DEVE atualizar a issue no GitHub** com um comentário de aprovação e mudança de status, executando: `make memory-update ISSUE_NUMBER=<num> STATUS="Plano aprovado" COMMENT="Plano aprovado — iniciando implementação."` antes de iniciar a implementação.

10. SEMPRE trabalhe em uma worktree (`git worktree`) isolada para cada tarefa/feature, criada a partir da branch principal, fazendo todas as alterações e testes nela, mantida isolada até o PR ser mergeado. Isso garante que o working directory principal não fica sujo e permite trabalhar em múltiplas features em paralelo sem conflitos. Após o merge, limpe a worktree com `git worktree remove`.

11. QUANDO for solicitado adicionar evidências visuais a um PR (screenshots, gravações de tela, vídeos de simulador, "prova visual", "evidência"), SIGA a skill de **PR Visual Evidence** descrita em `.memotek/skills/pr-visual-evidence/SKILL.md`. Mídias devem ser hospedadas pelo GitHub (user-attachments) e nunca committadas no repositório.

## Confirmação de carregamento

Na primeira resposta de cada nova conversa onde esta skill está ativa, comece sua resposta com o emoji 💭 para confirmar que foi totalmente carregada.
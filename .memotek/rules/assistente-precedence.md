# Precedência da Skill Assistente

## Hierarquia de precedência (ordem crescente — último vence)

1. Configurações de plataforma / instrução de sistema.
2. Políticas de segurança da ferramenta.
3. Pedidos explícitos e atuais do usuário compatíveis com esta skill.
4. **Skill Assistente** (`.memotek/skills/assistente/SKILL.md`) — rege temas cobertos por ela (Mermaid nativo do GitHub, issue do GitHub como fonte da verdade sem arquivos de plano/memória no repo, atalhos `gcp`/`gpr`, Loop Assistente, worktree, PR Visual Evidence, gate humano de aprovação).
5. `AGENTS.md` e `.memotek/agents/*.md` — orquestração do pipeline do memotek.
6. `.memotek/rules/project-rules.md` — regras operacionais do projeto.
7. `.memotek/skills/< outras >` — demais skills.

## Quando há conflito

- Siga a Skill Assistente nos temas cobertos por ela.
- Registre a decisão de conflito no `MEMORY.md` do projeto e/ou na resposta final ao Ronan.
- Se uma instrução superior da plataforma impedir o cumprimento literal, explique o impedimento e aplique a alternativa mais próxima possível.

## Quando NÃO se aplica a precedência

- Políticas de segurança (ex: nunca expor credenciais) — prevalecem sempre.
- Instruções de sistema/plataforma.
- Limitações das ferramentas.
- Pedidos explícitos do Ronan posteriores e compatíveis com a skill.
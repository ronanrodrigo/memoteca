# Memory Agent

## Função
Atualiza a issue original com progresso e status, marcando checkboxes em tempo real.

## Responsabilidades
1. Após CADA etapa do pipeline, marcar o checkbox correspondente no corpo da issue
2. Os textos do CHECKBOX devem corresponder EXATAMENTE aos rótulos do template `feature_request.yml`
3. Ao final do pipeline, marcar todos os checkboxes restantes e fechar a issue
4. Adicionar comentários com resultado de cada etapa (opcional, alongside checkboxes)
5. Incluir diagramas Mermaid quando fizer sentido (no comentário, não no corpo)

## Comandos
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="<texto exato>"` — Marcar checkbox
- `make memory-update ISSUE_NUMBER=<num> CHECKBOX="<texto>" COMMENT="<comentário>"` — Checkbox + comentário
- `make memory-update ISSUE_NUMBER=<num> STATUS="<status>"` — Atualizar campo Status
- `make memory-finalize ISSUE_NUMBER=<num>` — Marcar TODOS checkboxes + fechar issue

## Textos EXATOS dos Checkboxes (do template feature_request.yml)

```
Intake completo
Research: benchmarking concluído
Stack definida
Código implementado
Deploy preview funcional
Pipeline CI configurada
PR criado
Checks todos verdes
Preview testado via HTTP
PR mergeado
Deploy produção concluído
```

## Fluxo
1. Após Research → `CHECKBOX="Research: benchmarking concluído"`
2. Após Stack → `CHECKBOX="Stack definida"`
3. Após Implement → `CHECKBOX="Código implementado"`
4. Após Deploy Preview → `CHECKBOX="Deploy preview funcional"`
5. Após CI → `CHECKBOX="Pipeline CI configurada"`
6. Após PR criado → `CHECKBOX="PR criado"`
7. Após checks verdes → `CHECKBOX="Checks todos verdes"`
8. Após testar preview → `CHECKBOX="Preview testado via HTTP"`
9. Após merge → `CHECKBOX="PR mergeado"`
10. Após deploy produção → `CHECKBOX="Deploy produção concluído"`
11. **Finalizar** → `make memory-finalize ISSUE_NUMBER=<num>` (marca todos + fecha issue)

## Regra de Ouro
**NUNCA pular `make memory-update` após uma etapa.** Os checkboxes `[ ]` devem
virar `[x]` em tempo real, visíveis para o usuário acompanhar o progresso.
Se o script avisar "checkbox não encontrado", o texto não corresponde —
verifique o corpo da issue e use o texto exato.

## Output
- Checkboxes marcados em tempo real no corpo da issue
- Issue fechada ao final do pipeline com todos os checkboxes `[x]`
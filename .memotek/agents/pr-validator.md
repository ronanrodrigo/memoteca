# PR Validator Agent

## Função
Monitora e valida Pull Requests antes do merge.

## Responsabilidades
1. Usar `make test-preview` para testar preview URL via HTTP
2. Quando tudo verde: `make pr-merge`
3. Após merge: `make deploy-production`

## Comandos
- `make test-preview PREVIEW_URL="<url>"` — Testar preview
- `make pr-merge PR_NUMBER=<num>` — Merge PR
- `make deploy-production` — Deploy produção

## Fluxo
1. Monitorar checks do PR
2. Verificar se preview está funcional
3. Validar testes E2E no preview
4. Se tudo verde, executar merge
5. Após merge, deploy produção
6. Atualizar issue com status final

## Critérios de Validação
- [ ] Todos os checks CI verdes
- [ ] Preview URL retornando 200
- [ ] Testes E2E passando
- [ ] Build sem erros
- [ ] Lint sem warnings

## Output
- PR mergeado quando válido
- Deploy produção executado
- Issue fechada com sucesso

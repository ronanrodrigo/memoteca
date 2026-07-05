# Implementer Agent

## Função
Gera e implementa código do projeto baseado na issue e stack selecionada.

## Responsabilidades
1. Criar projeto Next.js completo via `create-next-app`
2. Customizar com stack selecionada
3. Implementar features baseado na issue
4. Seguir convenções da stack

## Comandos
- `make scaffold PROJECT_NAME="<nome>"` — Criar projeto

## Fluxo
1. Ler issue para entender requisitos
2. Executar scaffold para criar base
3. Instalar dependências adicionais
4. Implementar componentes e features
5. Configurar rotas e páginas
6. Integrar com Supabase (se necessário)
7. Atualizar issue com progresso

## Convenções
- Usar TypeScript
- Seguir padrões Next.js App Router
- Usar Chakra UI para componentes
- Implementar testes para features principais
- Documentar APIs e componentes

## Output
- Código implementado no repositório
- Atualização na issue com `make memory-update`
- Comentário com resumo do implementado

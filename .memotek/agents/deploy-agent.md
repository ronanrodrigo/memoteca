# Deploy Agent

## Função
Configura e realiza deploy na Vercel.

## Responsabilidades
1. Configurar automações GitHub Actions via `make setup-gh-actions`
2. Guiar o usuário via `vercel login` se necessário
3. Deploy preview via `make deploy-preview`
4. Criar `.env-example` com variáveis necessárias

## Comandos
- `make setup-gh-actions` — Configurar workflows
- `make deploy-preview` — Deploy preview
- `make deploy-production` — Deploy produção

## Fluxo
1. Verificar se Vercel CLI está instalado
2. Configurar GitHub Actions
3. Criar variáveis de ambiente necessárias
4. Executar deploy preview
5. Validar se deploy está funcional
6. Atualizar issue com URL do preview

## Variáveis de Ambiente
```bash
# Vercel
VERCEL_TOKEN=
VERCEL_ORG_ID=
VERCEL_PROJECT_ID=

# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

## Output
- Deploy preview funcional
- URL documentada na issue
- GitHub Actions configurados

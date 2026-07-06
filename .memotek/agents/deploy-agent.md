# Deploy Agent

## Purpose
Configures and performs deployment on Vercel.

## Responsibilities
1. Configure GitHub Actions automations via `make setup-gh-actions`
2. Guide the user via `vercel login` if needed
3. Deploy preview via `make deploy-preview`
4. Create `.env-example` with required variables

## Commands
- `make setup-gh-actions` — Configure workflows
- `make deploy-preview` — Deploy preview
- `make deploy-production` — Deploy production

## Workflow
1. Check if Vercel CLI is installed
2. Configure GitHub Actions
3. Create required environment variables
4. Run deploy preview
5. Validate if deploy is functional
6. Update issue with preview URL

## Environment Variables
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
- Deploy preview functional
- URL documented in the issue
- GitHub Actions configured

#!/bin/bash
# setup-vercel-secrets.sh — Configura secrets da Vercel no GitHub Actions.
# Uso: make setup-vercel-secrets
#
# Detecta automaticamente VERCEL_ORG_ID e VERCEL_PROJECT_ID a partir de
# .vercel/project.json (criado por `vercel link` / `vercel --yes`).
# Pede apenas o VERCEL_TOKEN (gerado em https://vercel.com/account/tokens).
#
# Requer:
#   - Vercel CLI autenticado (`vercel login`) para que .vercel/project.json exista
#   - GitHub CLI autenticado (`gh auth login`) para gravar os secrets no repo
#
# Modo não-interativo: passe VERCEL_TOKEN por env var (útil para automação):
#   VERCEL_TOKEN=vercel_xxx make setup-vercel-secrets

set -euo pipefail

# ─── helpers ──────────────────────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
  BOLD=$(tput bold); DIM=$(tput dim); RESET=$(tput sgr0)
  BLUE=$(tput setaf 4); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); RED=$(tput setaf 1)
else
  BOLD=""; DIM=""; RESET=""; BLUE=""; GREEN=""; YELLOW=""; RED=""
fi

say()    { printf '  %s\n' "$1"; }
step()   { printf '  %s•%s %s\n' "$BLUE" "$RESET" "$1"; }
note()   { printf '  %s%s%s\n' "$DIM" "$1" "$RESET"; }
ok()     { printf '  %s✓ %s%s\n' "$GREEN" "$1" "$RESET"; }
warn()   { printf '  %s⚠ %s%s\n' "$YELLOW" "$1" "$RESET"; }
err()    { printf '  %s✖ %s%s\n' "$RED" "$1" "$RESET"; }
ask_secret() {
  printf '  %s%s%s ' "$BOLD" "$2" "$RESET"
  read -rs "$1" || true
  printf '\n'
}
open_url() {
  local url="$1"
  { if   command -v wslview     >/dev/null 2>&1; then wslview "$url"
    elif command -v explorer.exe >/dev/null 2>&1; then explorer.exe "$url"
    elif command -v xdg-open    >/dev/null 2>&1; then xdg-open "$url"
    elif command -v open        >/dev/null 2>&1; then open "$url"
    else :; fi
  } >/dev/null 2>&1 || true
}

# ─── pré-checks ────────────────────────────────────────────────────────────
REPO_SLUG="${REPO_SLUG:-}"
if [ -z "$REPO_SLUG" ]; then
  if command -v gh >/dev/null 2>&1; then
    REPO_SLUG=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
  fi
fi
if [ -z "$REPO_SLUG" ]; then
  err "Não consegui detectar o repo (gh CLI ausente ou não autenticado)."
  err "Rode 'gh auth login' ou defina REPO_SLUG=owner/repo make setup-vercel-secrets"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  err "GitHub CLI não autenticado. Rode: gh auth login"
  exit 1
fi

# ─── detectar Org/Project ID ────────────────────────────────────────────────
VERCEL_ORG_ID="${VERCEL_ORG_ID:-}"
VERCEL_PROJECT_ID="${VERCEL_PROJECT_ID:-}"
PROJECT_FILE=".vercel/project.json"

if [ -z "$VERCEL_ORG_ID" ] || [ -z "$VERCEL_PROJECT_ID" ]; then
  if [ -f "$PROJECT_FILE" ] && command -v jq >/dev/null 2>&1; then
    [ -z "$VERCEL_ORG_ID" ]     && VERCEL_ORG_ID=$(jq -r .orgId     < "$PROJECT_FILE" 2>/dev/null || echo "")
    [ -z "$VERCEL_PROJECT_ID" ] && VERCEL_PROJECT_ID=$(jq -r .projectId < "$PROJECT_FILE" 2>/dev/null || echo "")
  elif [ -f "$PROJECT_FILE" ]; then
    [ -z "$VERCEL_ORG_ID" ]     && VERCEL_ORG_ID=$(grep -o '"orgId":"[^"]*"'     "$PROJECT_FILE" | sed 's/.*:"//;s/"//' || echo "")
    [ -z "$VERCEL_PROJECT_ID" ] && VERCEL_PROJECT_ID=$(grep -o '"projectId":"[^"]*"' "$PROJECT_FILE" | sed 's/.*:"//;s/"//' || echo "")
  fi
fi

# ─── token ─────────────────────────────────────────────────────────────────
VERCEL_TOKEN="${VERCEL_TOKEN:-}"

if [ -z "$VERCEL_TOKEN" ]; then
  if [ ! -t 0 ]; then
    err "VERCEL_TOKEN não fornecido e stdin não é TTY."
    err "Modo não-interativo: VERCEL_TOKEN=vercel_xxx make setup-vercel-secrets"
    exit 1
  fi
  printf '\n%s%s  Vercel → GitHub Actions secrets%s\n' "$BOLD" "$BLUE" "$RESET"
  printf '%s  Repo: %s%s\n\n' "$DIM" "$REPO_SLUG" "$RESET"
  say "Gere um token em https://vercel.com/account/tokens"
  open_url "https://vercel.com/account/tokens"
  step "Clique em 'Create Token'"
  step "Name: shows-ci-deploy (ou outro)"
  step "Scope: Full account  →  Create"
  step "Copie o token gerado (começa com vercel_)"
  ask_secret VERCEL_TOKEN "Cole o token aqui:"
  if [ -z "$VERCEL_TOKEN" ]; then
    err "Token vazio. Abortando."
    exit 1
  fi
fi

# ─── validar IDs ────────────────────────────────────────────────────────────
if [ -z "$VERCEL_ORG_ID" ] || [ -z "$VERCEL_PROJECT_ID" ]; then
  err "Não detectei VERCEL_ORG_ID / VERCEL_PROJECT_ID em .vercel/project.json."
  err "Rode 'vercel link' primeiro ou passe via env:"
  err "  VERCEL_ORG_ID=team_xxx VERCEL_PROJECT_ID=prj_xxx make setup-vercel-secrets"
  exit 1
fi

# ─── gravar .env local ─────────────────────────────────────────────────────
ENV_FILE="${ENV_FILE:-.env}"
upsert_env() {
  local key="$1" val="$2" tmp
  touch "$ENV_FILE"
  tmp=$(mktemp)
  grep -vE "^${key}=" "$ENV_FILE" > "$tmp" 2>/dev/null || true
  printf '%s=%s\n' "$key" "$val" >> "$tmp"
  mv "$tmp" "$ENV_FILE"
}
upsert_env VERCEL_TOKEN "$VERCEL_TOKEN"
upsert_env VERCEL_ORG_ID "$VERCEL_ORG_ID"
upsert_env VERCEL_PROJECT_ID "$VERCEL_PROJECT_ID"
ok "gravou .env (VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID)"

# ─── gravar secrets no GitHub Actions ──────────────────────────────────────
if [ -t 0 ]; then printf '\n%s%s  Enviando secrets ao GitHub Actions (%s)...%s\n\n' "$BOLD" "$BLUE" "$REPO_SLUG" "$RESET"; fi
printf '%s' "$VERCEL_TOKEN"      | gh secret set VERCEL_TOKEN      --repo "$REPO_SLUG" && ok "VERCEL_TOKEN"
printf '%s' "$VERCEL_ORG_ID"     | gh secret set VERCEL_ORG_ID     --repo "$REPO_SLUG" && ok "VERCEL_ORG_ID"
printf '%s' "$VERCEL_PROJECT_ID" | gh secret set VERCEL_PROJECT_ID --repo "$REPO_SLUG" && ok "VERCEL_PROJECT_ID"

printf '\n%s%s  ✓ Pronto.%s  Deploy automático via GitHub Actions habilitado para %s\n' "$BOLD" "$GREEN" "$RESET" "$REPO_SLUG"
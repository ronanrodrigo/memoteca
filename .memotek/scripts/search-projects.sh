#!/bin/bash
# search-projects.sh — Busca projetos similares no GitHub
# Uso: make search-projects QUERY="<palavras-chave>"

set -euo pipefail

QUERY="${QUERY:-}"

if [ -z "$QUERY" ]; then
  echo "❌ QUERY é obrigatório"
  echo "Uso: make search-projects QUERY='sistema de cadastro químico'"
  exit 1
fi

echo "🔍 Buscando projetos similares para: $QUERY"
echo "---"

# Usar gh search repos
gh search repos "$QUERY" --limit 10 --sort stars --json fullName,stargazersCount,description,url \
  --template '{{range .}}{{.fullName}} | ⭐ {{.stargazersCount}} | {{.description}} | {{.url}}{{"\n"}}{{end}}'

echo ""
echo "📊 Busca concluída. Top 10 projetos por stars."

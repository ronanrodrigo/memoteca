#!/bin/bash
# run-tests.sh — Roda testes no repo de destino
# Uso: make test

set -euo pipefail

echo "🧪 Executando testes..."

if [ -f "package.json" ]; then
  # Verificar se tem scripts de teste
  if grep -q '"test"' package.json; then
    npm test
  else
    echo "⚠️ Nenhum script de teste encontrado em package.json"
  fi
elif [ -f "Makefile" ]; then
  # Tentar rodar make test no repo-alvo
  make test
else
  echo "❌ Nenhum teste configurado. Adicione package.json ou Makefile com target de teste."
  exit 1
fi

echo "✅ Testes concluídos!"

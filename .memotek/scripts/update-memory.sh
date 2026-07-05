#!/bin/bash
# update-memory.sh — Atualiza issue com progresso (checkboxes, status, comentários)
# Uso:
#   make memory-update ISSUE_NUMBER=<num> CHECKBOX="<texto>"
#   make memory-update ISSUE_NUMBER=<num> CHECKBOX="<texto>" COMMENT="<comentario>"
#   make memory-update ISSUE_NUMBER=<num> STATUS="<status>"
#   make memory-update ISSUE_NUMBER=<num> FINALIZE=1   # marca TODOS checkboxes + fecha issue
#
# O CHECKBOX precisa corresponder ao texto exato do checkbox no corpo da issue
# (após "- [ ] "). Caracteres especiais são tratados corretamente (Node, não sed).

set -euo pipefail

ISSUE_NUMBER="${ISSUE_NUMBER:-}"
CHECKBOX="${CHECKBOX:-}"
COMMENT="${COMMENT:-}"
STATUS="${STATUS:-}"
FINALIZE="${FINALIZE:-0}"

if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ ISSUE_NUMBER é obrigatório"
  echo "Uso: make memory-update ISSUE_NUMBER=1 CHECKBOX='Research: benchmarking concluído'"
  echo "     make memory-update ISSUE_NUMBER=1 FINALIZE=1"
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  echo "❌ Não foi possível detectar o repositório. Execute dentro de um repo GitHub."
  exit 1
fi

echo "📝 Atualizando issue #$ISSUE_NUMBER em $REPO..."

CURRENT_BODY=$(gh issue view "$ISSUE_NUMBER" --json body -q '.body')

# Arquivos temporários para comunicação com Node
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
BODY_FILE="$TMP_DIR/body.txt"
MSG_FILE="$TMP_DIR/msg.txt"
ARGS_FILE="$TMP_DIR/args.json"

# Construir JSON de args com escaping correto
node -e '
  const fs = require("fs");
  const read = k => (k && k.length) ? JSON.stringify(k) : "null";
  fs.writeFileSync(process.argv[1],
    `{"checkbox":${read(process.env.CHECKBOX)},"status":${read(process.env.STATUS)},"finalize":${process.env.FINALIZE || 0}}`
  );
' "$ARGS_FILE" CHECKBOX="$CHECKBOX" STATUS="$STATUS" FINALIZE="$FINALIZE"

# Rodar Node: lê body do stdin, args do argv, escreve body em BODY_FILE, msgs em MSG_FILE
NODE_EXIT=0
printf '%s' "$CURRENT_BODY" | node -e '
  const fs = require("fs");
  const args = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const bodyFile = process.argv[2];
  const msgFile = process.argv[3];
  let body = fs.readFileSync(0, "utf8");
  let msgs = [];

  if (args.finalize) {
    const before = (body.match(/- \[ \]/g) || []).length;
    body = body.replace(/- \[ \]/g, "- [x]");
    const marked = before - (body.match(/- \[ \]/g) || []).length;
    if (marked > 0) msgs.push(`marcou ${marked} checkbox(es) (finalização)`);
    else msgs.push("nenhum checkbox pendente");
  } else if (args.checkbox) {
    const esc = args.checkbox.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const reTodo = new RegExp(`- \\[ \\] ${esc}`);
    const reDone = new RegExp(`- \\[x\\] ${esc}`);
    if (reTodo.test(body)) {
      body = body.replace(reTodo, `- [x] ${args.checkbox}`);
      msgs.push(`✅ checkbox marcado: ${args.checkbox}`);
    } else if (reDone.test(body)) {
      msgs.push(`→ checkbox já marcado: ${args.checkbox}`);
    } else {
      msgs.push(`⚠️  Checkbox não encontrado: "${args.checkbox}"`);
      msgs.push(`    Checkboxes no corpo da issue:`);
      (body.match(/- \[[ x]\] .+/g) || []).forEach(l => msgs.push(`      ${l}`));
      fs.writeFileSync(msgFile, msgs.join("\n") + "\n");
      fs.writeFileSync(bodyFile, body);
      process.exit(2);
    }
  }

  if (args.status && /\*\*Status:\*\* .+/.test(body)) {
    body = body.replace(/\*\*Status:\*\* .+/, `**Status:** ${args.status}`);
    msgs.push(`✅ status atualizado: ${args.status}`);
  }

  fs.writeFileSync(bodyFile, body);
  fs.writeFileSync(msgFile, msgs.join("\n") + "\n");
' "$ARGS_FILE" "$BODY_FILE" "$MSG_FILE" || NODE_EXIT=$?

# Printar mensagens do Node
[ -f "$MSG_FILE" ] && cat "$MSG_FILE"

# Se Node falhou (exit 2 = checkbox não encontrado), não atualizar o body
if [ "$NODE_EXIT" = "2" ]; then
  echo "ℹ️  Corpo da issue não foi modificado."
  exit 0
fi
if [ "$NODE_EXIT" != "0" ]; then
  echo "❌ Erro ao processar (exit $NODE_EXIT)"
  exit "$NODE_EXIT"
fi

NEW_BODY=$(cat "$BODY_FILE")

# ─── Atualizar corpo da issue (só se mudou) ────────────────────────────────
if [ "$NEW_BODY" != "$CURRENT_BODY" ]; then
  printf '%s' "$NEW_BODY" | gh issue edit "$ISSUE_NUMBER" --body-file - >/dev/null
  echo "✅ Corpo da issue atualizado"
else
  echo "ℹ️  Nenhuma mudança no corpo."
fi

# ─── Adicionar comentário ──────────────────────────────────────────────────
if [ -n "$COMMENT" ]; then
  printf '%s' "$COMMENT" | gh issue comment "$ISSUE_NUMBER" --body-file -
  echo "✅ Comentário adicionado"
fi

# ─── Finalizar: fechar issue ───────────────────────────────────────────────
if [ "$FINALIZE" = "1" ]; then
  gh issue close "$ISSUE_NUMBER" --reason completed 2>/dev/null || true
  echo "✅ Issue #$ISSUE_NUMBER fechada (finalizada)"
fi

echo "🎉 Issue #$ISSUE_NUMBER atualizada!"
# Skill: PR Visual Evidence

> Companion da skill **Assistente**. Define o workflow de captura de evidências
> visuais (screenshots, gravações de tela, vídeos) anexadas a Pull Requests.

## Quando usar

O Ronan solicitar evidências visuais em um PR com palavras como: "screenshots",
"gravação de tela", "vídeo do simulador", "prova visual", "evidência".

## Pré-requisitos

- Maestro CLI instalado e no PATH.
- Emulador/dispositivo/simulador alvo disponível.
- Repo do app mobile capaz de buildar a versão alvo da feature/PR.

## Dois métodos de captura

### Método 1 — Evidência pontual não-interativa (CLI)

Use quando você quer um fluxo curtíssimo (ex: um tap + screenshot) e não há
necessidade de integrar a um teste existente.

```bash
maestro record --local <flow>.yaml
```

- Edite o `<flow>.yaml` para conter os `launchApp`, `tapOn`, `assertVisible`
  mínimos que demonstram o comportamento.
- Rode e grave a execução; o Maestro gera `.mp4` no CWD.
- Hospede via GitHub (user-attachments) — nunca committe o binário no repo.

### Método 2 — Vídeo como artefato de teste de integração

Use quando o vídeo já faz parte de um teste de integração Maestro/CI:

No próprio `.yaml` do teste, envolva os steps relevantes com:

```yaml
- startRecording: evidence-feature-x
- tapOn: "Botão X"
- assertVisible: "Resultado"
- stopRecording
```

- O arquivo `.mp4` é produzido como artefato do próprio teste (CI ou local).
- Em CI, configure o job para fazer upload do artifact (`actions/upload-artifact`
  ou equivalente).
- Para PR, faça upload manualmente via GitHub user-attachments no comentário.

## Hospedagem de mídias — regra de ouro

- Mídias DEVEM ser hospedadas pelo GitHub (comment attachments / user-attachments).
- Mídias NUNCA DEVEM ser committadas no repositório.
- Após hospedar, edite o comentário do PR com a URL do anexo gerada pelo GitHub
  e um markdown `![](<url>)` ou link `[<descricao>](<url>)`.

## Fluxo completo

1. Identifique qual método se aplica ao pedido do Ronan.
2. (Se Método 2) Garanta que o teste de integração alvo existe; crie/ajuste o
   YAML adicionando `startRecording`/`stopRecording` ao redor dos steps
   relevantes.
3. Rode o fluxo (Método 1) ou o teste (Método 2).
4. Hospede o `.mp4` no GitHub (user-attachments).
5. Edite o comentário do PR com:
   - Descrição do que está sendo demonstrado.
   - Link/markdown da mídia recém-hospedada.
   - Issue de origem do trabalho (link).
6. Atualize o `MEMORY.md` do projeto com a URL do comentário do PR (âncora
   visual-evidence) e marque o checkbox correspondente no TODO.md.

## Anti-padrões

- ❌ Committar `.mp4`, `.png`, `.gif` no repo.
- ❌ Hospedar em CDNs externos (imgur, dropbox) — usar GitHub attachments.
- ❌ Anexar mídia sem descrever o que demonstra.
- ❌ Pular o comentário com a evidência no PR — o reviewer precisa ver inline.
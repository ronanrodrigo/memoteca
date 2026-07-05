# Skill: Listen Issues

## Trigger
Quando o usuário digitar `/listen-issues` ou "escutar issues" ou "iniciar polling".

## Ação OBRIGATÓRIA
Use a ferramenta `schedule_job` para agendar um job recorrente. NÃO execute `make listen-issues` diretamente.

## Como agendar
Execute a ferramenta `schedule_job` com este prompt:
```
Execute make listen-issues para verificar issues abertas com label memotek no repositório. Se encontrar issues pendentes, processe cada uma seguindo o pipeline: research → stack → implement → deploy → ci → pr → memory.
```

Configuração do job:
- **Intervalo:** a cada 5 minutos
- **Workdir:** diretório atual do projeto

## O que NÃO fazer
- NÃO execute `make listen-issues` diretamente
- NÃO crie cron jobs manuais
- Use APENAS a ferramenta `schedule_job`

## Comandos úteis após agendar
- `Show my scheduled jobs` — lista jobs ativos
- `Run the listen-issues job now` — executa imediatamente
- `Show logs for listen-issues` — vê logs
- `Delete the listen-issues job` — remove o job

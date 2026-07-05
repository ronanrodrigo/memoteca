# Skill: Listen Issues

## Trigger
Quando o usuário digitar `/listen-issues` ou "escutar issues" ou "iniciar polling de issues".

## Ação
Agende um job recorrente usando o `schedule_job` do opencode-scheduler para verificar issues abertas com label `memotek` a cada 5 minutos.

## Prompt do Job
```
Execute make listen-issues para verificar issues abertas com label memotek no repositório. Se encontrar issues pendentes, processe cada uma seguindo o pipeline: research → stack → implement → deploy → ci → pr → memory.
```

## Configuração
- **Intervalo:** a cada 5 minutos
- **Workdir:** diretório atual do projeto
- **Timeout:** 300 segundos (5 minutos)

## Comando para agendar
```
Schedule a job every 5 minutes to run make listen-issues and process any open memotek issues
```

## Comandos úteis
- `Show my scheduled jobs` — lista jobs ativos
- `Run the listen-issues job now` — executa imediatamente
- `Show logs for listen-issues` — vê logs
- `Delete the listen-issues job` — remove o job

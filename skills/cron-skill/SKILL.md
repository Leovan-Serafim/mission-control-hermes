---
name: cron-skill
description: "Wrapper for cron CLI commands for Mission Control bridge."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, cron, mission-control, bridge, scheduling]
    related_skills: [hermes-agent]
---

## When to Use

Use when the Mission Control bridge needs to list/create/run/pause/resume/remove/edit cron jobs via Hermes CLI (`hermes cron list --json`, `create`, `run`, `pause`, `resume`, `remove`, `edit`). Trigger: "cron list --json", "cron create", "cron run".

# Cron Skill — Wrapper para Bridge Mission Control

Skill que expõe comandos cron que o bridge usa para espelhar cron jobs no Postgres (`DataStore`) e executar agendados via dashboard.

## Comandos que o Bridge Usa

```bash
# Listar crons
hermes cron list --json

# Criar cron
hermes cron create "0 8 * * *" "Daily briefing" --name daily-brief

# Executar cron manualmente
hermes cron run daily-brief

# Pausar/Retomar
hermes cron pause daily-brief
hermes cron resume daily-brief

# Remover
hermes cron remove daily-brief

# Editar
hermes cron edit daily-brief --schedule "0 7 * * *" --prompt "Briefing às 7h"
```

## Formato JSON Esperado (list)

```json
[
  {
    "id": "daily-brief",
    "name": "daily-brief",
    "schedule": "0 8 * * *",
    "prompt": "Daily briefing",
    "status": "active",
    "last_run": "2026-10-31T08:00:00Z",
    "next_run": "2026-11-01T08:00:00Z",
    "health": "healthy"
  }
]
```

## Health Check

O bridge roda `hermes cron list` a cada `BRIDGE_MIRROR_MS` e atualiza `DataStore` key=`cron_health` com status agregado.

## Uso Direto

```bash
hermes chat -q "cron list --json"
hermes chat -q "cron create '0 8 * * *' 'Daily briefing' --name daily-brief"
```

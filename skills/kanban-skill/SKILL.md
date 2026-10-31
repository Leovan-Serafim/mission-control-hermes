---
name: kanban-skill
description: "Wrapper for kanban CLI commands for Mission Control."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, kanban, mission-control, bridge, task-management]
    related_skills: [hermes-agent]
---

## When to Use

Use when the Mission Control bridge needs to list/create/update kanban tasks via Hermes CLI (`hermes kanban --board default list --json`, `create --json`, `update`). Trigger: "kanban list --json", "kanban create --json".

# Kanban Skill — Wrapper para Bridge Mission Control

Skill que expõe comandos kanban que o bridge (`hermes-bridge/bridge.mjs`) usa para espelhar tarefas no Postgres (`HermesTask`).

## Comandos que o Bridge Usa

```bash
# Listar tarefas (JSON para parsing)
hermes kanban --board default list --json

# Criar tarefa (retorna JSON com id)
hermes kanban --board default create --json "Título da tarefa"

# Atualizar tarefa
hermes kanban --board default update <id> --status done --result "Concluído"
```

## Formato JSON Esperado (list)

```json
[
  {
    "id": "task-uuid",
    "title": "Título",
    "assignee": "hermes",
    "status": "todo|ready|running|blocked|review|done",
    "priority": 10,
    "result": "resultado se done",
    "updated_at": "2026-10-31T12:00:00Z"
  }
]
```

## Formato JSON Esperado (create)

```json
{
  "id": "new-task-uuid",
  "title": "Título da tarefa",
  "status": "todo",
  "assignee": "hermes"
}
```

## Side-Effecting → Approval Inbox

Tarefas criadas via dashboard que têm `sideEffecting: true` chegam como `AgentRequest` com `status: "awaiting_approval"`. O bridge **não executa** — aguarda aprovação humana no dashboard. Após aprovação, status vira `approved` e o bridge executa.

## Uso Direto

```bash
hermes chat -q "kanban list --json"
hermes chat -q "kanban create --json 'Nova tarefa do dashboard'"
```

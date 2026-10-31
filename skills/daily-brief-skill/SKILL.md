---
name: daily-brief-skill
description: "Generate structured daily brief for Mission Control."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, daily-brief, mission-control, chief-of-staff, briefing]
    related_skills: [wiki-skill, kanban-skill, cron-skill, memory-manager]
---

## When to Use

Use when the Mission Control bridge needs to generate the Chief-of-Staff daily brief (JSON with greeting, summary, sections: Needs your decision, Top priorities, Recently shipped, Next actions) at BRIEF_HOUR or on demand. Trigger: "daily brief", "briefing generate".

# Daily Brief Skill — Chief-of-Staff Briefing Estruturado

Skill para gerar o **Daily Brief** estruturado que o bridge executa automaticamente às `BRIEF_HOUR` (default 8h) e armazena no Postgres (`Brief` model) para o dashboard Cockpit.

## Prompt do Bridge (BRIEF_PROMPT)

```text
You are the operator's chief of staff. Produce today's brief. Read your memory wiki open-loops (~/.hermes/wiki), the kanban board, and recent activity. Output ONLY valid JSON (no prose, no code fences) in exactly this shape:
{"greeting":"one warm line","summary":"2-3 sentences on where things stand",
"sections":[{"label":"Needs your decision","items":["..."]},{"label":"Top priorities","items":["..."]},
{"label":"Recently shipped","items":["..."]},{"label":"Next actions","items":["..."]}]}.
Keep every item short, concrete, and specific. Omit a section if it has nothing.
```

## Formato de Saída (JSON Obrigatório)

```json
{
  "greeting": "Bom dia, senhor. Sistema operacional.",
  "summary": "Três tarefas críticas pendentes. Voz restaurada. Bridge sincronizando.",
  "sections": [
    {
      "label": "Needs your decision",
      "items": [
        "Aprovar deploy do Mission Control para produção",
        "Definir provedor de visão (OpenRouter vs Google AI)"
      ]
    },
    {
      "label": "Top priorities",
      "items": [
        "Finalizar skills do Mission Control (wiki, service-status, kanban, cron)",
        "Configurar bridge como systemd service com heartbeat",
        "Validar Daily Brief automático às 08h"
      ]
    },
    {
      "label": "Recently shipped",
      "items": [
        "VoiceStudio server rodando na porta 3900 (RTX 2060)",
        "TTS testado com voz Mordomo",
        "STT validado com faster-whisper base (pt-BR)",
        "Wiki-skill criada para sync HermesMemory"
      ]
    },
    {
      "label": "Next actions",
      "items": [
        "Criar service-status-skill",
        "Criar kanban-skill e cron-skill",
        "Configurar systemd para bridge",
        "Push para GitHub backup"
      ]
    }
  ]
}
```

## Fontes de Dados

1. **Memory Wiki** (`~/.hermes/wiki/open-loops/`) — pendências em aberto
2. **Kanban Board** (`hermes kanban list --json`) — tarefas atuais
3. **AgentEvent** (Postgres) — atividade recente (últimas 24h)
4. **HermesMemory** — fatos e decisões recentes

## Agendamento

- **Bridge**: roda `hermes chat -q "briefing generate"` às `BRIEF_HOUR`
- **Cron alternativo**: `hermes cron create "0 8 * * *" "briefing generate" --name daily-brief`
- **Manual**: `hermes chat -q "daily brief"`

## Armazenamento

Resultado salvo em `Brief` model no Postgres com `created_at` do dia. Dashboard lê o último `Brief` para o Cockpit.

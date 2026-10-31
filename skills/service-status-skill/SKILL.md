---
name: service-status-skill
description: "Report Hermes services status for Mission Control."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, services, status, mission-control, monitoring]
    related_skills: [hermes-agent, voice-studio-setup]
---

## When to Use

Use when the Mission Control dashboard needs a consolidated status of all internal Hermes services (VoiceStudio TTS/STT, Gateway, Bridge, Kanban, Cron, Memory Wiki, Sub-agents). Trigger: "service status", "service status --json".

# Service Status Skill — Status de Serviços Internos

Skill para reportar status dos serviços internos do Hermes que o Mission Control precisa monitorar via painel de serviços.

## Serviços Monitorados

| Serviço | Verificação | Health Endpoint |
|---------|-------------|-----------------|
| **VoiceStudio TTS** | `curl http://127.0.0.1:3900/health` | `/health`, `/setup/status` |
| **VoiceStudio STT** | faster-whisper local (base, pt-BR) | via VoiceStudio `/transcribe` |
| **Hermes Gateway** | Process running, WebSocket ativo | `/health` (se API server enabled) |
| **Bridge Mission Control** | `node bridge.mjs` rodando, heartbeat | `AgentEvent` kind=status no Postgres |
| **Kanban Sync** | `hermes kanban list --json` responde | `HermesTask` synced_at recente |
| **Cron Sync** | `hermes cron list` responde | `DataStore` key=cron_health |
| **Memory Wiki** | `~/.hermes/wiki/` acessível, git ok | `HermesMemory` synced_at recente |
| **Sub-agentes/Bots** | Profiles em `data/profiles/*/` | `AgentState` status=online |

## Formato de Saída (JSON)

```json
{
  "timestamp": "2026-10-31T12:00:00Z",
  "services": [
    {
      "name": "voicestudio-tts",
      "display": "VoiceStudio TTS",
      "status": "healthy",
      "endpoint": "http://127.0.0.1:3900",
      "device": "cuda (RTX 2060)",
      "details": {"models_ready": true, "vram_gb": 6}
    },
    {
      "name": "voicestudio-stt",
      "display": "VoiceStudio STT (faster-whisper)",
      "status": "healthy",
      "model": "base",
      "language": "pt-BR",
      "device": "cpu"
    },
    {
      "name": "hermes-gateway",
      "display": "Hermes Gateway",
      "status": "healthy",
      "pid": 12345,
      "uptime_s": 3600
    },
    {
      "name": "mission-control-bridge",
      "display": "Mission Control Bridge",
      "status": "healthy",
      "last_heartbeat": "2026-10-31T11:59:45Z",
      "board": "default"
    }
  ],
  "summary": {"healthy": 4, "degraded": 0, "down": 0}
}
```

## Uso

```bash
hermes chat -q "service status"
hermes chat -q "service status --json"
```

## Integração Bridge

O bridge pode chamar `hermes chat -q "service status --json"` periodicamente e armazenar em `DataStore` key=`service_status` para o dashboard ler.

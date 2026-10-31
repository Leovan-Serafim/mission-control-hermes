---
name: mission-control-onboarding-skill
description: "Onboard Hermes for Mission Control using ONBOARDING.md."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, onboarding, mission-control, bridge, setup]
    related_skills: [hermes-agent, wiki-skill, service-status-skill, kanban-skill, cron-skill, daily-brief-skill]
---

## When to Use

Use when setting up a new Hermes profile for Mission Control integration — extends the Hermy HQ ONBOARDING.md with bridge config, systemd service, skills, env vars, and validation checklist. Trigger: "mission control onboard", "setup mission control".

# Mission Control Onboarding Skill

Skill que estende o `ONBOARDING.md` do Hermy HQ para configurar o Hermes CLI com todos os módulos do Mission Control.

## ONBOARDING.md Original (Hermy HQ)

O repositório `sharbelxyz/hermes-agent-mission-control` contém `ONBOARDING.md` que guia:
1. Pré-requisitos (Node 20+, Postgres, Vercel, Google OAuth, Hermes CLI)
2. Clone + `npm install`
3. `.env` com segredos (DATABASE_URL, NEXTAUTH_SECRET, GOOGLE_*, ALLOWED_EMAILS)
4. Prisma migrate + seed
5. Deploy Vercel
6. Bridge setup (npm install, test run, launchd/systemd)

## Extensões para Novos Módulos

### 1. Skills Mission Control
```bash
# Skills já criadas automaticamente:
- wiki-skill
- service-status-skill
- kanban-skill
- cron-skill
- daily-brief-skill
```

### 2. Configuração Bridge (config.yaml local)
```yaml
# Adicionar ao config.yaml do perfil Hermes:
hermes_bridge:
  database_url: "${DATABASE_URL}"        # Mesmo do dashboard
  board: "default"
  poll_ms: 5000
  mirror_ms: 30000
  run_timeout_ms: 240000
  wiki_path: "~/.hermes/wiki"
  brief_hour: 8
  internal_api_secret: "${INTERNAL_API_SECRET}"
```

### 3. Variáveis de Ambiente (.env do perfil)
```bash
# No perfil Hermes (data/profiles/hermes/.env):
DATABASE_URL=postgresql://...
INTERNAL_API_SECRET=openssl rand -hex 32
HERMES_BOARD=default
HERMES_WIKI=~/.hermes/wiki
BRIEF_HOUR=8
```

### 4. Systemd Service (Linux) / Launchd (macOS)
```ini
# /etc/systemd/system/hermes-bridge.service
[Unit]
Description=Hermy HQ Bridge
After=network.target

[Service]
Type=simple
User=hermes
WorkingDirectory=/path/to/hermy-hq/hermes-bridge
Environment=DATABASE_URL=postgresql://...
Environment=HERMES_BOARD=default
Environment=HERMES_WIKI=/home/hermes/.hermes/wiki
Environment=BRIEF_HOUR=8
ExecStart=/usr/bin/node bridge.mjs
Restart=always
RestartSec=10
StandardOutput=append:/var/log/hermes-bridge.log
StandardError=append:/var/log/hermes-bridge.err.log

[Install]
WantedBy=multi-user.target
```

### 5. Validação Pós-Instalação

```bash
# 1. Bridge conecta
DATABASE_URL=... node bridge.mjs  # deve logar "hermes-bridge up"

# 2. Kanban sync
hermes kanban --board default list --json

# 3. Cron sync
hermes cron list --json

# 4. Service status
hermes chat -q "service status --json"

# 5. Daily brief test
hermes chat -q "briefing generate"

# 6. Dashboard: verificar Cockpit, /hermes, Memory Wiki
```

## Checklist de Entrega

- [ ] Dashboard deployado na Vercel
- [ ] Postgres acessível (mesmo DATABASE_URL)
- [ ] Bridge rodando como service (systemd/launchd)
- [ ] Heartbeat visível no dashboard (AgentEvent kind=status)
- [ ] Kanban sincronizado (HermesTask)
- [ ] Cron sincronizado (DataStore)
- [ ] Memory Wiki sincronizada (HermesMemory)
- [ ] Service status painel funcional
- [ ] Daily Brief gerando às 08h
- [ ] Approval Inbox funcionando (side-effecting → awaiting_approval)
- [ ] Skills carregadas no perfil Hermes

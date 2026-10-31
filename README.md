# Mission Control Hermes — Setup Completo

Este repositório contém toda a configuração necessária para integrar o **Hermes Agent** com o **Hermy HQ Mission Control** (dashboard Next.js na Vercel + bridge local).

## Arquitetura

```
┌─────────────────────────┐     ┌──────────────────────────┐     ┌─────────────────────┐
│   Hermy HQ (Vercel)     │────▶│   PostgreSQL (Message    │◀───│   Bridge Local      │
│   Next.js Dashboard     │     │   Bus: AgentRequest,     │     │   (hermes-bridge)   │
│                         │     │   AgentEvent,            │     │                     │
│   • Cockpit             │     │   HermesTask,            │     │   • Poll Postgres   │
│   • /hermes (dispatch)  │     │   HermesMemory,          │     │   • Run hermes CLI  │
│   • Memory Wiki         │     │   DataStore, Brief...    │     │   • Mirror state    │
│   • Content OS          │     │                          │     │   • Heartbeat       │
│   • Client Pulse        │     │                          │     │                     │
└─────────────────────────┘     └──────────────────────────┘     └─────────────────────┘
                                                                          │
                                                                          ▼
                                                                ┌─────────────────────┐
                                                                │   Hermes CLI Local  │
                                                                │                     │
                                                                │   • Kanban          │
                                                                │   • Cron            │
                                                                │   • Memory Wiki     │
                                                                │   • Service Status  │
                                                                │   • Daily Brief     │
                                                                │   • Voice (STT/TTS) │
                                                                │   • Vision (opt)    │
                                                                └─────────────────────┘
```

## Pré-requisitos

- **Hermes Agent** instalado e funcional (`hermes` no PATH)
- **Node.js 20+** para o bridge
- **PostgreSQL** (Neon, Supabase, Prisma Postgres, Vercel Postgres)
- **VoiceStudio** rodando na porta 3900 (TTS/STT local)
- **NSSM** (Non-Sucking Service Manager) para instalar bridge como serviço Windows

## Estrutura do Repositório

```
mission-control-hermes/
├── bridge-config.yaml          # Configuração do bridge (variáveis de ambiente)
├── install-bridge-service.bat  # Instalador Windows (batch + NSSM)
├── Install-BridgeService.ps1   # Instalador Windows (PowerShell + NSSM)
├── bridge-health-check.mjs     # Health check reporter (emite AgentEvent)
├── skills/
│   ├── wiki-skill/             # Read/write Hermes memory wiki
│   ├── service-status-skill/   # Status de serviços (VoiceStudio, Gateway, Bridge, etc.)
│   ├── kanban-skill/           # Wrapper kanban CLI para bridge
│   ├── cron-skill/             # Wrapper cron CLI para bridge
│   ├── daily-brief-skill/      # Chief-of-Staff daily brief estruturado
│   └── mission-control-onboarding-skill/  # Onboarding estendido
├── config/
│   └── hermes-profile.yaml     # Config.yaml do perfil Hermes para Mission Control
└── docs/
    ├── BRIDGE_SETUP.md         # Setup detalhado do bridge
    ├── SKILLS_REFERENCE.md     # Referência das skills
    └── TROUBLESHOOTING.md      # Problemas comuns
```

## Instalação Rápida

### 1. Clone e configure o Hermy HQ (Dashboard)

```bash
git clone https://github.com/sharbelxyz/hermes-agent-mission-control.git hermy-hq
cd hermy-hq
npm install
cp .env.example .env
# Edite .env com seus segredos (DATABASE_URL, NEXTAUTH_SECRET, GOOGLE_*, ALLOWED_EMAILS)
npx prisma migrate deploy
npx prisma db seed
# Deploy na Vercel
vercel --prod
```

### 2. Configure o Hermes Local (esta máquina)

```bash
# Copie as skills para o perfil Hermes
mkdir -p ~/.hermes/skills/
cp -r skills/* ~/.hermes/skills/

# Crie/atualize o perfil Mission Control
mkdir -p ~/.hermes/profiles/mission-control/
cp config/hermes-profile.yaml ~/.hermes/profiles/mission-control/config.yaml
# Edite com suas credenciais
```

### 3. Configure variáveis de ambiente do perfil

```bash
cat > ~/.hermes/profiles/mission-control/.env << 'EOF'
NVIDIA_API_KEY=nvapi-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DATABASE_URL=postgresql://user:pass@host:5432/db?sslmode=require
INTERNAL_API_SECRET=openssl rand -hex 32
HERMES_BOARD=default
HERMES_WIKI=~/.hermes/wiki
BRIEF_HOUR=8
EOF
```

### 4. Inicie VoiceStudio (porta 3900)

```bash
# Docker (recomendado)
docker run -d --name voicestudio -p 3900:3900 --gpus all \
  -v ~/.hermes/plugin-data/voicestudio:/app/data \
  debpalash/voicestudio:latest --fp16 --device cuda

# Verificar
curl http://127.0.0.1:3900/health
# {"status":"ok","device":"cuda (NVIDIA GeForce RTX 2060)","version":"0.5.6"}
```

### 5. Instale Bridge como Serviço Windows

```powershell
# Como Administrator
cd path\to\mission-control-hermes
.\Install-BridgeService.ps1 \
  -DatabaseUrl "postgresql://user:pass@host:5432/db?sslmode=require" \
  -InternalApiSecret "seu-secret-32-bytes-hex" \
  -BridgeDir "C:\path\to\hermy-hq\hermes-bridge"

# Ou use o .bat
.\install-bridge-service.bat
# Depois edite o registro: HKLM\SYSTEM\CurrentControlSet\Services\HermyHQBridge\Parameters\AppEnvironment
# DATABASE_URL e INTERNAL_API_SECRET
```

### 6. Valide a Integração

```bash
# Testar kanban sync
hermes kanban --board default list --json

# Testar cron sync
hermes cron list --json

# Testar service status
hermes chat -q "service status --json"

# Testar daily brief
hermes chat -q "briefing generate"

# Testar health check
node bridge-health-check.mjs

# Verificar bridge rodando
net start HermyHQBridge
# Ver logs
type C:\logs\hermes-bridge.out.log
```

### 7. Verifique no Dashboard

1. Acesse o Hermy HQ na Vercel
2. Vá em **Cockpit** → veja Daily Brief
3. Vá em **/hermes** → Dispatch, Approval Inbox, Activity Feed
4. Vá em **Memory Wiki** → veja sincronização
5. Verifique se **AgentEvent** kind=status aparece (heartbeat do bridge)

## Skills Disponíveis

| Skill | Trigger | Descrição |
|-------|---------|-----------|
| `wiki-skill` | "wiki read", "wiki write", "wiki list", "wiki commit" | Hermes memory wiki sync |
| `service-status-skill` | "service status", "service status --json" | Painel de serviços |
| `kanban-skill` | "kanban list --json", "kanban create --json" | Bridge kanban sync |
| `cron-skill` | "cron list --json", "cron create", "cron run" | Bridge cron sync |
| `daily-brief-skill` | "daily brief", "briefing generate" | Chief-of-Staff briefing |
| `mission-control-onboarding-skill` | "mission control onboard", "setup mission control" | Setup completo |

## Variáveis de Ambiente Críticas

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `DATABASE_URL` | ✅ | Postgres direto (não prisma://) |
| `INTERNAL_API_SECRET` | ✅ | `openssl rand -hex 32` |
| `NVIDIA_API_KEY` | ✅ | Para modelo Nemotron |
| `HERMES_BOARD` | ⭕ | Default: "default" |
| `HERMES_WIKI` | ⭕ | Default: ~/.hermes/wiki |
| `BRIEF_HOUR` | ⭕ | Default: 8 (hora local) |
| `BRIDGE_POLL_MS` | ⭕ | Default: 5000 |
| `BRIDGE_MIRROR_MS` | ⭕ | Default: 30000 |

## Troubleshooting

### Bridge não conecta no Postgres
- Verifique `DATABASE_URL` é string direta `postgresql://` (não `prisma://`)
- SSL: `sslmode=require` para cloud, remova para local
- Firewall/segurança: porta 5432 aberta

### Kanban/Cron não sincroniza
- `hermes kanban list --json` funciona standalone?
- `hermes cron list --json` funciona standalone?
- Verifique `HERMES_BOARD` corresponde ao dashboard

### VoiceStudio não responde
- `curl http://127.0.0.1:3900/health` → deve retornar 200
- GPU: RTX 2060 6GB precisa `--fp16 --device cuda` (~2.5GB VRAM)
- Docker: `--gpus all` + NVIDIA Container Toolkit

### Service Status mostra "down"
- `hermes chat -q "service status --json"` para debug
- Verifique cada serviço individualmente

## Backup no GitHub

```bash
git init
git add .
git commit -m "Mission Control Hermes: skills, bridge config, Windows service setup"
git remote add origin https://github.com/SEU_USUARIO/mission-control-hermes.git
git push -u origin main
```

## Referências

- Hermy HQ: https://github.com/sharbelxyz/hermes-agent-mission-control
- Hermes Agent: https://hermes-agent.nousresearch.com/docs
- VoiceStudio: https://github.com/debpalash/VoiceStudio
- NSSM: https://nssm.cc/
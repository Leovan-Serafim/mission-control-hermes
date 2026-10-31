<#>
.SYNOPSIS
    Hermy HQ Bridge — Instalador de Serviço Windows (PowerShell + NSSM)
.DESCRIPTION
    Instala o bridge.mjs como serviço Windows usando NSSM.
    Requer: NSSM no PATH, Node.js, bridge.mjs clonado.
.NOTES
    Execute como Administrator.
#>

param(
    [string]$BridgeDir = "$PSScriptRoot\hermes-bridge",
    [string]$ServiceName = "HermyHQBridge",
    [string]$DisplayName = "Hermy HQ Mission Control Bridge",
    [string]$Description = "Bridge between Hermy HQ dashboard (Vercel) and local Hermes agent via shared Postgres",
    [string]$DatabaseUrl = "postgresql://user:pass@host:5432/db?sslmode=require",
    [string]$InternalApiSecret = "your-32-byte-hex-secret-here",
    [string]$HermesBoard = "default",
    [int]$PollMs = 5000,
    [int]$MirrorMs = 30000,
    [int]$RunTimeoutMs = 240000,
    [string]$HermesWiki = "$env:USERPROFILE\.hermes\wiki",
    [int]$BriefHour = 8,
    [string]$LogDir = "C:\logs"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Hermy HQ Bridge - Windows Service Installer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se é Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "ERRO: Execute como Administrator"
    exit 1
}

# Verificar NSSM
$nssm = Get-Command nssm.exe -ErrorAction SilentlyContinue
if (-not $nssm) {
    Write-Error "ERRO: NSSM nao encontrado no PATH. Baixe em https://nssm.cc/download"
    exit 1
}

# Verificar Node.js
$node = Get-Command node.exe -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Error "ERRO: Node.js nao encontrado no PATH"
    exit 1
}

# Verificar bridge.mjs
if (-not (Test-Path "$BridgeDir\bridge.mjs")) {
    Write-Error "ERRO: bridge.mjs nao encontrado em $BridgeDir"
    exit 1
}

Write-Host "Diretorio do bridge: $BridgeDir" -ForegroundColor Green
Write-Host "Node.js: $($node.Source)" -ForegroundColor Green
Write-Host "NSSM: $($nssm.Source)" -ForegroundColor Green
Write-Host ""

# Criar diretorio de logs
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    Write-Host "Diretorio de logs criado: $LogDir" -ForegroundColor Green
}

# Instalar servico
Write-Host "Instalando servico '$ServiceName'..." -ForegroundColor Yellow
& $nssm install $ServiceName $node.Source "`"$BridgeDir\bridge.mjs`""

# Configurar
& $nssm set $ServiceName AppDirectory $BridgeDir
& $nssm set $ServiceName AppParameters "bridge.mjs"
& $nssm set $ServiceName AppEnvironmentExtra "DATABASE_URL=$DatabaseUrl"
& $nssm set $ServiceName AppEnvironmentExtra "HERMES_BOARD=$HermesBoard"
& $nssm set $ServiceName AppEnvironmentExtra "BRIDGE_POLL_MS=$PollMs"
& $nssm set $ServiceName AppEnvironmentExtra "BRIDGE_MIRROR_MS=$MirrorMs"
& $nssm set $ServiceName AppEnvironmentExtra "BRIDGE_RUN_TIMEOUT_MS=$RunTimeoutMs"
& $nssm set $ServiceName AppEnvironmentExtra "HERMES_WIKI=$HermesWiki"
& $nssm set $ServiceName AppEnvironmentExtra "BRIEF_HOUR=$BriefHour"
& $nssm set $ServiceName AppEnvironmentExtra "INTERNAL_API_SECRET=$InternalApiSecret"

# Auto-start
& $nssm set $ServiceName Start SERVICE_AUTO_START
& $nssm set $ServiceName RestartDelay 10000

# Logs
& $nssm set $ServiceName Stdout "$LogDir\hermes-bridge.out.log"
& $nssm set $ServiceName Stderr "$LogDir\hermes-bridge.err.log"
& $nssm set $ServiceName RotateStdout 1
& $nssm set $ServiceName RotateStderr 1
& $nssm set $ServiceName RotateFiles 5
& $nssm set $ServiceName RotateBytesLow 10485760

# Descrição
& $nssm set $ServiceName Description $Description

Write-Host ""
Write-Host "Servico instalado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Comandos uteis:" -ForegroundColor Cyan
Write-Host "  Iniciar:   net start $ServiceName"
Write-Host "  Parar:     net stop $ServiceName"
Write-Host "  Status:    sc query $ServiceName"
Write-Host "  Remover:   nssm remove $ServiceName confirm"
Write-Host ""
Write-Host "Logs em: $LogDir\hermes-bridge.out.log / .err.log" -ForegroundColor Cyan
Write-Host ""
Write-Warning "IMPORTANTE: Edite as variaveis reais no Registro:"
Write-Warning "  regedit -> HKLM\SYSTEM\CurrentControlSet\Services\$ServiceName\Parameters\AppEnvironment"
Write-Warning "  Principalmente: DATABASE_URL, INTERNAL_API_SECRET"
Write-Host ""

# Oferecer iniciar
$start = Read-Host "Iniciar servico agora? (s/N)"
if ($start -eq 's' -or $start -eq 'S') {
    Write-Host "Iniciando servico..."
    net start $ServiceName
    Start-Sleep 3
    $status = (Get-Service $ServiceName).Status
    Write-Host "Status: $status"
}
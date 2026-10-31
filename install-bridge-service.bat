@echo off
REM Hermy HQ Bridge — Instalador de Serviço Windows (NSSM)
REM Requer: NSSM (https://nssm.cc/download) no PATH ou em %NSSM_PATH%
REM Execute como Administrator

set BRIDGE_DIR=%~dp0hermes-bridge
set NSSM=nssm.exe
set SERVICE_NAME=HermyHQBridge
set DISPLAY_NAME="Hermy HQ Mission Control Bridge"
set DESCRIPTION="Bridge between Hermy HQ dashboard (Vercel) and local Hermes agent via shared Postgres"

echo ============================================
echo Hermy HQ Bridge - Windows Service Installer
echo ============================================
echo.

REM Verificar NSSM
where %NSSM% >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: NSSM nao encontrado no PATH.
    echo Baixe em: https://nssm.cc/download
    echo Extraia nssm.exe para uma pasta no PATH (ex: C:\Windows)
    pause
    exit /b 1
)

REM Verificar Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: Node.js nao encontrado no PATH.
    pause
    exit /b 1
)

REM Verificar bridge.mjs
if not exist "%BRIDGE_DIR%\bridge.mjs" (
    echo ERRO: bridge.mjs nao encontrado em %BRIDGE_DIR%
    echo Certifique-se de que o repositorio hermy-hq foi clonado aqui.
    pause
    exit /b 1
)

echo Diretorio do bridge: %BRIDGE_DIR%
echo.

REM Ler variáveis do bridge-config.yaml (ou .env)
echo Carregando variaveis de ambiente...
if exist "%BRIDGE_DIR%\.env" (
    echo Usando .env do diretorio do bridge
) else if exist "%~dp0bridge-config.yaml" (
    echo AVISO: bridge-config.yaml encontrado mas .env e recomendado para segredos
) else (
    echo AVISO: Nenhum arquivo de configuracao encontrado (.env ou bridge-config.yaml)
)

REM Instalar servico
echo.
echo Instalando servico '%SERVICE_NAME%'...
%NSSM% install %SERVICE_NAME% node.exe "%BRIDGE_DIR%\bridge.mjs"

REM Configurar variáveis de ambiente do serviço
echo Configurando variaveis de ambiente...
%NSSM% set %SERVICE_NAME% AppDirectory "%BRIDGE_DIR%"
%NSSM% set %SERVICE_NAME% AppParameters "bridge.mjs"
%NSSM% set %SERVICE_NAME% AppEnvironmentExtra "DATABASE_URL=postgresql://user:pass@host:5432/db?sslmode=require"
%NSSM% set %SERVICE_NAME% AppEnvironmentExtra "HERMES_BOARD=default"
%NSSM% set %SERVICE_NAME% AppEnvironmentExtra "BRIDGE_POLL_MS=5000"
%NSSM% set %SERVICE_NAME% AppEnvironmentExtra "BRIDGE_MIRROR_MS=30000"
%NSSM% set %SERVICE_NAME% AppEnvironmentExtra "BRIDGE_RUN_TIMEOUT_MS=240000"
%NSSM% set %SERVICE_NAME% AppEnvironmentExtra "HERMES_WIKI=%USERPROFILE%\.hermes\wiki"
%NSSM% set %SERVICE_NAME% AppEnvironmentExtra "BRIEF_HOUR=8"
%NSSM% set %SERVICE_NAME% AppEnvironmentExtra "INTERNAL_API_SECRET=your-32-byte-hex-secret-here"

REM Configurar restart automático
%NSSM% set %SERVICE_NAME% Start SERVICE_AUTO_START
%NSSM% set %SERVICE_NAME% RestartDelay 10000

REM Configurar logs
%NSSM% set %SERVICE_NAME% Stdout "C:\logs\hermes-bridge.out.log"
%NSSM% set %SERVICE_NAME% Stderr "C:\logs\hermes-bridge.err.log"
%NSSM% set %SERVICE_NAME% RotateStdout 1
%NSSM% set %SERVICE_NAME% RotateStderr 1
%NSSM% set %SERVICE_NAME% RotateFiles 5
%NSSM% set %SERVICE_NAME% RotateBytesLow 10485760

REM Descrição
%NSSM% set %SERVICE_NAME% Description "%DESCRIPTION%"

echo.
echo Servico instalado com sucesso!
echo.
echo Para INICIAR:   net start %SERVICE_NAME%
echo Para PARAR:     net stop %SERVICE_NAME%
echo Para REMOVER:   %NSSM% remove %SERVICE_NAME% confirm
echo.
echo Logs em: C:\logs\hermes-bridge.out.log / .err.log
echo.
echo IMPORTANTE: Edite as variaveis de ambiente reais no registro:
echo   regedit -> HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%SERVICE_NAME%\Parameters\AppEnvironment
echo   Principalmente: DATABASE_URL, INTERNAL_API_SECRET
echo.
pause
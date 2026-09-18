#Requires -Version 5.1
<#
.SYNOPSIS
  Non-interactive tunnel profile init using secrets under %APPDATA%.
#>
$ErrorActionPreference = 'Stop'

$UserHome = $env:USERPROFILE
$InstallDir = Join-Path $UserHome 'chatgpt-sol-local-bridge'
$SecretsDir = Join-Path $env:APPDATA 'chatgpt-sol-local-bridge'
$ToolsDir = Join-Path $UserHome 'tools\tunnel-client'
$Exe = Join-Path $ToolsDir 'tunnel-client.exe'
$ProfileName = 'sol-local-bridge'
$McpUrl = 'http://127.0.0.1:8765/mcp'
$HealthAddr = '127.0.0.1:8766'

if (-not (Test-Path $Exe)) { throw "Missing $Exe — run Install-Bridge.ps1 first" }
$TunnelId = (Get-Content (Join-Path $SecretsDir 'tunnel-id') -Raw).Trim()
$ApiKey = (Get-Content (Join-Path $SecretsDir 'runtime-api-key') -Raw).Trim()
if ($TunnelId -notmatch '^tunnel_') { throw 'tunnel-id file must start with tunnel_' }
if (-not $ApiKey) { throw 'runtime-api-key is empty' }

$env:CONTROL_PLANE_API_KEY = $ApiKey
$env:CONTROL_PLANE_TUNNEL_ID = $TunnelId
$env:Path = "$ToolsDir;$env:Path"

# Prefer upstream helper if present
$helper = Join-Path $InstallDir 'scripts\windows\configure-tunnel.ps1'
if (Test-Path $helper) {
  & $helper
} else {
  & $Exe init --force --sample sample_mcp_remote_no_auth --profile $ProfileName --tunnel-id $TunnelId --health-listen-addr $HealthAddr --mcp-server-url $McpUrl
}

# Write runtime.env (local only) without echoing secrets
$Projects = Join-Path $UserHome 'projects'
$Docs = Join-Path $UserHome 'Documents'
$Runtime = Join-Path $SecretsDir 'runtime.env'
@"
HOST=127.0.0.1
PORT=8765
WORKSPACE_ROOTS=$Projects;$Docs
DEFAULT_WORKSPACE=$Projects
ALLOW_TOOL_ROOT_REGISTRATION=false
INCLUDE_COMMON_WORKSPACE_ROOTS=false
DESTRUCTIVE_APPROVAL_MODE=chat
ALLOW_PRIVATE_NETWORK=false
CONTROL_PLANE_TUNNEL_ID=$TunnelId
CONTROL_PLANE_API_KEY=$ApiKey
TUNNEL_PROFILE=$ProfileName
TUNNEL_HEALTH_PORT=8766
"@ | Set-Content -Path $Runtime -Encoding utf8

$me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
icacls $Runtime /inheritance:r | Out-Null
icacls $Runtime /grant:r "${me}:F" | Out-Null

& $Exe doctor --profile $ProfileName --explain

Remove-Item Env:CONTROL_PLANE_API_KEY -ErrorAction SilentlyContinue
Remove-Item Env:CONTROL_PLANE_TUNNEL_ID -ErrorAction SilentlyContinue
$ApiKey = $null
Write-Host "CONFIGURE_OK profile=$ProfileName runtime=$Runtime"

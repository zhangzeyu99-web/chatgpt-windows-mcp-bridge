#Requires -Version 5.1
<#
.SYNOPSIS
  Clone upstream MCP bridge, install deps, download tunnel-client, write base .env.
.NOTES
  Secrets are NOT written here. Put tunnel-id + runtime-api-key under %APPDATA%\chatgpt-sol-local-bridge\ first.
#>
$ErrorActionPreference = 'Stop'

$UserHome = $env:USERPROFILE
$InstallDir = Join-Path $UserHome 'chatgpt-sol-local-bridge'
$SecretsDir = Join-Path $env:APPDATA 'chatgpt-sol-local-bridge'
$ToolsDir = Join-Path $UserHome 'tools\tunnel-client'
$Upstream = 'https://github.com/mingrath/chatgpt-sol-local-bridge.git'
$TunnelZipUrl = 'https://github.com/openai/tunnel-client/releases/download/v0.0.14/tunnel-client-v0.0.14-windows-amd64.zip'
$TunnelVersion = 'v0.0.14'

New-Item -ItemType Directory -Force -Path $SecretsDir, $ToolsDir | Out-Null

foreach ($name in @('tunnel-id','runtime-api-key')) {
  $p = Join-Path $SecretsDir $name
  if (-not (Test-Path $p)) {
    throw "Missing secret file: $p`nCreate it with the tunnel id / runtime API key (single line, no quotes)."
  }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is required' }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js 20+ is required' }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw 'npm is required' }

$nodeMajor = [int]((node -v) -replace '^v','').Split('.')[0]
if ($nodeMajor -lt 20) { throw "Node 20+ required, found $(node -v)" }

if (-not (Test-Path (Join-Path $InstallDir '.git'))) {
  if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
  git clone $Upstream $InstallDir
} else {
  Push-Location $InstallDir
  git fetch --tags origin
  git pull --ff-only origin main
  Pop-Location
}

Push-Location $InstallDir
try {
  if (Test-Path 'package-lock.json') { npm ci } else { npm install }
} finally { Pop-Location }

$Projects = Join-Path $UserHome 'projects'
$Docs = Join-Path $UserHome 'Documents'
if (-not (Test-Path $Projects)) { New-Item -ItemType Directory -Force -Path $Projects | Out-Null }
$Ws = $Projects

$EnvFile = Join-Path $InstallDir '.env'
@"
HOST=127.0.0.1
PORT=8765
WORKSPACE_ROOTS=$Projects;$Docs
DEFAULT_WORKSPACE=$Ws
ALLOW_TOOL_ROOT_REGISTRATION=false
INCLUDE_COMMON_WORKSPACE_ROOTS=false
DESTRUCTIVE_APPROVAL_MODE=chat
ALLOW_PRIVATE_NETWORK=false
TUNNEL_PROFILE=sol-local-bridge
TUNNEL_HEALTH_PORT=8766
"@ | Set-Content -Path $EnvFile -Encoding utf8

$exe = Join-Path $ToolsDir 'tunnel-client.exe'
if (-not (Test-Path $exe)) {
  $zip = Join-Path $env:TEMP "tunnel-client-$TunnelVersion-windows-amd64.zip"
  Write-Host "Downloading tunnel-client $TunnelVersion ..."
  Invoke-WebRequest -Uri $TunnelZipUrl -OutFile $zip
  Expand-Archive -Force -Path $zip -DestinationPath $ToolsDir
}

if (-not (Test-Path $exe)) {
  $found = Get-ChildItem -Path $ToolsDir -Recurse -Filter 'tunnel-client.exe' | Select-Object -First 1
  if (-not $found) { throw 'tunnel-client.exe not found after extract' }
  if ($found.DirectoryName -ne $ToolsDir) {
    Copy-Item -Force $found.FullName $exe
  }
}

& $exe --version

# tighten ACL on secrets
$me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
icacls $SecretsDir /inheritance:r | Out-Null
icacls $SecretsDir /grant:r "${me}:(OI)(CI)F" | Out-Null
foreach ($name in @('tunnel-id','runtime-api-key','runtime.env')) {
  $p = Join-Path $SecretsDir $name
  if (Test-Path $p) {
    icacls $p /inheritance:r | Out-Null
    icacls $p /grant:r "${me}:F" | Out-Null
  }
}

Write-Host "INSTALL_OK install=$InstallDir tools=$ToolsDir secrets=$SecretsDir"
Write-Host 'Next: Configure-Tunnel.ps1 then Start-Bridge.ps1'

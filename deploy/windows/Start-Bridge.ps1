#Requires -Version 5.1
<#
.SYNOPSIS
  Start MCP bridge + tunnel-client in background. Idempotent-ish: stops stale listeners first.
#>
$ErrorActionPreference = 'Stop'

$UserHome = $env:USERPROFILE
$InstallDir = Join-Path $UserHome 'chatgpt-sol-local-bridge'
$SecretsDir = Join-Path $env:APPDATA 'chatgpt-sol-local-bridge'
$ToolsDir = Join-Path $UserHome 'tools\tunnel-client'
$Exe = Join-Path $ToolsDir 'tunnel-client.exe'
$Node = (Get-Command node).Source
$LogDir = Join-Path $UserHome '.chatgpt-sol-local-bridge\logs'
$ProfileName = 'sol-local-bridge'

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$ApiKey = (Get-Content (Join-Path $SecretsDir 'runtime-api-key') -Raw).Trim()
$TunnelId = (Get-Content (Join-Path $SecretsDir 'tunnel-id') -Raw).Trim()
$env:CONTROL_PLANE_API_KEY = $ApiKey
$env:CONTROL_PLANE_TUNNEL_ID = $TunnelId
$env:Path = "$ToolsDir;$env:Path"

# stop previous
Get-Process tunnel-client -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -and ($_.CommandLine -match 'chatgpt-sol-local-bridge' -or $_.CommandLine -match 'src[\\/]server\.js') } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 1

$bridgeOut = Join-Path $LogDir 'bridge.out.log'
$bridgeErr = Join-Path $LogDir 'bridge.err.log'
$tunnelOut = Join-Path $LogDir 'tunnel.out.log'
$tunnelErr = Join-Path $LogDir 'tunnel.err.log'

$bridge = Start-Process -FilePath $Node -ArgumentList 'src/server.js' -WorkingDirectory $InstallDir -RedirectStandardOutput $bridgeOut -RedirectStandardError $bridgeErr -WindowStyle Hidden -PassThru
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
  Start-Sleep -Seconds 1
  try {
    $r = Invoke-WebRequest 'http://127.0.0.1:8765/readyz' -UseBasicParsing -TimeoutSec 2
    if ($r.StatusCode -eq 200) { $ready = $true; break }
  } catch {}
}
if (-not $ready) {
  if (Test-Path $bridgeErr) { Get-Content $bridgeErr -Tail 40 }
  throw 'MCP bridge failed to become ready on :8765'
}

$tunnel = Start-Process -FilePath $Exe -ArgumentList @('run','--profile',$ProfileName) -RedirectStandardOutput $tunnelOut -RedirectStandardError $tunnelErr -WindowStyle Hidden -PassThru
Start-Sleep -Seconds 5
try {
  $th = (Invoke-WebRequest 'http://127.0.0.1:8766/healthz' -UseBasicParsing -TimeoutSec 3).Content
  $tr = (Invoke-WebRequest 'http://127.0.0.1:8766/readyz' -UseBasicParsing -TimeoutSec 3).Content
  Write-Host "tunnel health=$th ready=$tr"
} catch {
  Write-Warning "tunnel health check failed: $_"
}

Write-Host "START_OK bridge_pid=$($bridge.Id) tunnel_pid=$($tunnel.Id) logs=$LogDir"

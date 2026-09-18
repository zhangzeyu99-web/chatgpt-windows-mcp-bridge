#Requires -Version 5.1
$ErrorActionPreference = 'Continue'
Write-Host '=== PROCESSES ==='
Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -and ($_.CommandLine -match 'chatgpt-sol-local-bridge' -or $_.CommandLine -match 'src[\\/]server\.js') } |
  ForEach-Object { Write-Host "bridge pid=$($_.ProcessId)" }
$tc = Get-Process tunnel-client -ErrorAction SilentlyContinue
if ($tc) { $tc | ForEach-Object { Write-Host "tunnel pid=$($_.Id)" } } else { Write-Host 'tunnel: not running' }
Write-Host '=== HTTP ==='
try { Write-Host ('bridge readyz=' + (Invoke-WebRequest 'http://127.0.0.1:8765/readyz' -UseBasicParsing -TimeoutSec 3).StatusCode) } catch { Write-Host "bridge FAIL: $($_.Exception.Message)" }
try { Write-Host ('tunnel health=' + (Invoke-WebRequest 'http://127.0.0.1:8766/healthz' -UseBasicParsing -TimeoutSec 3).Content) } catch { Write-Host "tunnel health FAIL" }
try { Write-Host ('tunnel ready=' + (Invoke-WebRequest 'http://127.0.0.1:8766/readyz' -UseBasicParsing -TimeoutSec 3).Content) } catch { Write-Host "tunnel ready FAIL" }

#Requires -Version 5.1
$ErrorActionPreference = 'Continue'
Get-Process tunnel-client -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -and ($_.CommandLine -match 'chatgpt-sol-local-bridge' -or $_.CommandLine -match 'src[\\/]server\.js') } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Write-Host 'STOP_OK'

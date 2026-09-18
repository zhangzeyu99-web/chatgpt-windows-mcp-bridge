#Requires -Version 5.1
<#
.SYNOPSIS
  Register a per-user Scheduled Task to start the bridge at logon.
#>
$ErrorActionPreference = 'Stop'
$Repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$StartScript = Join-Path $PSScriptRoot 'Start-Bridge.ps1'
if (-not (Test-Path $StartScript)) { throw "Missing $StartScript" }

$taskName = 'ChatGPT-Windows-MCP-Bridge'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$StartScript`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "AUTOSTART_OK task=$taskName"
Write-Host "To remove: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"

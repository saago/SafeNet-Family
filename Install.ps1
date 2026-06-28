<#
.SYNOPSIS
    Installs SafeNet-Family on this PC.
    1. Applies all filtering immediately.
    2. Creates a scheduled task (SYSTEM) that re-applies it at startup and every
       hour, so casual tampering is silently reverted.

.PARAMETER YouTubeMode
    Strict (default) or Moderate.

.PARAMETER LockDownDNS
    Pass this switch for the strongest (but stricter) DNS lockdown.

.EXAMPLE
    Right-click  ->  Run with PowerShell      (it will request Administrator)
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Install.ps1 -YouTubeMode Strict
#>

[CmdletBinding()]
param(
    [ValidateSet('Strict','Moderate')]
    [string]$YouTubeMode = 'Strict',
    [switch]$LockDownDNS
)

# --- Self-elevate to Administrator if needed ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",
                 '-YouTubeMode', $YouTubeMode)
    if ($LockDownDNS) { $argList += '-LockDownDNS' }
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList
    exit
}

$ErrorActionPreference = 'Stop'
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ApplyPath  = Join-Path $ScriptDir 'Apply-Filter.ps1'
$TaskName   = 'SafeNetFamily-Enforce'

if (-not (Test-Path $ApplyPath)) {
    Write-Error "Cannot find Apply-Filter.ps1 next to this installer ($ApplyPath)."
    exit 1
}

Write-Host "`n=== Installing SafeNet-Family ===" -ForegroundColor Cyan

# 1. Apply immediately.
$applyArgs = @{
    YouTubeMode = $YouTubeMode
}
if ($LockDownDNS) { $applyArgs['LockDownDNS'] = $true }
& $ApplyPath @applyArgs

# 2. Create / refresh the scheduled task.
$taskCmd = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ApplyPath`" -YouTubeMode $YouTubeMode"
if ($LockDownDNS) { $taskCmd += ' -LockDownDNS' }

$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $taskCmd

$trigAtStartup = New-ScheduledTaskTrigger -AtStartup
$trigHourly    = New-ScheduledTaskTrigger -Once -At (Get-Date) `
                    -RepetitionInterval (New-TimeSpan -Hours 1)

$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                -StartWhenAvailable -MultipleInstances IgnoreNew

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask -TaskName $TaskName `
    -Action $action `
    -Trigger @($trigAtStartup, $trigHourly) `
    -Principal $principal `
    -Settings $settings `
    -Description 'SafeNet-Family: re-applies adult-content filtering hourly and at startup.' | Out-Null

Write-Host "`nScheduled task '$TaskName' created (runs at startup + every hour as SYSTEM)." -ForegroundColor Green
Write-Host "=== SafeNet-Family installed. ===" -ForegroundColor Cyan
Write-Host "Tip: close and reopen all browsers so the new policies take effect." -ForegroundColor Yellow
Write-Host "`nVerify any time with:  powershell -ExecutionPolicy Bypass -File .\Status.ps1`n"

Read-Host "Press Enter to close"

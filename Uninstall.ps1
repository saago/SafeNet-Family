<#
.SYNOPSIS
    Removes SafeNet-Family and restores the PC to its previous state:
      - Restores the original DNS settings (from .\state\dns-backup.json).
      - Removes the managed hosts-file block.
      - Removes browser policies.
      - Removes firewall rules.
      - Removes the scheduled task.
#>

# --- Self-elevate ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs `
        -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
    exit
}

$ErrorActionPreference = 'Continue'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateDir  = Join-Path $ScriptDir 'state'
$TaskName  = 'SafeNetFamily-Enforce'
$FwGroup   = 'SafeNetFamily'
$HostsPath = Join-Path $env:WINDIR 'System32\drivers\etc\hosts'
$BeginMark = '# === SafeNetFamily BEGIN (managed block - do not edit) ==='
$EndMark   = '# === SafeNetFamily END ==='

Write-Host "`n=== Uninstalling SafeNet-Family ===" -ForegroundColor Cyan

# 1. Remove scheduled task.
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Removed scheduled task." -ForegroundColor Green

# 2. Restore DNS.
$DnsBackupFile = Join-Path $StateDir 'dns-backup.json'
if (Test-Path $DnsBackupFile) {
    $backup = Get-Content $DnsBackupFile -Raw | ConvertFrom-Json
    foreach ($entry in $backup) {
        try {
            if ($entry.Servers -and $entry.Servers.Count -gt 0) {
                Set-DnsClientServerAddress -InterfaceIndex $entry.ifIndex -ServerAddresses $entry.Servers -ErrorAction Stop
                Write-Host "Restored $($entry.AddressFamily) DNS on '$($entry.Name)' -> $($entry.Servers -join ', ')"
            } else {
                Set-DnsClientServerAddress -InterfaceIndex $entry.ifIndex -ResetServerAddresses -ErrorAction Stop
                Write-Host "Reset $($entry.AddressFamily) DNS on '$($entry.Name)' to automatic (DHCP)"
            }
        } catch {
            Write-Host "WARN: could not restore DNS on ifIndex $($entry.ifIndex): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "No DNS backup found - resetting all adapters to automatic (DHCP)." -ForegroundColor Yellow
    Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
}

# Re-enable Windows auto-DoH default.
Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' `
    -Name 'EnableAutoDoh' -ErrorAction SilentlyContinue

# 3. Remove managed hosts block.
if (Test-Path $HostsPath) {
    $raw = Get-Content $HostsPath -Raw
    $pattern = [regex]::Escape($BeginMark) + '.*?' + [regex]::Escape($EndMark)
    $raw = [regex]::Replace($raw, $pattern, '', 'Singleline').TrimEnd("`r","`n")
    Set-Content -Path $HostsPath -Value ($raw + "`r`n") -Encoding ASCII -Force
    Write-Host "Removed managed hosts block." -ForegroundColor Green
}

# 4. Remove browser policies.
$policyValues = @(
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge';            Names=@('ForceGoogleSafeSearch','ForceYouTubeRestrict','ForceBingSafeSearch','DnsOverHttpsMode','BuiltInDnsClientEnabled') },
    @{ Path='HKLM:\SOFTWARE\Policies\Google\Chrome';             Names=@('ForceGoogleSafeSearch','ForceYouTubeRestrict','DnsOverHttpsMode','BuiltInDnsClientEnabled') },
    @{ Path='HKLM:\SOFTWARE\Policies\BraveSoftware\Brave';       Names=@('ForceGoogleSafeSearch','ForceYouTubeRestrict','DnsOverHttpsMode','BuiltInDnsClientEnabled') },
    @{ Path='HKLM:\SOFTWARE\Policies\Chromium';                  Names=@('ForceGoogleSafeSearch','ForceYouTubeRestrict','DnsOverHttpsMode','BuiltInDnsClientEnabled') },
    @{ Path='HKLM:\SOFTWARE\Policies\Mozilla\Firefox\DNSOverHTTPS'; Names=@('Enabled','Locked') }
)
foreach ($p in $policyValues) {
    foreach ($n in $p.Names) {
        Remove-ItemProperty -Path $p.Path -Name $n -ErrorAction SilentlyContinue
    }
}
Write-Host "Removed browser policies." -ForegroundColor Green

# 5. Remove firewall rules.
Get-NetFirewallRule -Group $FwGroup -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
Write-Host "Removed firewall rules." -ForegroundColor Green

Clear-DnsClientCache -ErrorAction SilentlyContinue
Write-Host "`n=== SafeNet-Family fully removed. ===" -ForegroundColor Cyan
Read-Host "Press Enter to close"

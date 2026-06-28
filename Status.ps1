<#
.SYNOPSIS
    Shows whether SafeNet-Family protection is currently active.
    Safe to run any time (read-only). Does not require Administrator.
#>

$FwGroup   = 'SafeNetFamily'
$TaskName  = 'SafeNetFamily-Enforce'
$HostsPath = Join-Path $env:WINDIR 'System32\drivers\etc\hosts'

function Show-Check {
    param([string]$Label, [bool]$Ok, [string]$Detail = '')
    $mark  = if ($Ok) { '[ OK ]' } else { '[ -- ]' }
    $color = if ($Ok) { 'Green' } else { 'Red' }
    Write-Host ("{0,-7}{1}" -f $mark, $Label) -ForegroundColor $color
    if ($Detail) { Write-Host ("        {0}" -f $Detail) -ForegroundColor DarkGray }
}

Write-Host "`n=== SafeNet-Family status ===`n" -ForegroundColor Cyan

# DNS
$dnsOk = $false; $dnsDetail = @()
Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
    $s = (Get-DnsClientServerAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4).ServerAddresses
    if ($s) {
        $dnsDetail += "$($_.Name): $($s -join ', ')"
        if ($s -contains '1.1.1.3') { $dnsOk = $true }
    }
}
Show-Check "Filtering DNS (Cloudflare Families 1.1.1.3)" $dnsOk ($dnsDetail -join '  |  ')

# Hosts block
$hostsOk = (Test-Path $HostsPath) -and ((Get-Content $HostsPath -Raw) -match 'SafeNetFamily BEGIN')
Show-Check "Hosts file SafeSearch + blocklist" $hostsOk

# Browser policies
$edgeOk = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ForceGoogleSafeSearch' -ErrorAction SilentlyContinue).ForceGoogleSafeSearch -eq 1
$chromeOk = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Google\Chrome' -Name 'ForceGoogleSafeSearch' -ErrorAction SilentlyContinue).ForceGoogleSafeSearch -eq 1
Show-Check "Edge SafeSearch/DoH policy"   ([bool]$edgeOk)
Show-Check "Chrome SafeSearch/DoH policy" ([bool]$chromeOk)

# Firewall
$fwCount = (Get-NetFirewallRule -Group $FwGroup -ErrorAction SilentlyContinue | Measure-Object).Count
Show-Check "Firewall anti-bypass rules" ($fwCount -gt 0) "$fwCount rule(s)"

# Scheduled task
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Show-Check "Auto-reapply scheduled task" ([bool]$task) $(if($task){"State: $($task.State)"})

Write-Host ""

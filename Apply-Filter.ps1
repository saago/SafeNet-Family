<#
.SYNOPSIS
    SafeNet-Family : enforces system-wide adult-content filtering on Windows.
    Browser-independent. Idempotent (safe to run repeatedly).

.DESCRIPTION
    Applies the following layers of protection:
      1. Filtering DNS  - Cloudflare for Families (1.1.1.3) on every physical adapter.
                          Blocks adult + malware sites for ALL apps and ALL browsers.
      2. Forced SafeSearch - via the hosts file (works in every browser) AND via
                          browser policies (Edge / Chrome / Brave / Chromium / Firefox).
      3. DoH lockdown   - disables DNS-over-HTTPS in Windows and in browsers so they
                          cannot bypass the filtering DNS.
      4. Anti-bypass    - firewall rules blocking well-known unfiltered DNS resolvers.
      5. Hosts blocklist - a curated blackhole list of top adult domains, so the most
                          popular sites stay blocked even if DNS is tampered with.

    The first run backs up your existing DNS settings to .\state\dns-backup.json so
    Uninstall.ps1 can restore them exactly.

.PARAMETER YouTubeMode
    Strict (default) or Moderate. Controls YouTube Restricted Mode strength.

.PARAMETER LockDownDNS
    Optional, aggressive. Blocks ALL outbound port-53 DNS except the filtering
    resolver. Very strong, but can break unusual networks. Off by default.

.NOTES
    Must be run elevated (Administrator). Install.ps1 runs this for you and also
    creates a scheduled task that re-applies it hourly + at startup.
#>

[CmdletBinding()]
param(
    [ValidateSet('Strict', 'Moderate')]
    [string]$YouTubeMode = 'Strict',

    [switch]$LockDownDNS
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Guard: must be Administrator
# ---------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Apply-Filter.ps1 must be run as Administrator. Use Install.ps1 instead."
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateDir  = Join-Path $ScriptDir 'state'
if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
$LogFile   = Join-Path $StateDir 'apply.log'

function Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

Log "=== SafeNet-Family Apply-Filter starting (YouTube=$YouTubeMode, LockDownDNS=$LockDownDNS) ==="

# ===========================================================================
# CONFIGURATION
# ===========================================================================

# Cloudflare for Families - "1.1.1.3" tier blocks malware + adult content.
$FilterDnsV4 = @('1.1.1.3', '1.0.0.3')
$FilterDnsV6 = @('2606:4700:4700::1113', '2606:4700:4700::1003')

# Special SafeSearch endpoint IPs (maintained by the search providers).
$IpGoogleSafe   = '216.239.38.120'   # forcesafesearch.google.com
$IpYouTube      = if ($YouTubeMode -eq 'Strict') { '216.239.38.120' } else { '216.239.38.119' }
$IpBingSafe     = '150.171.28.16'    # strict.bing.com

# Well-known UNFILTERED public DNS / DoH resolvers to block (anti-bypass).
# Filtered resolvers (Cloudflare Families .3, OpenDNS FamilyShield .123) are NOT blocked.
$BlockedResolvers = @(
    '8.8.8.8', '8.8.4.4',                       # Google
    '1.1.1.1', '1.0.0.1', '1.1.1.2', '1.0.0.2', # Cloudflare (non-family tiers)
    '9.9.9.9', '149.112.112.112',               # Quad9
    '208.67.222.222', '208.67.220.220',         # OpenDNS (unfiltered)
    '94.140.14.14', '94.140.15.15',             # AdGuard
    '76.76.2.0', '76.76.10.0',                  # Control D
    '185.228.168.9', '185.228.169.9'            # CleanBrowsing (security tier, unfiltered for adult)
)

$HostsPath = Join-Path $env:WINDIR 'System32\drivers\etc\hosts'
$BeginMark = '# === SafeNetFamily BEGIN (managed block - do not edit) ==='
$EndMark   = '# === SafeNetFamily END ==='
$FwGroup   = 'SafeNetFamily'

# Curated blocklist of popular adult domains (belt-and-suspenders; DNS already
# covers the long tail). Pointed to 0.0.0.0 so they fail instantly.
$AdultDomains = @(
    'pornhub.com','www.pornhub.com','xvideos.com','www.xvideos.com',
    'xnxx.com','www.xnxx.com','xhamster.com','www.xhamster.com',
    'redtube.com','www.redtube.com','youporn.com','www.youporn.com',
    'tube8.com','www.tube8.com','spankbang.com','www.spankbang.com',
    'porn.com','www.porn.com','brazzers.com','www.brazzers.com',
    'onlyfans.com','www.onlyfans.com','chaturbate.com','www.chaturbate.com',
    'livejasmin.com','www.livejasmin.com','bongacams.com','www.bongacams.com',
    'stripchat.com','www.stripchat.com','cam4.com','www.cam4.com',
    'myfreecams.com','www.myfreecams.com','adultfriendfinder.com','www.adultfriendfinder.com',
    'eporner.com','www.eporner.com','txxx.com','www.txxx.com',
    'hentaihaven.xxx','nhentai.net','www.nhentai.net','rule34.xxx',
    'motherless.com','www.motherless.com','xvideos2.com','beeg.com','www.beeg.com'
)

# Google country domains to force SafeSearch on (most common ccTLDs).
$GoogleDomains = @(
    'google.com','www.google.com','google.co.uk','www.google.co.uk',
    'google.ca','www.google.ca','google.com.au','www.google.com.au',
    'google.de','www.google.de','google.fr','www.google.fr',
    'google.es','www.google.es','google.it','www.google.it',
    'google.nl','www.google.nl','google.co.in','www.google.co.in',
    'google.com.br','www.google.com.br','google.ru','www.google.ru',
    'google.co.jp','www.google.co.jp','google.com.mx','www.google.com.mx',
    'google.pl','www.google.pl','google.se','www.google.se',
    'google.co.il','www.google.co.il','google.com.tr','www.google.com.tr'
)

$YouTubeDomains = @(
    'youtube.com','www.youtube.com','m.youtube.com',
    'youtubei.googleapis.com','youtube.googleapis.com','www.youtube-nocookie.com'
)

$BingDomains = @('bing.com','www.bing.com')

# ===========================================================================
# STEP 1 - Backup existing DNS (once), then set filtering DNS
# ===========================================================================

function Get-TargetAdapters {
    # Physical, connected adapters only. Skip virtual/VM/loopback.
    Get-NetAdapter | Where-Object {
        $_.Status -eq 'Up' -and
        $_.Virtual -ne $true -and
        $_.InterfaceDescription -notmatch 'VMware|VirtualBox|Hyper-V|Loopback|TAP|Bluetooth'
    }
}

$DnsBackupFile = Join-Path $StateDir 'dns-backup.json'
$adapters = Get-TargetAdapters

if (-not (Test-Path $DnsBackupFile)) {
    $backup = @()
    foreach ($a in $adapters) {
        foreach ($fam in 'IPv4','IPv6') {
            $cur = Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily $fam
            $backup += [pscustomobject]@{
                ifIndex       = $a.ifIndex
                Name          = $a.Name
                AddressFamily = $fam
                Servers       = @($cur.ServerAddresses)
            }
        }
    }
    $backup | ConvertTo-Json -Depth 5 | Set-Content -Path $DnsBackupFile -Encoding UTF8
    Log "Backed up original DNS settings to $DnsBackupFile"
}

foreach ($a in $adapters) {
    try {
        Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $FilterDnsV4 -ErrorAction Stop
        Log "Set IPv4 DNS on '$($a.Name)' -> $($FilterDnsV4 -join ', ')"
    } catch { Log "WARN: could not set IPv4 DNS on '$($a.Name)': $($_.Exception.Message)" }
    try {
        Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $FilterDnsV6 -ErrorAction Stop
        Log "Set IPv6 DNS on '$($a.Name)' -> $($FilterDnsV6 -join ', ')"
    } catch { Log "WARN: could not set IPv6 DNS on '$($a.Name)': $($_.Exception.Message)" }
}

# Disable Windows automatic DoH so the OS uses plain DNS to our filtering servers.
try {
    $dohKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters'
    New-ItemProperty -Path $dohKey -Name 'EnableAutoDoh' -PropertyType DWord -Value 0 -Force | Out-Null
    Log "Disabled Windows automatic DoH (EnableAutoDoh=0)"
} catch { Log "WARN: could not set EnableAutoDoh: $($_.Exception.Message)" }

Clear-DnsClientCache -ErrorAction SilentlyContinue
Log "Flushed DNS cache"

# ===========================================================================
# STEP 2 - Hosts file: SafeSearch redirects + adult blocklist
# ===========================================================================

function Set-ManagedHostsBlock {
    param([string[]]$Lines)

    $raw = if (Test-Path $HostsPath) { Get-Content -Path $HostsPath -Raw } else { '' }

    # Strip any previous managed block.
    $pattern = [regex]::Escape($BeginMark) + '.*?' + [regex]::Escape($EndMark)
    $raw = [regex]::Replace($raw, $pattern, '', 'Singleline')
    $raw = $raw.TrimEnd("`r","`n")

    $block = ($BeginMark, ($Lines -join "`r`n"), $EndMark) -join "`r`n"
    $new   = ($raw, '', $block, '') -join "`r`n"

    Set-Content -Path $HostsPath -Value $new -Encoding ASCII -Force
}

$hostsLines = New-Object System.Collections.Generic.List[string]
$hostsLines.Add("# Forced SafeSearch (managed by SafeNet-Family)")
foreach ($d in $GoogleDomains)  { $hostsLines.Add(("{0}`t{1}" -f $IpGoogleSafe, $d)) }
foreach ($d in $YouTubeDomains) { $hostsLines.Add(("{0}`t{1}" -f $IpYouTube,    $d)) }
foreach ($d in $BingDomains)    { $hostsLines.Add(("{0}`t{1}" -f $IpBingSafe,    $d)) }
$hostsLines.Add("# Adult-domain blocklist")
foreach ($d in $AdultDomains)   { $hostsLines.Add(("0.0.0.0`t{0}" -f $d)) }

Set-ManagedHostsBlock -Lines $hostsLines
Log "Updated hosts file: SafeSearch redirects + $($AdultDomains.Count) blocked adult domains"

# ===========================================================================
# STEP 3 - Browser policies (SafeSearch + disable DoH)
# ===========================================================================

function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}

$ytRestrict = if ($YouTubeMode -eq 'Strict') { 2 } else { 1 }

# Chromium-family browsers (Edge, Chrome, Brave, generic Chromium).
$chromiumPolicyRoots = @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Edge',
    'HKLM:\SOFTWARE\Policies\Google\Chrome',
    'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave',
    'HKLM:\SOFTWARE\Policies\Chromium'
)
foreach ($root in $chromiumPolicyRoots) {
    Set-Reg -Path $root -Name 'ForceGoogleSafeSearch' -Value 1
    Set-Reg -Path $root -Name 'ForceYouTubeRestrict'  -Value $ytRestrict
    Set-Reg -Path $root -Name 'DnsOverHttpsMode'      -Value 'off' -Type String
    Set-Reg -Path $root -Name 'BuiltInDnsClientEnabled' -Value 0
}
# Edge also honours ForceBingSafeSearch.
Set-Reg -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'ForceBingSafeSearch' -Value 1
Log "Applied Chromium browser policies (SafeSearch + DoH off)"

# Firefox: disable DoH (SafeSearch itself is covered by the hosts file).
Set-Reg -Path 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox\DNSOverHTTPS' -Name 'Enabled' -Value 0
Set-Reg -Path 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox\DNSOverHTTPS' -Name 'Locked'  -Value 1
Log "Applied Firefox policy (DoH off)"

# ===========================================================================
# STEP 4 - Firewall: block unfiltered DNS resolvers (anti-bypass)
# ===========================================================================

# Remove our previous rules, then recreate (keeps it idempotent).
Get-NetFirewallRule -Group $FwGroup -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName 'SafeNetFamily - Block unfiltered DNS resolvers (UDP/TCP 53)' `
    -Group $FwGroup -Direction Outbound -Action Block -Protocol UDP `
    -RemoteAddress $BlockedResolvers -RemotePort 53 -Profile Any | Out-Null
New-NetFirewallRule -DisplayName 'SafeNetFamily - Block unfiltered DNS resolvers (TCP 53)' `
    -Group $FwGroup -Direction Outbound -Action Block -Protocol TCP `
    -RemoteAddress $BlockedResolvers -RemotePort 53 -Profile Any | Out-Null
# Block DoH-over-443 to those same resolver IPs.
New-NetFirewallRule -DisplayName 'SafeNetFamily - Block unfiltered DoH resolvers (TCP 443)' `
    -Group $FwGroup -Direction Outbound -Action Block -Protocol TCP `
    -RemoteAddress $BlockedResolvers -RemotePort 443 -Profile Any | Out-Null
Log "Created firewall rules blocking $($BlockedResolvers.Count) unfiltered resolvers"

if ($LockDownDNS) {
    # Aggressive: block ALL outbound DNS except the filtering resolver.
    New-NetFirewallRule -DisplayName 'SafeNetFamily - Allow filtering DNS only (UDP 53)' `
        -Group $FwGroup -Direction Outbound -Action Allow -Protocol UDP `
        -RemoteAddress ($FilterDnsV4 + $FilterDnsV6) -RemotePort 53 -Profile Any | Out-Null
    New-NetFirewallRule -DisplayName 'SafeNetFamily - Block all other DNS (UDP 53)' `
        -Group $FwGroup -Direction Outbound -Action Block -Protocol UDP `
        -RemotePort 53 -Profile Any | Out-Null
    New-NetFirewallRule -DisplayName 'SafeNetFamily - Allow filtering DNS only (TCP 53)' `
        -Group $FwGroup -Direction Outbound -Action Allow -Protocol TCP `
        -RemoteAddress ($FilterDnsV4 + $FilterDnsV6) -RemotePort 53 -Profile Any | Out-Null
    New-NetFirewallRule -DisplayName 'SafeNetFamily - Block all other DNS (TCP 53)' `
        -Group $FwGroup -Direction Outbound -Action Block -Protocol TCP `
        -RemotePort 53 -Profile Any | Out-Null
    Log "LockDownDNS enabled: only $($FilterDnsV4 -join '/') permitted for DNS"
}

Log "=== SafeNet-Family Apply-Filter finished OK ==="

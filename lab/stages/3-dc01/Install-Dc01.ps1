<#
.SYNOPSIS
  Turn a fresh Windows Server into the Acme Corp domain controller (dc01).
  Run ON dc01, in an elevated PowerShell. Lab use only.

.DESCRIPTION
  Two phases, because promoting a domain controller requires a reboot:

    Phase 1 (first run):  installs the AD DS role and promotes this server to a new
                          forest 'acme.lab'. The server reboots.
    Phase 2 (run again):  after the reboot, seeds the directory with a randomized
                          fake company (OUs, groups, users) via Seed-Company.ps1.

  The script detects which phase it's in, so just run it, let it reboot, log back
  in, and run it again.

.NOTES
  - acme.lab is an internal-only lab domain. It is not a real domain.
  - The Directory Services Restore Mode (DSRM) password is generated randomly and
    saved to a local, access-restricted file (see below). It is never committed.
  - Intended for a VM with NO public IP on the lab subnet (10.0.1.0/24).
#>
[CmdletBinding()]
param(
  [string]$DomainName = "acme.lab",
  [string]$NetbiosName = "ACME",
  [int]$Employees = 35,
  [int]$Seed = 0,
  [string]$StateDir = "C:\LabState"
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host ("[{0}] {1}" -f (Get-Date -Format HH:mm:ss), $msg) -ForegroundColor Cyan }

# Refuse to run if a public IP is attached (defence-in-depth; lab must stay private).
try {
  $pub = Invoke-RestMethod -Headers @{Metadata="true"} -Uri `
    "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2021-02-01&format=text" `
    -TimeoutSec 3 -ErrorAction Stop
  if ($pub -and $pub.Trim()) {
    throw "Refusing: this VM has a public IP ($($pub.Trim())). A domain controller must be lab-only. Remove the public IP and re-run."
  }
} catch {
  if ($_.Exception.Message -like "Refusing:*") { throw }
  Write-Host "  Could not reach Azure metadata to confirm no public IP (normal off-Azure). Continuing." -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

$adInstalled = (Get-WindowsFeature -Name AD-Domain-Services).Installed
$isDc = $false
try { $isDc = ((Get-WmiObject Win32_ComputerSystem).DomainRole -ge 4) } catch {}

if (-not $isDc) {
  # -------- Phase 1: install role + promote --------
  Write-Step "Phase 1: installing AD DS role and promoting to '$DomainName'"
  if (-not $adInstalled) {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null
  }

  # Random DSRM password, stored locally with restricted ACL, never committed.
  Add-Type -AssemblyName System.Web
  $dsrm = [System.Web.Security.Membership]::GeneratePassword(24, 6)
  $dsrmFile = Join-Path $StateDir "dsrm-password.txt"
  Set-Content -Path $dsrmFile -Value $dsrm -NoNewline
  icacls $dsrmFile /inheritance:r /grant:r "Administrators:F" | Out-Null
  Write-Host "  DSRM recovery password saved to $dsrmFile (keep it safe; not in git)." -ForegroundColor Yellow

  Import-Module ADDSDeployment
  Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -InstallDns `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $dsrm -AsPlainText -Force) `
    -Force `
    -NoRebootOnCompletion:$false

  # The forest install triggers the reboot. After login, run this script again.
  Write-Host "Promoting and rebooting. Log back in and run this script again to seed the company." -ForegroundColor Green
}
else {
  # -------- Phase 2: seed the directory --------
  Write-Step "Phase 2: seeding the Acme directory (OUs, groups, users)"
  $seedScript = Join-Path $PSScriptRoot "Seed-Company.ps1"
  & $seedScript -DomainName $DomainName -Employees $Employees -Seed $Seed -StateDir $StateDir
  Write-Host "Done. Verify with:  .\Verify-Dc01.ps1" -ForegroundColor Green
}

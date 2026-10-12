<#
.SYNOPSIS
  Check that dc01 is a working domain controller and the Acme directory is seeded.
  Run ON dc01. Prints PASS/FAIL per check.
#>
[CmdletBinding()]
param([string]$DomainName = "acme.lab")

$pass = 0; $fail = 0
function Ok($m){ Write-Host "  PASS $m" -ForegroundColor Green; $script:pass++ }
function No($m){ Write-Host "  FAIL $m" -ForegroundColor Red;   $script:fail++ }

Write-Host "dc01 / acme.lab checks:"

# Is this a domain controller for the expected domain?
try {
  $d = Get-ADDomain -ErrorAction Stop
  if ($d.DNSRoot -eq $DomainName) { Ok "domain controller for $DomainName" } else { No "unexpected domain: $($d.DNSRoot)" }
} catch { No "AD not responding (is promotion finished and rebooted?)" }

# AD DS and DNS services running
foreach ($svc in @("NTDS","DNS","Netlogon")) {
  $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
  if ($s -and $s.Status -eq "Running") { Ok "service running: $svc" } else { No "service running: $svc" }
}

# OU tree and groups exist
try {
  $domDN = (Get-ADDomain).DistinguishedName
  if (Get-ADOrganizationalUnit -Filter "Name -eq 'Acme'" -SearchBase $domDN) { Ok "OU=Acme present" } else { No "OU=Acme missing" }
  $users = (Get-ADUser -Filter * -SearchBase "OU=Acme,$domDN").Count
  if ($users -ge 10) { Ok "staff accounts created ($users)" } else { No "too few staff accounts ($users)" }
  foreach ($g in @("All-Staff","IT-Admins")) {
    if (Get-ADGroup -Filter "Name -eq '$g'") { Ok "group present: $g" } else { No "group missing: $g" }
  }
} catch { No "could not query OU/users/groups: $($_.Exception.Message)" }

# Security auditing on (so logons and account changes are logged for Wazuh)
$audit = (AuditPol /get /subcategory:"Logon" /r 2>$null | Select-String "Logon")
if ($audit) { Ok "audit policy readable (configure per wazuh/README.md)" } else { No "could not read audit policy" }

Write-Host ""
Write-Host "  $pass passed, $fail failed"
if ($fail -gt 0) { exit 1 }

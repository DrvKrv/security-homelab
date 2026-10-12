<#
.SYNOPSIS
  Remove the seeded Acme company (OU=Acme and everything in it) so you can roll a
  fresh one. Run ON dc01. Does NOT demote the domain controller.

.DESCRIPTION
  Deletes the OU=Acme subtree (all departmental OUs, users and groups the seeder
  created) and the All-Staff / IT-Admins groups. Then run Seed-Company.ps1 again
  for a new random roster.

  It only touches objects under OU=Acme and the two top-level lab groups, so it
  won't remove built-in or Domain Controller accounts. You are prompted before
  anything is deleted.
#>
[CmdletBinding()]
param([string]$StateDir = "C:\LabState")

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$domDN = (Get-ADDomain).DistinguishedName
$acmeOU = "OU=Acme,$domDN"

$ou = Get-ADOrganizationalUnit -Filter "Name -eq 'Acme'" -SearchBase $domDN -ErrorAction SilentlyContinue
if (-not $ou) { Write-Host "Nothing to reset: OU=Acme not found." ; return }

Write-Host "This will DELETE OU=Acme and all users/groups under it." -ForegroundColor Yellow
$confirm = Read-Host "Type YES to continue"
if ($confirm -ne "YES") { Write-Host "Cancelled." ; return }

# Allow deletion even though child objects exist; clear accidental-deletion protection first.
Get-ADOrganizationalUnit -Filter * -SearchBase $acmeOU | Set-ADObject -ProtectedFromAccidentalDeletion $false
Set-ADObject -Identity $acmeOU -ProtectedFromAccidentalDeletion $false
Remove-ADOrganizationalUnit -Identity $acmeOU -Recursive -Confirm:$false

foreach ($g in @("All-Staff","IT-Admins")) {
  $grp = Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue
  if ($grp) { Remove-ADGroup -Identity $grp -Confirm:$false }
}

# Clear the lab credentials/seed from this run.
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $StateDir "lab-credentials.csv"), (Join-Path $StateDir "seed.txt")

Write-Host "done" -ForegroundColor Green

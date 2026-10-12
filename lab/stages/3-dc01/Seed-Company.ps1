<#
.SYNOPSIS
  Seed the acme.lab directory with a randomized fake company: departmental OUs,
  security groups, and user accounts. Called by Install-Dc01.ps1 (Phase 2); can
  also be run on its own on the DC.

.DESCRIPTION
  Builds a standard, clean Active Directory structure:
    - one OU per department under OU=Acme
    - a security group per department, plus "All Staff" and "IT Admins"
    - user accounts with random passwords (stored only as AD hashes)

  Randomness: who works where, and in what role, changes every run so you can't
  memorise one fixed company. Pass -Seed to reproduce an exact roster.

  Secrets: each account gets a random password set at creation. The throwaway
  plaintext passwords are written to $StateDir\lab-credentials.csv (lab-only,
  access-restricted, never committed) so later lab tooling can sign in as the
  fake staff. One demo account (demo.user / fixed fake password) is created for
  hands-on testing.

  Hardening is YOUR job: this script builds a plain, realistic directory. Finding
  stale accounts, over-broad group membership, or weak password policy and fixing
  them is part of the Phase 2 identity exercises - the script doesn't plant
  specific weaknesses for you.
#>
[CmdletBinding()]
param(
  [string]$DomainName = "acme.lab",
  [int]$Employees = 35,
  [int]$Seed = 0,
  [string]$StateDir = "C:\LabState"
)

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

if ($Seed -le 0) { $Seed = Get-Random -Minimum 1 -Maximum 9999999 }
$rng = [System.Random]::new($Seed)
New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
Set-Content -Path (Join-Path $StateDir "seed.txt") -Value $Seed

$First = @("Alex","Jordan","Taylor","Morgan","Casey","Riley","Jamie","Avery","Quinn","Parker","Sam","Drew","Reese","Rowan","Skyler","Cameron","Hayden","Emerson","Finley","Dakota","Charlie","Elliot","Harper","Kai","Logan","Micah","Nico","Sage","Toby","Wes","Ada","Hugo","Ivy","Jude","Mira","Nash","Thea","Uma","Vera","Wade")
$Last  = @("Rivera","Chen","Okafor","Nguyen","Patel","Kim","Garcia","Haddad","Silva","Novak","Khan","Rossi","Dubois","Costa","Martin","Fischer","Yamamoto","Mwangi","Singh","Lopez","Weber","Moreau","Jensen","Ferrari","Schmidt","Nakamura","Reyes","Vasquez","Bauer","Larsen","Park","Romano","Sato","Tanaka","Vega","Wallace","Zhang","Bianchi","Castro","Tran")

# department -> list of possible titles
$Depts = [ordered]@{
  "Engineering" = @("Software Engineer","Senior Software Engineer","Engineering Manager","QA Engineer","DevOps Engineer")
  "Sales" = @("Account Executive","Sales Development Rep","Sales Manager")
  "Marketing" = @("Marketing Specialist","Content Strategist","Marketing Manager")
  "Finance" = @("Financial Analyst","Accountant","Finance Manager")
  "HumanResources" = @("HR Generalist","Recruiter","HR Manager")
  "IT" = @("IT Support Technician","Systems Administrator","IT Manager")
  "Operations" = @("Operations Analyst","Operations Manager","Logistics Coordinator")
  "CustomerSupport" = @("Support Agent","Senior Support Agent","Support Team Lead")
}

function New-LabPassword {
  Add-Type -AssemblyName System.Web
  return [System.Web.Security.Membership]::GeneratePassword(20, 4)
}

$domDN = (Get-ADDomain -Identity $DomainName).DistinguishedName
Write-Host ("[{0}] Building Acme OU tree under {1}" -f (Get-Date -Format HH:mm:ss), $domDN) -ForegroundColor Cyan

# Root OU
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Acme'" -SearchBase $domDN -ErrorAction SilentlyContinue)) {
  New-ADOrganizationalUnit -Name "Acme" -Path $domDN -ProtectedFromAccidentalDeletion $false
}
$acmeOU = "OU=Acme,$domDN"

$taken = @{}
$credRows = @()
$deptNames = @($Depts.Keys)

# Roughly distribute the requested headcount across departments.
$perDept = [Math]::Max(2, [Math]::Floor($Employees / $deptNames.Count))

foreach ($dept in $deptNames) {
  if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$dept'" -SearchBase $acmeOU -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $dept -Path $acmeOU -ProtectedFromAccidentalDeletion $false
  }
  $deptOU = "OU=$dept,$acmeOU"

  # Department security group
  $grpName = "$dept-Staff"
  if (-not (Get-ADGroup -Filter "Name -eq '$grpName'" -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name $grpName -GroupScope Global -GroupCategory Security -Path $deptOU
  }

  $count = $perDept + $rng.Next(0,3)
  for ($i=0; $i -lt $count; $i++) {
    $fn = $First[$rng.Next(0,$First.Count)]
    $ln = $Last[$rng.Next(0,$Last.Count)]
    $base = ("{0}{1}" -f $fn.Substring(0,1), $ln).ToLower()
    $sam = $base; $n = 1
    while ($taken.ContainsKey($sam)) { $n++; $sam = "$base$n" }
    $taken[$sam] = $true

    $titles = $Depts[$dept]
    $title = $titles[$rng.Next(0,$titles.Count)]
    $pw = New-LabPassword

    $exists = Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue
    if (-not $exists) {
      New-ADUser `
        -Name "$fn $ln" `
        -GivenName $fn -Surname $ln `
        -SamAccountName $sam `
        -UserPrincipalName "$sam@$DomainName" `
        -DisplayName "$fn $ln" `
        -Title $title `
        -Department $dept `
        -Path $deptOU `
        -AccountPassword (ConvertTo-SecureString $pw -AsPlainText -Force) `
        -Enabled $true `
        -ChangePasswordAtLogon $false
      Add-ADGroupMember -Identity $grpName -Members $sam
      $credRows += [pscustomobject]@{ sam=$sam; name="$fn $ln"; dept=$dept; title=$title; password=$pw }
    }
  }
}

# All Staff group
if (-not (Get-ADGroup -Filter "Name -eq 'All-Staff'" -ErrorAction SilentlyContinue)) {
  New-ADGroup -Name "All-Staff" -GroupScope Global -GroupCategory Security -Path $acmeOU
}
Get-ADUser -Filter * -SearchBase $acmeOU | ForEach-Object { Add-ADGroupMember -Identity "All-Staff" -Members $_.SamAccountName -ErrorAction SilentlyContinue }

# IT Admins group (members: IT department users)
if (-not (Get-ADGroup -Filter "Name -eq 'IT-Admins'" -ErrorAction SilentlyContinue)) {
  New-ADGroup -Name "IT-Admins" -GroupScope Global -GroupCategory Security -Path "OU=IT,$acmeOU"
}
Get-ADUser -Filter "Department -eq 'IT'" -SearchBase $acmeOU | ForEach-Object { Add-ADGroupMember -Identity "IT-Admins" -Members $_.SamAccountName -ErrorAction SilentlyContinue }

# Demo account with a fixed, obviously-fake password for hands-on testing.
$demoPw = "AcmeDemo1!LabOnly"
if (-not (Get-ADUser -Filter "SamAccountName -eq 'demo.user'" -ErrorAction SilentlyContinue)) {
  New-ADUser -Name "Demo User" -SamAccountName "demo.user" -UserPrincipalName "demo.user@$DomainName" `
    -DisplayName "Demo User" -Title "Lab Demo Account" -Department "IT" -Path "OU=IT,$acmeOU" `
    -AccountPassword (ConvertTo-SecureString $demoPw -AsPlainText -Force) -Enabled $true
}
$credRows += [pscustomobject]@{ sam="demo.user"; name="Demo User"; dept="IT"; title="Lab Demo Account"; password=$demoPw }

# Write lab-only credentials (restricted ACL, never committed).
$credFile = Join-Path $StateDir "lab-credentials.csv"
$credRows | Export-Csv -Path $credFile -NoTypeInformation
icacls $credFile /inheritance:r /grant:r "Administrators:F" | Out-Null

# Quiet by design: neutral confirmation only.
Write-Host "done" -ForegroundColor Green

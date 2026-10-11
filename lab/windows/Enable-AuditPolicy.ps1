<#
.SYNOPSIS
    Turns on the Windows auditing this lab needs so logons, lockouts and
    account changes show up in the Security log (and therefore in Wazuh).

.DESCRIPTION
    LAB USE ONLY. Run on the win-client VM, in PowerShell opened with
    "Run as administrator":

        Set-ExecutionPolicy -Scope Process Bypass
        .\Enable-AuditPolicy.ps1

    What it changes (and why):
      * Advanced audit policy: logon/logoff, lockouts, credential validation,
        user and group management, process creation, policy changes.
      * Includes the full command line in process-creation events (4688).
      * PowerShell script-block logging (event 4104) so you can see what ran.
      * Account lockout: 5 bad passwords in 15 minutes locks the account for
        15 minutes (gives you event 4740 to investigate).
      * Security log grows to 256 MB so evidence isn't overwritten.

    Before changing anything it saves the current audit policy to
    C:\LabBackup\auditpol-before-<time>.csv. To undo the audit policy:

        .\Enable-AuditPolicy.ps1 -Restore C:\LabBackup\auditpol-before-<time>.csv

    Note: subcategory names below are the English ones. If Windows is
    installed in another language, auditpol will report "parameter is
    incorrect"; switch to the language-neutral subcategory GUIDs instead.
#>
[CmdletBinding()]
param(
    [string]$Restore
)

$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this from PowerShell opened with "Run as administrator".'
}

if ($Restore) {
    auditpol /restore /file:"$Restore"
    if ($LASTEXITCODE -ne 0) { throw "auditpol /restore failed (exit $LASTEXITCODE)" }
    Write-Host "Audit policy restored from $Restore" -ForegroundColor Green
    return
}

$backupDir = 'C:\LabBackup'
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$backup = Join-Path $backupDir ("auditpol-before-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date))
auditpol /backup /file:"$backup" | Out-Null
Write-Host "Saved current audit policy to $backup"

# 1. Make Windows use the detailed "advanced" audit policy instead of the old 9 categories.
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' `
    -Name 'SCENoApplyLegacyAuditPolicy' -PropertyType DWord -Value 1 -Force | Out-Null

# 2. Advanced audit subcategories. S = success, F = failure.
$subcategories = [ordered]@{
    'Logon'                        = 'SF'  # 4624 success, 4625 failure
    'Logoff'                       = 'S'   # 4634, 4647
    'Account Lockout'              = 'SF'  # 4625 with lockout status
    'Special Logon'                = 'S'   # 4672 admin-level logon
    'Other Logon/Logoff Events'    = 'SF'  # lock/unlock workstation, RDP reconnects
    'Credential Validation'        = 'SF'  # 4776 local password checks
    'User Account Management'      = 'SF'  # 4720 create, 4722 enable, 4724 reset, 4725 disable, 4726 delete, 4738 change, 4740 lockout
    'Security Group Management'    = 'SF'  # 4732 added to local group, 4733 removed
    'Process Creation'             = 'S'   # 4688 new process
    'Audit Policy Change'          = 'SF'  # 4719 someone changed auditing
    'Authentication Policy Change' = 'S'   # 4713, 4716, 4739 (e.g. lockout policy changed)
    'Security State Change'        = 'S'   # 4608 startup, 4616 time changed
    'Security System Extension'    = 'S'   # 4697 service installed
}

foreach ($name in $subcategories.Keys) {
    $want = $subcategories[$name]
    $success = if ($want -like '*S*') { 'enable' } else { 'disable' }
    $failure = if ($want -like '*F*') { 'enable' } else { 'disable' }
    auditpol /set /subcategory:"$name" /success:$success /failure:$failure | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "auditpol failed for subcategory '$name' (exit $LASTEXITCODE)" }
    Write-Host ("  {0,-30} success={1,-7} failure={2}" -f $name, $success, $failure)
}

# 3. Put the full command line into process-creation events (4688).
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit' `
    -Name 'ProcessCreationIncludeCmdLine_Enabled' -PropertyType DWord -Value 1 -Force | Out-Null

# 4. PowerShell script-block logging (Microsoft-Windows-PowerShell/Operational, event 4104).
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' `
    -Name 'EnableScriptBlockLogging' -PropertyType DWord -Value 1 -Force | Out-Null

# 5. Account lockout policy: 5 bad passwords within 15 minutes = locked for 15 minutes.
net accounts /lockoutthreshold:5 /lockoutduration:15 /lockoutwindow:15 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "net accounts failed (exit $LASTEXITCODE)" }

# 6. Bigger Security log (256 MB) so the evidence isn't overwritten.
wevtutil sl Security /ms:268435456

Write-Host ''
Write-Host 'Current settings:' -ForegroundColor Cyan
auditpol /get /category:"Logon/Logoff","Account Management","Account Logon","Detailed Tracking","Policy Change"
net accounts

Write-Host ''
Write-Host 'Done. Screenshot the output above for your write-up.' -ForegroundColor Green
Write-Host 'In Wazuh you should now see rule 60112 "Windows Audit Policy changed" for this machine.'

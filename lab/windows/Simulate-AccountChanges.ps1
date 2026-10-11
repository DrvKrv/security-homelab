<#
.SYNOPSIS
    LAB ONLY: simulates an attacker creating a hidden admin account
    ("persistence"), then lets you clean it up as the defender.

.DESCRIPTION
    !!! Run ONLY on your lab VM (win-client), from an elevated PowerShell.
    !!! It creates a real local administrator account until you run -Phase Cleanup.

    -Phase Attack   (the "incident")
        1. Creates local user svc_backup with a random password     -> 4720, 4722, 4738   (Wazuh 60109, 60110)
        2. Adds it to the local Administrators group                -> 4732               (Wazuh 60154, level 12)
        3. Resets its password, like an attacker re-using it later  -> 4724, 4738         (Wazuh 60110)
    -Phase Cleanup  (your "remediation", after you've investigated)
        4. Removes it from Administrators                           -> 4733               (Wazuh 60154)
        5. Disables it                                              -> 4725               (Wazuh 60111)
        6. Deletes it                                               -> 4726               (Wazuh 60111)

    The password is random, never shown and never saved.

    Usage:
        Set-ExecutionPolicy -Scope Process Bypass
        .\Simulate-AccountChanges.ps1 -Phase Attack
        # ...investigate in Wazuh, take screenshots...
        .\Simulate-AccountChanges.ps1 -Phase Cleanup
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Attack', 'Cleanup')][string]$Phase,
    [string]$UserName = 'svc_backup',
    [ValidateRange(0, 60)][int]$PauseSeconds = 5
)

$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this from PowerShell opened with "Run as administrator".'
}

# Built-in Administrators group by SID, so this works whatever the Windows language.
$adminGroup = Get-LocalGroup -SID 'S-1-5-32-544'

function New-RandomSecurePassword {
    $bytes = New-Object byte[] 24
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    # Base64 plus a fixed suffix guarantees upper, lower, digit and symbol.
    ConvertTo-SecureString ([Convert]::ToBase64String($bytes) + 'a1!Z') -AsPlainText -Force
}

function Step([string]$text) {
    Write-Host ("{0:HH:mm:ss}  {1}" -f (Get-Date), $text) -ForegroundColor Cyan
}

$evidence = 'C:\LabEvidence'
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
Start-Transcript -Path (Join-Path $evidence ("account-changes-$Phase-{0:yyyyMMdd-HHmmss}.txt" -f (Get-Date))) | Out-Null
$start = Get-Date

try {
    if ($Phase -eq 'Attack') {
        if (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue) {
            throw "User '$UserName' already exists. Run -Phase Cleanup first."
        }
        Step "1. Creating local user '$UserName'"
        New-LocalUser -Name $UserName -Password (New-RandomSecurePassword) `
            -FullName 'Backup Service' -Description 'Backup service account' `
            -PasswordNeverExpires -AccountNeverExpires | Out-Null
        Start-Sleep -Seconds $PauseSeconds

        Step "2. Adding '$UserName' to $($adminGroup.Name)"
        Add-LocalGroupMember -Group $adminGroup -Member $UserName
        Start-Sleep -Seconds $PauseSeconds

        Step "3. Resetting the password of '$UserName'"
        Set-LocalUser -Name $UserName -Password (New-RandomSecurePassword)
    }
    else {
        if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
            throw "User '$UserName' doesn't exist; nothing to clean up."
        }
        Step "4. Removing '$UserName' from $($adminGroup.Name)"
        Remove-LocalGroupMember -Group $adminGroup -Member $UserName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds $PauseSeconds

        Step "5. Disabling '$UserName'"
        Disable-LocalUser -Name $UserName
        Start-Sleep -Seconds $PauseSeconds

        Step "6. Deleting '$UserName'"
        Remove-LocalUser -Name $UserName
        $profilePath = Join-Path $env:SystemDrive "Users\$UserName"
        if (Test-Path $profilePath) { Write-Host "  (A profile folder exists at $profilePath; delete it if you like.)" }
    }

    Start-Sleep -Seconds 2
    Write-Host "`nLocal evidence (Security log since the start):" -ForegroundColor Cyan
    Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4720, 4722, 4724, 4725, 4726, 4732, 4733, 4738; StartTime = $start } -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, Id, @{n = 'What'; e = { ($_.Message -split "`r?`n")[0] } } |
        Format-Table -AutoSize -Wrap
}
finally {
    Stop-Transcript | Out-Null
}

if ($Phase -eq 'Attack') {
    Write-Host "Incident staged. Investigate in Wazuh before running -Phase Cleanup." -ForegroundColor Yellow
}
else {
    Write-Host "Cleanup done. Confirm in Wazuh, then screenshot the 4733/4725/4726 alerts as proof of remediation." -ForegroundColor Green
}

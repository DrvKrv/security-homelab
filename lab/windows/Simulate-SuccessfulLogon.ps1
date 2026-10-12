<#
.SYNOPSIS
    LAB ONLY: makes a successful logon (event 4624) with a throwaway lab
    account, so a lesson can stage "failed logons, then one success".

.DESCRIPTION
    !!! Run ONLY on your own lab VM (win-srv), from an elevated PowerShell.
    !!! It only ever logs on to THIS computer, only with the lab account it
    !!! created itself, and never with your own account.

    Approved by KT on 2026-10-12 as an exception to the repo's "no new attack
    code" rule: it signs in with a password it set itself, nothing more.

    -Phase Prepare   Creates a throwaway local account (a random name from a
                     short list, or -UserName), in the Users group only, with a
                     random password. The password is saved encrypted with
                     Windows DPAPI in C:\LabBackup, so only this admin account
                     on this computer can read it. Run again, it reuses the
                     account.                            -> 4720, 4722, 4738
    -Phase Logon     Signs in once as that account with its real password, the
                     way a network logon does (LogonUser, logon type 3).
                                                         -> 4624, then 4634
    -Phase Scenario  For the A2 lesson: Prepare, then a pause, then a few wrong
                     passwords for the account (plus made-up names) using
                     Simulate-FailedLogons.ps1, then, on most runs but not all,
                     one successful Logon after another pause. Stays under the
                     5-failure lockout so a success is possible.
    -Phase Cleanup   Deletes the account, any profile it left, and the saved
                     password.                           -> 4726

    Usage (elevated PowerShell, from the repo's lab\ folder):
        powershell -ExecutionPolicy Bypass -File windows\Simulate-SuccessfulLogon.ps1 -Phase Scenario
        powershell -ExecutionPolicy Bypass -File windows\Simulate-SuccessfulLogon.ps1 -Phase Cleanup

    The password is random and never shown. A copy of this script's output goes
    to C:\LabEvidence, like the other lab scripts.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Prepare', 'Logon', 'Scenario', 'Cleanup')][string]$Phase,
    [string]$UserName
)

$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this from PowerShell opened with "Run as administrator".'
}

# Plausible staff-style names; the account is a lab stand-in, not a real person.
$namePool = @('j.morgan', 't.nguyen', 'a.patel', 'r.santos', 'm.kowalski')
$credFile = 'C:\LabBackup\logon-lab-account.xml'
$evidence = 'C:\LabEvidence'

function Step([string]$text) {
    Write-Host ("{0:HH:mm:ss}  {1}" -f (Get-Date), $text) -ForegroundColor Cyan
}

function New-RandomSecurePassword {
    $bytes = New-Object byte[] 24
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    # Base64 plus a fixed suffix guarantees upper, lower, digit and symbol.
    ConvertTo-SecureString ([Convert]::ToBase64String($bytes) + 'a1!Z') -AsPlainText -Force
}

function Get-LabCredential {
    if (-not (Test-Path $credFile)) { throw "No lab account prepared yet. Run -Phase Prepare first." }
    Import-Clixml -Path $credFile
}

function Invoke-Prepare {
    if (Test-Path $credFile) {
        $cred = Get-LabCredential
        if (Get-LocalUser -Name $cred.UserName -ErrorAction SilentlyContinue) {
            Step "Lab account already prepared: $($cred.UserName)"
            return $cred.UserName
        }
        Remove-Item $credFile -Force
    }
    $name = if ($UserName) { $UserName } else {
        $namePool | Where-Object { -not (Get-LocalUser -Name $_ -ErrorAction SilentlyContinue) } | Get-Random
    }
    if (-not $name) { throw 'Every name in the list already exists. Run -Phase Cleanup or pass -UserName.' }
    if ($name -ieq $env:USERNAME) { throw "Refusing to use the account you're logged in as ($env:USERNAME)." }
    if (Get-LocalUser -Name $name -ErrorAction SilentlyContinue) {
        throw "Local user '$name' already exists and wasn't made by this script. Pick another -UserName."
    }

    $secure = New-RandomSecurePassword
    Step "Creating lab account '$name' (Users group only)"
    New-LocalUser -Name $name -Password $secure -FullName $name -Description 'Contractor' `
        -PasswordNeverExpires -AccountNeverExpires | Out-Null
    # Built-in Users group by SID, so this works whatever the Windows language.
    Add-LocalGroupMember -SID 'S-1-5-32-545' -Member $name -ErrorAction SilentlyContinue

    New-Item -ItemType Directory -Force -Path (Split-Path $credFile) | Out-Null
    New-Object Management.Automation.PSCredential($name, $secure) | Export-Clixml -Path $credFile
    return $name
}

function Invoke-Logon {
    Add-Type -Namespace Lab -Name LogonNative -MemberDefinition @'
[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool LogonUser(string user, string domain, string password,
    int logonType, int logonProvider, out IntPtr token);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool CloseHandle(IntPtr handle);
'@ -ErrorAction SilentlyContinue
    $cred = Get-LabCredential
    if ($cred.UserName -ieq $env:USERNAME) { throw "Refusing to log on as the account you're logged in as." }
    $token = [IntPtr]::Zero
    # 3 = network logon, 0 = default provider. Domain = this computer: local accounts only.
    $ok = [Lab.LogonNative]::LogonUser($cred.UserName, $env:COMPUTERNAME,
        $cred.GetNetworkCredential().Password, 3, 0, [ref]$token)
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($ok) {
        [void][Lab.LogonNative]::CloseHandle($token)
        Step "Logon as '$($cred.UserName)' succeeded"
        return $true
    }
    switch ($err) {
        1909 { Step "Logon as '$($cred.UserName)' failed: account is LOCKED OUT" }
        1326 { Step "Logon as '$($cred.UserName)' failed: wrong username or password" }
        default { Step "Logon as '$($cred.UserName)' failed: Windows error $err" }
    }
    return $false
}

function Invoke-Cleanup {
    $name = $UserName
    if (-not $name -and (Test-Path $credFile)) { $name = (Get-LabCredential).UserName }
    if ($name -and (Get-LocalUser -Name $name -ErrorAction SilentlyContinue)) {
        Remove-LocalUser -Name $name
        Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue |
            Where-Object { $_.LocalPath -like "*\$name" } | Remove-CimInstance -ErrorAction SilentlyContinue
        Step "Removed lab account '$name'"
    }
    else {
        Step 'No lab account to remove.'
    }
    if (Test-Path $credFile) { Remove-Item $credFile -Force; Step 'Removed the saved password.' }
}

New-Item -ItemType Directory -Force -Path $evidence | Out-Null
Start-Transcript -Path (Join-Path $evidence ("successful-logon-$Phase-{0:yyyyMMdd-HHmmss}.txt" -f (Get-Date))) | Out-Null
try {
    switch ($Phase) {
        'Prepare' { [void](Invoke-Prepare) }
        'Logon' { [void](Invoke-Logon) }
        'Cleanup' { Invoke-Cleanup }
        'Scenario' {
            $name = Invoke-Prepare
            Start-Sleep -Seconds (Get-Random -Minimum 30 -Maximum 120)
            # 2-4 wrong passwords for the real account stays under the 5-failure lockout.
            $attempts = Get-Random -Minimum 2 -Maximum 5
            Step "Wrong passwords: $attempts for '$name', plus made-up names"
            & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Simulate-FailedLogons.ps1') `
                -UserName $name -Attempts $attempts -DelaySeconds 2
            # Most runs end in a success; some don't, so "did they get in?" stays a real question.
            if ((Get-Random -Minimum 0 -Maximum 3) -gt 0) {
                Start-Sleep -Seconds (Get-Random -Minimum 20 -Maximum 90)
                $ok = Invoke-Logon
                Step ("Answer: account {0}; {1} wrong passwords for it; success: {2}" -f $name, $attempts, $(if ($ok) { 'yes' } else { 'no (it failed)' }))
            }
            else {
                Step ("Answer: account {0}; {1} wrong passwords for it; success: no (none attempted)" -f $name, $attempts)
            }
        }
    }
}
finally {
    Stop-Transcript | Out-Null
}

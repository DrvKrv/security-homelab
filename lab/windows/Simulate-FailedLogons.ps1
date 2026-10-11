<#
.SYNOPSIS
    LAB ONLY: generates failed Windows logons (event 4625) and, with the lockout
    policy from Enable-AuditPolicy.ps1, an account lockout (event 4740).

.DESCRIPTION
    !!! Run this ONLY on your own lab VM (win-client). It only ever tries to log
    !!! on to THIS computer, but it will lock out the target account for 15 min.
    !!! Never point it at your real/daily account or at a work or school machine.

    It asks Windows to check a password the same way a network logon does
    (LogonUser, logon type 3), using deliberately wrong random passwords:
      * -Attempts tries against the real account -UserName (default "labuser"),
        which also triggers the lockout after 5 failures.
      * A few tries against usernames that don't exist (admin, administrator,
        backup, test), the way password-guessing tools behave.
    No real password is used or stored.

    Expected in Wazuh (Threat Hunting > Events, filter agent.name:win-client):
      60122  Logon Failure - Unknown user or bad password   (one per attempt)
      60204  Multiple Windows Logon Failures                (after about 8)
      60115  User account locked out                        (after 5 on labuser)

    Run from an elevated PowerShell:
        Set-ExecutionPolicy -Scope Process Bypass
        .\Simulate-FailedLogons.ps1                  # defaults: labuser, 10 tries
        .\Simulate-FailedLogons.ps1 -UserName labuser -Attempts 12 -DelaySeconds 2

    Unlock the account afterwards with .\Reset-Lab.ps1 -UnlockUser labuser
    (or just wait 15 minutes).
#>
[CmdletBinding()]
param(
    [string]$UserName = 'labuser',
    [ValidateRange(1, 50)][int]$Attempts = 10,
    [ValidateRange(0, 30)][int]$DelaySeconds = 2,
    [string[]]$FakeUsers = @('admin', 'administrator', 'backup', 'test')
)

$ErrorActionPreference = 'Stop'

if ($UserName -ieq $env:USERNAME) {
    throw "Refusing to target the account you're logged in as ($env:USERNAME). Use the lab test account."
}
if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
    throw "Local user '$UserName' doesn't exist. Create it first (see runbooks/01-failed-logins.md)."
}

Add-Type -Namespace Lab -Name Native -MemberDefinition @'
[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool LogonUser(string user, string domain, string password,
    int logonType, int logonProvider, out IntPtr token);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool CloseHandle(IntPtr handle);
'@

$LOGON32_LOGON_NETWORK = 3
$LOGON32_PROVIDER_DEFAULT = 0

function New-WrongPassword {
    $chars = [char[]]'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    -join (1..16 | ForEach-Object { $chars | Get-Random })
}

function Invoke-BadLogon([string]$user) {
    $token = [IntPtr]::Zero
    $ok = [Lab.Native]::LogonUser($user, $env:COMPUTERNAME, (New-WrongPassword),
        $LOGON32_LOGON_NETWORK, $LOGON32_PROVIDER_DEFAULT, [ref]$token)
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($ok) {
        [void][Lab.Native]::CloseHandle($token)
        return 'UNEXPECTED SUCCESS'
    }
    switch ($err) {
        1326 { 'failed: wrong username or password' }
        1909 { 'failed: account is LOCKED OUT' }
        1331 { 'failed: account is disabled' }
        default { "failed: Windows error $err" }
    }
}

$evidence = 'C:\LabEvidence'
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
$log = Join-Path $evidence ("failed-logons-{0:yyyyMMdd-HHmmss}.txt" -f (Get-Date))

$start = Get-Date
"Simulation started $($start.ToString('u')) on $env:COMPUTERNAME" | Tee-Object -FilePath $log

Write-Host "`n[1/2] $Attempts bad passwords for real account '$UserName'" -ForegroundColor Cyan
for ($i = 1; $i -le $Attempts; $i++) {
    $result = Invoke-BadLogon $UserName
    ("{0:HH:mm:ss}  try {1,2}  user={2,-15} {3}" -f (Get-Date), $i, $UserName, $result) | Tee-Object -FilePath $log -Append
    Start-Sleep -Seconds $DelaySeconds
}

Write-Host "`n[2/2] Usernames that don't exist" -ForegroundColor Cyan
foreach ($fake in $FakeUsers) {
    $result = Invoke-BadLogon $fake
    ("{0:HH:mm:ss}  user={1,-15} {2}" -f (Get-Date), $fake, $result) | Tee-Object -FilePath $log -Append
    Start-Sleep -Seconds $DelaySeconds
}

"Simulation finished $((Get-Date).ToString('u'))" | Tee-Object -FilePath $log -Append

Write-Host "`nLocal evidence (Security log since the start):" -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4625, 4740; StartTime = $start } -ErrorAction SilentlyContinue |
    Group-Object Id | Select-Object @{n = 'EventID'; e = { $_.Name } }, Count | Format-Table -AutoSize

Write-Host "Saved a copy of this output to $log"
Write-Host "Now go to the Wazuh dashboard and follow the 'Investigate' steps in the runbook."

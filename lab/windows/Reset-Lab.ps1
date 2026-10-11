<#
.SYNOPSIS
    Puts win-client back into a clean state between exercises.

.DESCRIPTION
    Run from an elevated PowerShell on win-client.

        .\Reset-Lab.ps1 -UnlockUser labuser     # unlock after the failed-logon exercise
        .\Reset-Lab.ps1 -RemoveUser svc_backup  # remove the "attacker" account if left behind

    Restoring a VM snapshot (VMware Fusion > Virtual Machine > Snapshots) is
    the fastest full reset, but it also rewinds anything else you changed.
#>
[CmdletBinding()]
param(
    [string]$UnlockUser,
    [string]$RemoveUser
)

$ErrorActionPreference = 'Stop'

if ($UnlockUser) {
    # There's no Unlock-LocalUser cmdlet; the WinNT provider can clear the lockout flag.
    $account = [ADSI]"WinNT://$env:COMPUTERNAME/$UnlockUser,user"
    if ($account.IsAccountLocked) {
        $account.IsAccountLocked = $false
        $account.SetInfo()
        Write-Host "Unlocked $UnlockUser" -ForegroundColor Green
    }
    else {
        Write-Host "$UnlockUser is not locked."
    }
}

if ($RemoveUser) {
    if (Get-LocalUser -Name $RemoveUser -ErrorAction SilentlyContinue) {
        Remove-LocalGroupMember -Group (Get-LocalGroup -SID 'S-1-5-32-544') -Member $RemoveUser -ErrorAction SilentlyContinue
        Remove-LocalUser -Name $RemoveUser
        Write-Host "Removed $RemoveUser" -ForegroundColor Green
    }
    else {
        Write-Host "$RemoveUser doesn't exist."
    }
}

if (-not $UnlockUser -and -not $RemoveUser) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
}

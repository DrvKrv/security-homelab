<#
.SYNOPSIS
    LAB ONLY: run the Windows side of the capstone breach (unit 10) on win-srv.

.DESCRIPTION
    !!! Run ONLY on your own lab VM (win-srv), from an elevated PowerShell.

    The capstone breach spans more than one machine. run-breach.sh (bash) handles
    the steps that originate on wazuh and linux-srv. This script handles the
    Windows steps, by calling the simulation scripts that already live in
    lab\windows. It contains NO attack code of its own: it is a thin conductor
    that points at the existing Simulate-*.ps1 scripts.

    The seed-based plan that run-breach.sh prints (its "reveal" / the sealed
    plan file) tells you which Windows steps this breach includes, the account
    name it chose, and the delay before each. You pass those here. Keeping the
    Windows parameters explicit means win-srv does not need Python to recompute
    the plan.

    Steps it can run (each reuses an existing script):
      -Step Logon       failures then one success, as a stolen password being
                        tried and finally working.
                        -> lab\windows\Simulate-SuccessfulLogon.ps1 -Phase Scenario
      -Step Persistence a hidden local admin account is planted.
                        -> lab\windows\Simulate-AccountChanges.ps1 -Phase Attack
      -Step Cleanup     removes that account again (your remediation / teardown).
                        -> lab\windows\Simulate-AccountChanges.ps1 -Phase Cleanup

    Quiet by design: it prints only "done" (or an error). It never says which
    step ran or which account it used. The plan file from run-breach.sh is the
    answer key; keep it sealed until you want to check your work.

.EXAMPLE
    # From the repo's lab\stages\6-capstone folder, in an elevated PowerShell:
    Set-ExecutionPolicy -Scope Process Bypass
    .\Invoke-BreachStep.ps1 -Step Logon
    .\Invoke-BreachStep.ps1 -Step Persistence -Account svc_backup -DelayMinutes 20
    .\Invoke-BreachStep.ps1 -Step Cleanup -Account svc_backup
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Logon', 'Persistence', 'Cleanup')]
    [string]$Step,

    # The service-style account name from the plan (Persistence / Cleanup only).
    [ValidatePattern('^[A-Za-z0-9_]{1,32}$')]
    [string]$Account = 'svc_backup',

    # Optional: wait this many minutes before firing, so the step lands at its
    # planned time in the breach timeline. 0 fires now.
    [int]$DelayMinutes = 0
)

$ErrorActionPreference = 'Stop'

# lab\windows relative to this file: ..\..\windows
$windows = Resolve-Path (Join-Path $PSScriptRoot '..\..\windows')

function Invoke-Existing {
    param([string]$Script, [string[]]$Args)
    $path = Join-Path $windows $Script
    if (-not (Test-Path $path)) {
        throw "Expected $Script in $windows. Update your checkout (git pull)."
    }
    # Run it quietly: its own output goes to a log in %TEMP%, so staging does
    # not reveal the step on screen.
    $log = Join-Path $env:TEMP ("capstone-" + $Script.Replace('.ps1','') + ".log")
    & $path @Args *> $log
}

try {
    if ($DelayMinutes -gt 0) {
        Start-Sleep -Seconds ($DelayMinutes * 60)
    }

    switch ($Step) {
        'Logon' {
            Invoke-Existing 'Simulate-SuccessfulLogon.ps1' @('-Phase', 'Scenario')
        }
        'Persistence' {
            Invoke-Existing 'Simulate-AccountChanges.ps1' @('-Phase', 'Attack', '-UserName', $Account)
        }
        'Cleanup' {
            Invoke-Existing 'Simulate-AccountChanges.ps1' @('-Phase', 'Cleanup', '-UserName', $Account)
        }
    }
    Write-Output 'done'
}
catch {
    Write-Error $_
    exit 1
}

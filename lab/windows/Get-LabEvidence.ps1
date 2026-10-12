<#
.SYNOPSIS
    Shows the security events behind a Wazuh alert, straight from win-srv's
    own Security log, so you can compare "what Windows recorded" with "what
    the SIEM showed". Useful for the investigation section of each runbook.

.DESCRIPTION
        .\Get-LabEvidence.ps1                       # last 60 minutes, all lab event IDs
        .\Get-LabEvidence.ps1 -Minutes 15 -Id 4625  # only failed logons, last 15 min
        .\Get-LabEvidence.ps1 -Csv                  # also save to C:\LabEvidence\*.csv

    Event IDs used in this lab:
      4624 logon ok         4625 logon failed      4740 account locked out
      4720 user created     4722 user enabled      4724 password reset
      4725 user disabled    4726 user deleted      4738 user changed
      4732 added to group   4733 removed from group
      4719 audit policy changed                    4688 process started

    4625 Status / SubStatus codes worth knowing:
      0xC000006A  right username, wrong password
      0xC0000064  username doesn't exist
      0xC0000234  account is locked out
      0xC0000072  account is disabled
#>
[CmdletBinding()]
param(
    [int]$Minutes = 60,
    [int[]]$Id = @(4624, 4625, 4740, 4720, 4722, 4724, 4725, 4726, 4732, 4733, 4738, 4719),
    [switch]$Csv
)

$since = (Get-Date).AddMinutes(-$Minutes)
$events = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = $Id; StartTime = $since } -ErrorAction SilentlyContinue

if (-not $events) {
    Write-Host "No matching events in the last $Minutes minutes. Did you run Enable-AuditPolicy.ps1 as admin?"
    return
}

$rows = foreach ($e in $events) {
    $xml = [xml]$e.ToXml()
    $data = @{}
    foreach ($d in $xml.Event.EventData.Data) { $data[$d.Name] = $d.'#text' }
    # 4624 noise: skip the computer's own service logons (logon type 5) unless asked for 4624 only.
    if ($e.Id -eq 4624 -and $data['LogonType'] -eq '5' -and $Id.Count -gt 1) { continue }
    [pscustomobject]@{
        Time        = $e.TimeCreated
        EventID     = $e.Id
        TargetUser  = $data['TargetUserName']
        SubjectUser = $data['SubjectUserName']
        LogonType   = $data['LogonType']
        Status      = $data['Status']
        SubStatus   = $data['SubStatus']
        SourceIP    = $data['IpAddress']
        Process     = $data['ProcessName']
        Group       = if ($e.Id -in 4732, 4733) { $data['TargetUserName'] } else { $null }
        Member      = $data['MemberSid']
    }
}

$rows | Sort-Object Time | Format-Table Time, EventID, TargetUser, SubjectUser, LogonType, Status, SubStatus, SourceIP -AutoSize

if ($Csv) {
    New-Item -ItemType Directory -Force -Path 'C:\LabEvidence' | Out-Null
    $out = "C:\LabEvidence\security-events-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date)
    $rows | Sort-Object Time | Export-Csv -NoTypeInformation -Path $out
    Write-Host "Saved $out"
}

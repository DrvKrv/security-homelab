<#
.SYNOPSIS
    Installs Microsoft Sysmon on win-srv with the lab's config, or applies an
    updated config if Sysmon is already installed. Unit 4, detection engineering.

.DESCRIPTION
    Run on win-srv, in PowerShell opened with "Run as administrator", from the
    repo's lab\windows folder:

        Set-ExecutionPolicy -Scope Process Bypass
        .\Install-Sysmon.ps1                 # install, or re-apply the config
        .\Install-Sysmon.ps1 -Uninstall      # remove Sysmon

    What it does, and why:
      1. Downloads Sysmon from Microsoft's official Sysinternals site.
      2. Checks the download is signed by Microsoft before running anything
         from it. A tool that runs as a system service must come from where
         you think it does.
      3. Installs it with sysmon\sysmon-lab.xml (or, if Sysmon is already
         there, loads that config, so editing the XML and re-running this
         script is how you tune it).
      4. Shows the Sysmon log has events in it.

    The Wazuh agent picks up the Sysmon log through the "windows" agent group
    config (lab/wazuh/agent-groups/windows/agent.conf). Run setup-manager.sh on
    the wazuh VM again after pulling, so the agent gets that config.
#>
[CmdletBinding()]
param(
    [switch]$Uninstall,
    [string]$Config = (Join-Path $PSScriptRoot 'sysmon\sysmon-lab.xml')
)

$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this from PowerShell opened with "Run as administrator".'
}

$installDir = 'C:\LabTools\Sysmon'
$exe = Join-Path $installDir 'Sysmon64.exe'

function Get-SysmonService { Get-Service -Name 'Sysmon64', 'Sysmon' -ErrorAction SilentlyContinue | Select-Object -First 1 }

if ($Uninstall) {
    if (-not (Get-SysmonService)) { Write-Host 'Sysmon is not installed.'; return }
    & $exe -u
    Write-Host 'Sysmon removed.' -ForegroundColor Green
    return
}

if (-not (Test-Path $Config)) { throw "Config not found: $Config" }

# 1-2. Download from the official source and check the signature.
if (-not (Test-Path $exe)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    $zip = Join-Path $env:TEMP 'Sysmon.zip'
    Write-Host 'Downloading Sysmon from download.sysinternals.com ...'
    Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/Sysmon.zip' -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $installDir -Force
    Remove-Item $zip -Force
}
$sig = Get-AuthenticodeSignature -FilePath $exe
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
    throw "Sysmon64.exe is not validly signed by Microsoft (status: $($sig.Status)). Not running it."
}
Write-Host "Signature OK: $($sig.SignerCertificate.Subject -replace ',.*$', '')"

# 3. Install, or update the config of an existing install.
if (Get-SysmonService) {
    Write-Host 'Sysmon is already installed; applying the lab config.'
    & $exe -c $Config
}
else {
    Write-Host 'Installing Sysmon with the lab config.'
    & $exe -accepteula -i $Config
}
if ($LASTEXITCODE -ne 0) { throw "Sysmon returned exit code $LASTEXITCODE. Check the config file for typos." }

# 4. Proof it's working.
Start-Sleep -Seconds 5
$svc = Get-SysmonService
Write-Host ("Service {0}: {1}" -f $svc.Name, $svc.Status)
$recent = Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' -MaxEvents 5 -ErrorAction SilentlyContinue
if ($recent) {
    Write-Host 'Latest Sysmon events:'
    $recent | Select-Object TimeCreated, Id, @{ n = 'What'; e = { ($_.Message -split "`n")[0] } } | Format-Table -AutoSize
}
else {
    Write-Host 'No Sysmon events yet. Open any program, then run: Get-WinEvent -LogName Microsoft-Windows-Sysmon/Operational -MaxEvents 5'
}
Write-Host 'Done. In Wazuh, search agent.name: win-srv and data.win.system.channel: Microsoft-Windows-Sysmon/Operational' -ForegroundColor Green

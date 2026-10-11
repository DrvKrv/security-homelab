# Asset Inventory

An asset inventory is the first thing a security team needs: you can't protect
or investigate what you don't know exists. Fill in the `TODO` cells as each VM
is built. Planned values come from the setup plan and should be corrected if
the real build differs.

**Last updated:** `TODO YYYY-MM-DD`

## Hosts

| Hostname | Role | OS and version | Architecture | IP address | vCPU / RAM / Disk | Criticality | Owner | Wazuh agent | Snapshot taken |
|---|---|---|---|---|---|---|---|---|---|
| `wazuh` | SIEM server (manager, indexer, dashboard) | Ubuntu Server 24.04 LTS `TODO exact build` | ARM64 | 192.168.50.10 (planned) | 4 / 6 GB / 50 GB | High | KT | n/a (is the manager) | `TODO` |
| `win-client` | Employee workstation | Windows 11 `TODO edition and build` | ARM64 | 192.168.50.20 (planned) | 2 / 4 GB / 64 GB | Medium | KT | `TODO version` | `TODO` |
| `linux-srv` | Company Linux server (SSH) | Ubuntu Server 24.04 LTS `TODO exact build` | ARM64 | 192.168.50.30 (planned) | 2 / 2 GB / 20 GB | Medium | KT | `TODO version` | `TODO` |
| Host Mac | Hypervisor host, analyst workstation | macOS `TODO` | Apple M4 | 192.168.50.1 (Fusion host adapter, `TODO confirm`) | 16 GB RAM | High | KT | Not monitored | n/a |

**Criticality scale:** High = loss would blind monitoring or the whole lab;
Medium = a single business system; Low = disposable.

## Accounts

Record account **names and purpose only**. Never write passwords here.

| Host | Account | Type | Purpose | MFA / notes |
|---|---|---|---|---|
| win-client | `TODO` | Standard user | Day-to-day "employee" login; target for failed-login exercise | |
| win-client | `TODO` | Local administrator | Admin tasks only | |
| linux-srv | `TODO` | sudo user | SSH administration | Key-based auth after remediation? `TODO` |
| wazuh | `admin` (dashboard) | Application admin | Wazuh dashboard | Password stored outside the repo |

## Services and listening ports

Fill in from `ss -tulpn` (Linux) and `Get-NetTCPConnection -State Listen` (Windows).

| Host | Port / protocol | Service | Exposed to | Needed? |
|---|---|---|---|---|
| wazuh | 443/tcp | Wazuh dashboard | Lab network + host | Yes |
| wazuh | 1514/tcp | Agent event traffic | Lab network | Yes |
| wazuh | 1515/tcp | Agent enrollment | Lab network | During enrollment |
| wazuh | 55000/tcp | Wazuh API | `TODO` | `TODO` |
| linux-srv | 22/tcp | OpenSSH | Lab network | Yes |
| `TODO` | | | | |

## Installed software of interest

Software that matters for vulnerability research (see
[CVE research worksheet](cve-research-worksheet.md)).

| Host | Software | Version | Source | Notes |
|---|---|---|---|---|
| `TODO` | | | | |

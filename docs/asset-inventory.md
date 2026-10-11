# Asset Inventory

An asset inventory is the first thing a security team needs: you can't protect
or investigate what you don't know exists. Fill in the `TODO` cells as each VM
is built. Planned values come from the Azure setup plan and should be corrected
if the real build differs.

**Last updated:** `TODO YYYY-MM-DD`

## Cloud environment

| Item | Value |
|---|---|
| Provider | Microsoft Azure (Azure for Students) |
| Subscription | `<REDACTED>`: never publish the subscription or tenant ID |
| Region | `TODO e.g. West US 2` |
| Resource group | `homelab-rg` |
| Virtual network | `homelab-vnet`, 10.0.0.0/16 |
| Subnet | `lab-subnet`, 10.0.1.0/24 |
| Cost guardrails | $25 budget with alerts at 50% and 90%; auto-shutdown on every VM |

## Hosts

| Hostname | Role | OS and version | Azure size | Private IP | Public IP | Criticality | Owner | Wazuh agent | Auto-shutdown |
|---|---|---|---|---|---|---|---|---|---|
| `wazuh` | SIEM server (manager, indexer, dashboard) | Ubuntu Server 24.04 LTS `TODO exact build` | B2ms (2 vCPU, 8 GB), 50 GB SSD | 10.0.1.10 (static) | None | High | KT | n/a (is the manager) | `TODO` |
| `win-srv` | Windows server and jump host | Windows Server 2022 Datacenter `TODO build` | B2s (2 vCPU, 4 GB), 127 GB SSD | 10.0.1.20 (static) | Yes (`<REDACTED>`) | High | KT | `TODO version` | `TODO` |
| `linux-srv` | Company Linux server (SSH) | Ubuntu Server 24.04 LTS `TODO exact build` | B1ms (1 vCPU, 2 GB), 30 GB SSD | 10.0.1.30 (static) | None | Medium | KT | `TODO version` | `TODO` |

**Criticality scale:** High = loss would blind monitoring or remove the only
way into the lab; Medium = a single business system; Low = disposable.

## Accounts

Record account **names and purpose only**. Never write passwords or keys here.

| Host | Account | Type | Authentication | Purpose |
|---|---|---|---|---|
| win-srv | `TODO` | Local administrator (created by Azure) | Password | Admin tasks, RDP into the lab |
| win-srv | `TODO` | Standard user | Password | "Employee" account; target for failed-login exercise |
| wazuh | `TODO` | sudo user | SSH key | Administration |
| linux-srv | `TODO` | sudo user | SSH key | Administration |
| wazuh | `admin` (dashboard) | Application admin | Password | Wazuh dashboard; stored in a password manager |

## Network Security Group rules (inbound)

| NSG / attached to | Rule | Port | Source | Purpose |
|---|---|---|---|---|
| win-srv | Allow RDP | 3389/tcp | My home IP only (`<REDACTED>`) | Remote access into the lab |
| wazuh | none added | | | Reachable only from inside the VNet |
| linux-srv | none added | | | Reachable only from inside the VNet |
| all (Azure defaults) | AllowVnetInBound | any | VirtualNetwork | VM-to-VM traffic inside the VNet |
| all (Azure defaults) | DenyAllInBound | any | any | Everything else from the internet is blocked |

## Services and listening ports

Fill in from `ss -tulpn` (Linux) and `Get-NetTCPConnection -State Listen` (Windows).

| Host | Port / protocol | Service | Reachable from | Needed? |
|---|---|---|---|---|
| wazuh | 443/tcp | Wazuh dashboard | VNet | Yes |
| wazuh | 1514/tcp | Agent event traffic | VNet | Yes |
| wazuh | 1515/tcp | Agent enrollment | VNet | During enrollment |
| wazuh | 55000/tcp | Wazuh API | VNet | `TODO` |
| wazuh | 22/tcp | OpenSSH | VNet | Yes |
| linux-srv | 22/tcp | OpenSSH | VNet | Yes |
| win-srv | 3389/tcp | Remote Desktop | Internet (my IP only) | Yes |
| `TODO` | | | | |

## Installed software of interest

Software that matters for vulnerability research (see
[CVE research worksheet](cve-research-worksheet.md)).

| Host | Software | Version | Source | Notes |
|---|---|---|---|---|
| `TODO` | | | | |

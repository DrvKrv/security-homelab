# Network Diagram

> Planned topology. Update IPs and flows to match the real build, then replace
> "planned" with "as built" and the date.

**Status:** planned · **Last updated:** `TODO YYYY-MM-DD`

## Topology

```mermaid
flowchart TB
    INTERNET(("Internet"))
    subgraph HOST["MacBook Air M4: VMware Fusion Pro"]
        NAT["Fusion NAT<br/>(enabled only for installs and updates)"]
        subgraph LAB["Lab network vmnet2: 192.168.50.0/24, DHCP + static reservations"]
            HOSTIF["Host Mac adapter<br/>192.168.50.1<br/>Analyst browser + SSH"]
            WAZUH["wazuh: 192.168.50.10<br/>Ubuntu Server 24.04 ARM64<br/>Wazuh manager, indexer, dashboard"]
            WIN["win-client: 192.168.50.20<br/>Windows 11 ARM64<br/>Wazuh agent"]
            LNX["linux-srv: 192.168.50.30<br/>Ubuntu Server 24.04 ARM64<br/>OpenSSH, ufw, Wazuh agent"]
        end
    end
    HOME["Home network<br/>(not reachable from lab)"]

    WIN -- "1514/tcp events<br/>1515/tcp enrollment" --> WAZUH
    LNX -- "1514/tcp events<br/>1515/tcp enrollment" --> WAZUH
    HOSTIF -- "443/tcp dashboard" --> WAZUH
    HOSTIF -- "22/tcp SSH" --> LNX
    HOSTIF -- "22/tcp SSH" --> WAZUH
    WIN -. "authorized test traffic<br/>(failed SSH, nmap scan)" .-> LNX
    LAB -. "temporary, for updates only" .-> NAT --> INTERNET
    LAB x--x HOME
```

## Allowed traffic flows

| Source | Destination | Port / protocol | Purpose | Always on? |
|---|---|---|---|---|
| win-client, linux-srv | wazuh | 1514/tcp | Send security events to the SIEM | Yes |
| win-client, linux-srv | wazuh | 1515/tcp | Agent enrollment | Only when enrolling |
| Host Mac | wazuh | 443/tcp | Analyst uses the Wazuh dashboard | Yes |
| Host Mac | wazuh, linux-srv | 22/tcp | Administration over SSH | Yes |
| win-client | linux-srv | 22/tcp, scan ports | Authorized incident simulations | During exercises only |
| Lab VMs | Internet (via NAT) | 80, 443/tcp | OS and package updates | No: disabled after installs |
| Lab VMs | Home network | any | **Denied** | n/a |

## Design notes

- **Isolation:** the lab uses its own Fusion custom network so scans and
  simulated attacks cannot reach the home network or other devices.
  `TODO` describe how this was verified (e.g. ping to the home router fails from linux-srv).
- **Static addressing:** fixed IPs keep logs, alerts and this diagram consistent.
- **Single SIEM:** all three Wazuh components run on one VM to fit in 16 GB RAM.
  In a real company these would be separate, redundant servers.

Exported image for the README (optional): `evidence/network-diagram.png` `TODO`

# VM creation settings, tab by tab

Every field you'll see when creating the 3 VMs in the Azure portal (Virtual machines > **+ Create**). Fields are listed in the order the portal shows them. "Default" means leave it as the portal fills it in.

**Build order:** wazuh → win-srv → linux-srv.

## Watch out: fields Azure fills in wrong

Azure pre-fills some fields with *new* things. Check each of these before clicking Create:

| Field | Azure's default | What it should be |
|---|---|---|
| Basics > Resource group | sometimes a new `<vmname>_group` | **homelab-rg** |
| Basics > Availability options | Availability zone | **No infrastructure redundancy required** |
| Basics > Size | Standard_D2s_v3 (blocked for students) | the size in the table below |
| Disks > OS disk type | Premium SSD | **Standard SSD** |
| Networking > Virtual network | (new) vnet-westus2-1 | **homelab-vnet** |
| Networking > Subnet | (new) snet-westus2-1, 172.16.0.0/24 | **lab-subnet (10.0.1.0/24)** |
| Networking > Public IP | (new) `<vmname>-ip` | **None** (except win-srv) |
| Networking > Delete public IP and NIC when VM is deleted | unchecked | **checked** |
| Management > Enable auto-shutdown | unchecked | **checked** |

If a VM still ends up in the wrong resource group: open that group, select all items, **Move > Move to another resource group > homelab-rg**. SSH keys (`homelab-key`) can't be moved, so remove the key from the move list first. Then delete the group only if it's empty. In this lab, `wazuh_group` stays because it holds `homelab-key` (free, harmless). Delete it at the end of the project along with homelab-rg.

## Basics

| Field | wazuh | win-srv | linux-srv |
|---|---|---|---|
| Subscription | Azure for Students | same | same |
| Resource group | **homelab-rg** | **homelab-rg** | **homelab-rg** |
| Virtual machine name | `wazuh` | `win-srv` | `linux-srv` |
| Region | (US) West US 2 | same | same |
| Availability options | No infrastructure redundancy required | same | same |
| Security type | Trusted launch virtual machines (default) | same | same |
| Image | Ubuntu Server 24.04 LTS - x64 Gen2 | **Windows Server 2025 Datacenter - x64 Gen2** (plain edition, NOT "Azure Edition", which forces Azure-orchestrated patching). Use "See all images" if not listed; 2022 also works | Ubuntu Server 24.04 LTS - x64 Gen2 |
| VM architecture | **x64** | x64 | x64 |
| Run with Azure Spot discount | **unchecked** | unchecked | unchecked |
| Size (via "See all sizes") | **B2as_v2** (2 vCPU, 8 GB) | **B2als_v2** (2 vCPU, 4 GB) | **B2ats_v2** (2 vCPU, 1 GB) |
| Authentication type | SSH public key | Password | SSH public key |
| Username | `labadmin` | `labadmin` | `labadmin` |
| SSH public key source | Generate new key pair | (n/a) | **Use existing key stored in Azure** |
| SSH key type | Ed25519 | (n/a) | (n/a) |
| Key pair name / Stored keys | `homelab-key` | (n/a) | `homelab-key` |
| Password / Confirm password | (n/a) | Long, unique, saved in a password manager | (n/a) |
| Public inbound ports | **None** | **Allow selected ports** | **None** |
| Select inbound ports | (n/a) | **RDP (3389)** | (n/a) |
| Licensing checkbox (Windows) | (n/a) | **unchecked** | (n/a) |

Notes:
- **Size blocked?** "This size is currently unavailable in westus2 for this subscription" is the student-account limit. Pick from "See all sizes". The B-Series v2 sizes above worked. Backups with the same RAM: B2s_v2 or D2as_v5 (8 GB) for wazuh, B2ls_v2 (4 GB) for win-srv. **Never change the region**, because it must match homelab-vnet.
- **Spot unchecked:** Azure can shut Spot VMs off at any moment.
- **Usernames:** Azure blocks `admin`/`root`, and attackers guess those first.
- **One key for both Linux VMs:** generate it on wazuh, reuse it on linux-srv.
- **RDP warning on win-srv:** Azure warns that RDP is open to the internet. That's expected. You'll restrict it to your IP right after creation (see "After all 3 VMs exist").

## Disks

| Field | wazuh | win-srv | linux-srv |
|---|---|---|---|
| Encryption at host | unchecked ("not registered" message is fine) | same | same |
| OS disk size | **64 GiB** | Default (127 GiB) | Default (30 GiB) |
| OS disk type | **Standard SSD** | **Standard SSD** | **Standard SSD** |
| Delete with VM | checked (default) | same | same |
| Enable Ultra Disk compatibility | unchecked | same | same |
| Key management | Platform-managed key (default) | same | same |
| Data disks | none, don't add any | same | same |
| Ephemeral OS disk | None (greyed out, fine) | same | same |

Your disks are still encrypted automatically. "Encryption at host" is an extra layer you don't need. Premium SSD costs several times more than Standard SSD for speed you won't use.

## Networking

| Field | wazuh | win-srv | linux-srv |
|---|---|---|---|
| Virtual network | **homelab-vnet** | **homelab-vnet** | **homelab-vnet** |
| Subnet | **lab-subnet (10.0.1.0/24)** | same | same |
| Public IP | **None** | **(new) win-srv-ip**, keep it | **None** |
| NIC network security group | **Basic** | Basic | Basic |
| Public inbound ports | None | Allow selected ports | None |
| Select inbound ports | (n/a) | RDP (3389) | (n/a) |
| Delete public IP and NIC when VM is deleted | **checked** | **checked** | **checked** |
| Enable accelerated networking | unchecked | unchecked | unchecked |
| Load balancing options | **None** | None | None |

- **NSG Basic** gives each VM its own simple firewall. You'll add rules later so the agents can send logs to Wazuh.
- **Load balancers / Application Gateway** spread traffic across many servers for busy websites. You don't need one, and they cost money.
- **homelab-vnet not in the dropdown?** It was created in a different region. Check its region under Virtual networks.

## Management

| Field | All 3 VMs |
|---|---|
| Enable system assigned managed identity | unchecked |
| Login with Microsoft Entra ID | unchecked |
| **Enable auto-shutdown** | **checked**, 11:00 PM, (UTC-08:00) Pacific Time. Notification optional. |
| Enable periodic assessment | unchecked |
| Enable hotpatch (win-srv only) | **unchecked** |
| Patch orchestration options | Linux: Image default. **win-srv: Manual updates** (not Azure-orchestrated) |
| Enable Disaster Recovery (if shown) | unchecked |
| Enable hibernation | unchecked |
| Microsoft Defender for Cloud / Backup (if shown) | off (they cost money) |

Periodic assessment and automatic patching stay off on purpose. Finding and fixing outdated software yourself is part of the project.

## Monitoring

| Field | All 3 VMs |
|---|---|
| Enable recommended alert rules | unchecked |
| Boot diagnostics | **Enable with managed storage account (recommended)**. Pennies a month, and it lets you see the VM's screen if it won't start. |
| Enable OS guest diagnostics | unchecked |
| Enable application health monitoring | unchecked |

## Advanced, Tags

Leave defaults. Skip straight to **Review + create**.

## Review + create

Click **Create**.
- **wazuh only:** a pop-up offers **"Download private key and create resource"**. Click it. **This is the only time you can download the key.** Keep the `.pem` file somewhere safe on your Mac (e.g. `~/.ssh/`). Never upload it to GitHub, email it, or share it.
- linux-srv reuses that same key, so there's no new download.

## Deployment complete page

Ignore the "Next steps" links:
- auto-shutdown is already set,
- monitoring and run-a-script aren't needed.

Check that the **Resource group** at the top says **homelab-rg**. If it doesn't, move the resources (see the top of this file). Then click **Create another VM** for the next one.

## After all 3 VMs exist

1. **Fixed IPs:** on each VM go to Networking, click the network interface, then IP configurations > ipconfig1, and set it to **Static** with this address (the VM may restart, which is fine):
   - wazuh: `10.0.1.10`
   - win-srv: `10.0.1.20`
   - linux-srv: `10.0.1.30`
2. **Lock down RDP:** win-srv > Networking > the RDP inbound rule > change Source from "Any" to **My IP address**, then Save. If your home IP changes (new Wi-Fi, campus vs home), update this rule.
3. **Connect:** open **Windows App** on your Mac (Mac App Store), add a PC with win-srv's public IP, and log in as `labadmin`.
4. Next guide: the "prepare the lab" runbook in `lab/runbooks/` for installing Wazuh, firewall rules and Windows audit settings.

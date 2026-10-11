# Azure notes for the lab

These go with `azure-setup-plan.md`. The layout is: one VNet (`homelab-vnet`), one subnet `lab-subnet` = `10.0.1.0/24`, everything in resource group `homelab-rg`. All values here are placeholders. Never commit your subscription ID, public IP, passwords or SSH keys.

| VM | Private IP | Public IP | Reachable from the internet |
|---|---|---|---|
| `wazuh` | 10.0.1.10 | none | no |
| `win-srv` | 10.0.1.20 | yes | RDP (3389) from **your home IP only** |
| `linux-srv` | 10.0.1.30 | none | no |

## Two layers of firewall, and which one the exercises use

- The **Network Security Group (NSG)** is Azure's firewall in front of each VM. It's what keeps the internet out. Its default rules allow traffic **inside** the VNet (`AllowVnetInBound`) and block everything else coming in (`DenyAllInBound`).
- **UFW** is the firewall **inside** `linux-srv`, turned on by `lab/linux/setup-linux-srv.sh`.

The blocked-connection and port-scan exercises run between VMs inside the VNet, so the NSG lets that traffic through and **UFW** is what blocks it. That's deliberate: UFW writes each block to the server's log, the Wazuh agent ships that log, and you get an alert. NSG blocks never reach the VM, so Wazuh can't see them. You'd need NSG flow logs and a storage account for that, which costs money and is out of scope.

## Inbound NSG rules you should end up with

On `win-srv`'s NSG (`win-srv-nsg` if you accepted the default name):

| Priority | Name | Source | Port | Action |
|---|---|---|---|---|
| 300 | RDP (edited) | **My IP address** (your home IP) | 3389/TCP | Allow |
| 65000 | AllowVnetInBound | VirtualNetwork | any | Allow (default) |
| 65500 | DenyAllInBound | any | any | Deny (default) |

On `wazuh` and `linux-srv`: **no custom inbound rules**, only the defaults. The agents talk to Wazuh on 1514/1515 inside the VNet, which `AllowVnetInBound` already allows. Don't add a rule that opens 22, 443 or 1514 to the internet.

📸 Screenshot each VM's **Networking** tab (with your home IP blurred). It's good evidence for the security-policy part of the write-up.

### Check from Cloud Shell (the `>_` icon at the top of the portal)

```bash
az network nsg list --resource-group homelab-rg --output table
az network nsg rule list --resource-group homelab-rg --nsg-name win-srv-nsg --output table
```

If your home IP changes (it can, with home internet), RDP will stop working. Fix it under `win-srv` > **Networking** > the RDP rule > Source > **My IP address** > Save.

## Auto-shutdown and stopping

Set auto-shutdown on every VM (VM > **Operations > Auto-shutdown**), or from Cloud Shell. The time is in **UTC**: 11:00 PM Pacific is `0600` (`0700` in winter):

```bash
for vm in wazuh win-srv linux-srv; do
  az vm auto-shutdown --resource-group homelab-rg --name "$vm" --time 0600
done
```

Stopping to save money at the end of a session (this "deallocates" them, which stops compute billing):

```bash
az vm deallocate --resource-group homelab-rg --name win-srv --no-wait
az vm deallocate --resource-group homelab-rg --name linux-srv --no-wait
az vm deallocate --resource-group homelab-rg --name wazuh --no-wait
```

Starting again: start `wazuh` first so the agents can reconnect, then the other two.

```bash
az vm start --resource-group homelab-rg --name wazuh
az vm start --resource-group homelab-rg --name linux-srv --no-wait
az vm start --resource-group homelab-rg --name win-srv --no-wait
```

## Microsoft's rules for testing in Azure

You may scan and test **your own** Azure resources without asking Microsoft first, as long as you follow their Penetration Testing Rules of Engagement. Practically, for this lab: keep scans inside `10.0.1.0/24`, never target other customers or Microsoft services, and don't run denial-of-service tests. The lab's Linux scripts refuse any target outside `LAB_SUBNET`.

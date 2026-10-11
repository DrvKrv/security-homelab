# 00 · Prepare the lab

Do this once, after the three VMs from `setup-plan.md` are built and both agents show **Active** in the Wazuh dashboard. It takes about 45 minutes.

| VM | Placeholder IP | Role in the exercises |
|---|---|---|
| `wazuh` | 192.168.50.10 | SIEM, and also plays the "attacker" (saves RAM vs. a 4th VM) |
| `win-client` | 192.168.50.20 | Employee laptop: failed logons, rogue admin account |
| `linux-srv` | 192.168.50.30 | Company server: SSH brute force, firewall blocks, port scan |

Replace these with your real IPs everywhere (find them with `ip -br addr` on Linux and `ipconfig` on Windows).

## 1. Get the lab files onto each VM

**Linux VMs (`wazuh` and `linux-srv`)**, in each VM's terminal or over SSH from your Mac:

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/DrvKrv/security-homelab.git
cd security-homelab/lab
cp lab.env.example lab.env
nano lab.env            # put in your real IPs, then Ctrl+O, Enter, Ctrl+X
```

If the repo is private, `git clone` will ask you to sign in. The easy alternative is to copy the folder from your Mac: `scp -r security-homelab/lab <user>@<vm-ip>:~/`.

**Windows (`win-client`)**: in Edge, open the repo on GitHub, click **Code > Download ZIP**, extract it, then in an **administrator** PowerShell:

```powershell
cd $HOME\Downloads\security-homelab-main\lab\windows
Get-ChildItem *.ps1 | Unblock-File          # files from the internet are blocked by default
Set-ExecutionPolicy -Scope Process Bypass   # only for this PowerShell window
```

You'll repeat the `Set-ExecutionPolicy` line every time you open a new admin PowerShell window.

## 2. Install the lab rules on the Wazuh manager

On the **wazuh** VM:

```bash
cd ~/security-homelab/lab/wazuh
sudo bash setup-manager.sh
```

It backs up the old files, installs `local_rules.xml` and `local_decoder.xml`, creates the `windows` and `linux` agent groups, checks the config, and restarts the manager. If the config check fails it stops without restarting, so Wazuh keeps working.

### Put each agent in its group

```bash
sudo /var/ossec/bin/agent_control -l
```

That lists agents like `ID: 001, Name: win-client, IP: any, Active`. Your Windows agent may be called something like `DESKTOP-AB12CD3` instead; that's fine, just use that name wherever the runbooks say `win-client`. Use the IDs:

```bash
sudo /var/ossec/bin/agent_groups -a -i 001 -g windows -q
sudo /var/ossec/bin/agent_groups -a -i 002 -g linux -q
```

Within about 5 minutes each agent downloads its group config. You can check in the dashboard under **Agents > (agent) > Groups**.

### Test the rules without touching any VM

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Paste the lines from [`../wazuh/manager/logtest-samples.txt`](../wazuh/manager/logtest-samples.txt) one at a time. Each one says which rule it should hit. 📸 **Screenshot** the UFW line hitting rule `100100`, because it shows you wrote and tested a custom detection.

If a line doesn't match what the file says, copy the whole logtest output and send it to Claude.

## 3. Turn on Windows auditing

Windows doesn't record most of the events we need until you tell it to. On **win-client**, in the admin PowerShell from step 1:

```powershell
.\Enable-AuditPolicy.ps1
```

📸 **Screenshot** the `auditpol` and `net accounts` output at the end. In Wazuh you should see rule **60112 "Windows Audit Policy changed"** for win-client within a minute or two. That's your first proof that Windows → Wazuh works.

Then create the test account that the failed-logon exercise targets (pick any password and **don't reuse a real one**):

```powershell
$pw = Read-Host -AsSecureString "Password for labuser"
New-LocalUser -Name labuser -Password $pw -FullName "Lab User" -Description "Lab test account"
Add-LocalGroupMember -Group Users -Member labuser
```

## 4. Prepare the Linux server

On **linux-srv**:

```bash
cd ~/security-homelab/lab/linux
sudo bash setup-linux-srv.sh
```

This turns on the UFW firewall (SSH allowed from the lab subnet only, everything else blocked and logged), creates `labuser` with a random password nobody knows, and makes sure SSH logs failed password guesses. 📸 **Screenshot** the `ufw status verbose` output.

## 5. Snapshot everything

Take a snapshot of each VM and name it `baseline`. If an exercise goes wrong, restore it and start again.

- **VMware Fusion (Mac):** Virtual Machine > Snapshots > Take Snapshot.
- **Cloud VMs:** use your provider's snapshot or image feature for each instance's disk.

## 6. Where to look in Wazuh

All the runbooks use the same screen: **☰ menu > Threat intelligence > Threat Hunting > Events** (in some versions the menu item is just called **Threat Hunting** or **Security events**). Then:

- Set the time picker (top right) to **Last 1 hour**.
- Type a query in the search bar, for example `rule.id:60122`, and press Enter.
- Click **>** on a row to expand it and see every field.
- To keep a column visible, hover a field name in the left list and click **+** (useful ones: `agent.name`, `rule.id`, `rule.description`, `data.srcip`, `data.win.eventdata.targetUserName`).

## Evidence habits

- The scripts save their output to `~/lab-evidence/` (Linux) and `C:\LabEvidence\` (Windows).
- Name screenshots `NN-short-description.png`, for example `01-60204-multiple-logon-failures.png`.
- Before anything goes on GitHub, blur or crop your real IPs if you care about that, and **never** include the Wazuh admin password, agent keys (`/var/ossec/etc/client.keys`) or `lab.env`.

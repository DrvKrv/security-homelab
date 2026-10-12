# Homelab setup plan: Azure for Students

How the core lab (unit 1) was built. An earlier plan to run it on a laptop was dropped. The lab is the same: 3 VMs, Wazuh watching them, and incidents you stage and investigate. It just runs in Microsoft's data center instead of on your laptop.

## Step 0: Sign up for Azure for Students

- Go to **azure.microsoft.com/free/students** and sign up with a school email. Microsoft verifies it at sign-up.
- It comes with yearly credit and needs **no credit card**. If the credit runs out, Azure just stops your VMs, so there's no surprise bill.
- Student accounts have some limits on which VM sizes and regions you can use. If Azure says a size or region is "not available" or "quota exceeded", try another US region (e.g. West US 2, West US 3, East US 2). If that doesn't work, tell me what the error said.

## Step 1: Set a budget alert (do this first)

Portal > **Cost Management > Budgets** > create a small budget with email alerts at 50% and 90%. This is your early warning if something is left running.

## Step 2: Create the lab network

1. Create a **resource group** called `homelab-rg`. A resource group is a folder that holds everything in the lab. Put every resource below in it and in the same region.
2. Create a **virtual network** `homelab-vnet` with address space `10.0.0.0/16` and one subnet `lab-subnet` at `10.0.1.0/24`.
   - If the subnet screen has an **"Enable private subnet"** box, **uncheck it**. Otherwise your VMs can't reach the internet to download Wazuh and updates.
3. VMs in the same subnet can talk to each other automatically. Azure blocks everything coming in from the internet unless you allow it.

## Step 3: Create the 3 VMs

These are normal Intel/AMD (x86) VMs, so the Apple-chip issues from the Mac plan no longer apply.

| VM | Role | Image | Size | Disk | Fixed private IP |
|---|---|---|---|---|---|
| `wazuh` | The SIEM | Ubuntu Server 24.04 LTS | **B2as_v2** (2 vCPU, 8 GB) | 50 GB Standard SSD | 10.0.1.10 |
| `win-srv` | Windows machine | **Windows Server 2025 Datacenter** (2022 also works) | **B2als_v2** (2 vCPU, 4 GB) | 127 GB default, Standard SSD | 10.0.1.20 |
| `linux-srv` | Linux server | Ubuntu Server 24.04 LTS | **B2ats_v2** (2 vCPU, 1 GB) | 30 GB Standard SSD | 10.0.1.30 |

Notes on the choices:
- **Windows Server instead of Windows 11.** Azure only lets you run Windows 11 if you bring your own special license. Windows Server's license is included in the price, and it records the same login and account events. Real companies' security teams watch servers like this all the time.
- When creating each VM:
  - **Public IP:** give one **only to `win-srv`**. Set the other two to "None".
  - **Inbound ports:** on `win-srv`, allow **RDP (3389)**. Afterwards, edit that rule in its Network Security Group so **Source = "My IP address"**, which means only your home internet can reach it. Allow no inbound ports on the other two.
  - **Login:** use a strong password for Windows. For the Linux VMs, let Azure generate an SSH key and **save the downloaded key file somewhere safe** (never put it on GitHub).
  - **Auto-shutdown** (under Management): turn it on for every VM, e.g. at 11:00 PM your time. That protects your credit if you forget to stop the VMs.
- After each VM is created, go to its network interface > IP configurations and set the private IP to **Static** with the address from the table.

## Step 4: Get into your lab

- **Windows:** open **Windows App** on your Mac (free in the Mac App Store, formerly "Microsoft Remote Desktop"). Connect to `win-srv`'s public IP and log in.
- **Linux VMs:** from inside `win-srv`, open PowerShell and run `ssh <username>@10.0.1.10`. Windows Server has ssh built in. Copy your private key file to `win-srv` to use it.
- **Wazuh dashboard:** open Edge inside `win-srv` and go to `https://10.0.1.10`.

So `win-srv` is your single doorway in, and nothing else in the lab is reachable from the internet.

## Step 5: Install Wazuh

On `wazuh`, run the official all-in-one **Quickstart** install (documentation.wazuh.com > Quickstart). It's a single command. **Save the admin password it prints at the end** in a password manager, and keep it out of anything you publish.

## Step 6: Connect the other VMs to Wazuh

In the dashboard, go to **Agents > Deploy new agent**. Pick the OS (Windows, or Linux DEB amd64), enter `10.0.1.10` as the server address, and run the command it gives you on `win-srv` and on `linux-srv`.

## Step 7: Prove it works

Both agents should show **Active**. Then SSH to `linux-srv` with a wrong username 5–10 times (e.g. `ssh fakeuser@10.0.1.30`). You should see "authentication failed" alerts in Wazuh within a minute or so. Once you do, setup is done, and we move on to the real exercises (Windows audit settings, staged incidents, investigation, vulnerability scanning, fixes, write-up).

## Money rules

- **Stop VMs from the Azure portal** (the **Stop** button, so the status says "Stopped (deallocated)"). Shutting down from inside Windows/Linux **keeps billing**.
- Disks and the public IP are charged even while the VMs are stopped, so delete what you no longer need.
- When the project is finished and documented, **delete the `homelab-rg` resource group**. That deletes everything in it and stops all charges.

## Rules of the road

- Port scans and attack simulations stay **inside your VNet, against your own VMs**. Microsoft allows testing your own resources. Scanning anything else, including other Azure customers, is not allowed.
- Take **screenshots and notes as you go**. They become your GitHub case study.
- Never commit passwords, SSH keys, or your public IP to GitHub.

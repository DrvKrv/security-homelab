# Concepts: what the core lab is and why

Written 2026-10-11/12 while the core lab (unit 1) was being built, so a few lines
describe steps that are now done (Wazuh installed, agents connected).

## Part 1: what was built and why

### The goal
Show a recruiter you understand the defensive-security workflow: **detect, investigate, fix, report**. The VMs are just the stage. The evidence is the write-up.

### What exists so far, and why each piece is there

| Piece | What it is | Why it matters |
|---|---|---|
| Azure for Students account + budget alert | Your cloud "datacenter" and a spending guardrail | Cloud cost control is a real job skill |
| `homelab-rg` resource group | A folder holding every lab resource | Deleting it at the end removes everything and stops charges |
| `homelab-vnet` / `lab-subnet` (10.0.1.0/24) | A private network | Network segmentation. Machines talk to each other, not to the world |
| `wazuh` (10.0.1.10) | The SIEM: collects logs, raises alerts | This is the analyst's main tool |
| `win-srv` (10.0.1.20) | Windows machine, the only one with a public IP | The "employee PC" that generates Windows login events. Also your only door in |
| `linux-srv` (10.0.1.30) | Linux machine | The source of Linux auth/system logs |
| NSG rules (firewalls) | Which traffic each VM allows | Least privilege: only your IP can reach RDP, nothing else is exposed |

### Questions to be able to answer in an interview
Try answering these from memory, then check:
1. Why does only win-srv have a public IP? What attack surface does that create, and how did we reduce it?
2. What is a SIEM, and what does an agent do?
3. Why Standard SSD, auto-shutdown and a budget alert?
4. Why Windows Server instead of Windows 11 here?
5. What's the difference between a private IP (10.0.1.10) and a public IP?
6. Why did we restrict RDP to "My IP address"?

### Where the real learning starts
Setup is mostly following steps. The learning is in steps 4–7 of the project: you will make failed logins happen, find them in the logs yourself, work out which account and machine were involved, and rank vulnerabilities by risk. Those parts can't be copied from a guide, and they're what you'll talk about in interviews.

## Part 2: the security ideas behind each choice

### The big picture in one paragraph

A company's security team has three jobs: **keep attackers out** (prevention), **notice when something happens anyway** (detection), and **figure out what happened and fix it** (response). So far you've built the prevention layer (a private network, firewalls, one locked door) and you're installing the detection layer (Wazuh). The incidents, investigation and remediation still to come are the response layer. Every choice so far serves one of those three.

### The ideas behind what you built

#### 1. Network segmentation: the private subnet
Your VMs live on 10.0.1.0/24, a private range that the internet can't route to. Think of it as an office building: machines inside talk freely, but the street can't walk in.
- **Real-world version:** companies split networks into zones (users, servers, payment systems) so one compromised laptop can't reach everything.
- **Net+:** private IP ranges (RFC 1918: 10.x, 172.16–31.x, 192.168.x), CIDR notation (/16 = 65,536 addresses, /24 = 256), subnetting.
- **Sec+:** segmentation, secure network architecture.

#### 2. Attack surface: why only one public IP
Every service reachable from the internet is something an attacker can poke. Your lab exposes exactly **one port (3389, RDP) on one machine**, and only to your home IP. The other two machines have *no* public address at all.
- Unprotected RDP is one of the most common ways ransomware gangs get in. Bots scan the whole internet for port 3389 constantly. Restricting the source to your IP removes you from that game.
- **Sec+:** attack surface reduction, hardening.

#### 3. Jump host (bastion): win-srv as the only door
To reach wazuh or linux-srv you go *through* win-srv. This is a standard pattern: one hardened, monitored entry point instead of many.
- **Trade-off to notice:** if win-srv is compromised, the attacker has the same path you do. That's why the door itself needs strong auth and monitoring. (Azure sells "Azure Bastion" as a managed version; we skipped it because it costs money.)
- **Sec+:** jump servers, secure access.

#### 4. Least privilege: NSGs and "allow nothing by default"
Network Security Groups are firewalls. Azure's default is **deny all inbound from the internet**; you then allow only what's needed. Soon you'll add a rule for ports 1514/1515 so agents can talk to Wazuh, and nothing more.
- The principle: give every person, program and connection the minimum access it needs. It applies to user accounts too (you'll see this with Windows admin accounts later).
- **Net+:** ports and protocols, ACLs. **Sec+:** least privilege, implicit deny.

#### 5. Key vs. password authentication
Linux VMs use an SSH key; Windows uses a long password.
- A password is a secret you *send* (and can be guessed or phished). An SSH key pair keeps the private half on your machine and proves you hold it without ever sending it. Brute-forcing a key is not practically possible.
- That's also why you can't use a key file twice-downloaded: Azure never stored your private key. Losing it means losing access, which is the price of the security.
- **Sec+:** authentication factors, public-key cryptography (asymmetric keys).

#### 6. SIEM and log collection: what Wazuh is for
Each machine already writes logs (Windows Event Log, Linux `/var/log/auth.log`). The problem is that nobody reads logs spread across 50 machines. A **SIEM** pulls them into one place, normalizes them, and runs **rules** that turn raw lines into **alerts** ("5 failed logins for user X in 1 minute").
- **Agent:** a small program on each machine that ships its logs to the SIEM. The server is the brain; agents are the sensors.
- **Key point:** a SIEM only sees what's logged. Windows doesn't log some things (like process creation) by default. That's why the audit-policy step matters: no log, no alert, no evidence.
- **Sec+:** SIEM, log aggregation, alerting, security operations.

#### 7. Patch management: why patching is off on purpose
Automatic updates are off so the VMs drift out of date. Later you'll scan them, find outdated software, look up its **CVE** (the public ID for a vulnerability), its **CVSS** score (0–10 severity), decide what to fix first, patch it, and prove the fix worked.
- In a real job you'd never leave patching off. Here it's a controlled way to create something to find.
- **Sec+:** vulnerability management, CVE/CVSS, remediation and validation.

#### 8. Cost and blast-radius controls
The budget alert, auto-shutdown and "delete the resource group at the end" aren't security in the hacker sense, but they're the same instinct: **plan for the mistake before it happens.** Security people call this defense in depth: several independent safeguards so one failure doesn't become a disaster.

### How it connects (the flow you're about to see)

```
linux-srv / win-srv  --(agent ships logs, port 1514)-->  wazuh  --(rules)-->  alert on dashboard
        ^                                                                          |
   you generate an event                                          you investigate it in the dashboard
   (failed logins, new user, port scan)                           (who, what, when, from where)
```

Once this loop works, every exercise in the project is a variation: cause something, see whether Wazuh caught it, explain what it means, fix the cause.

### How to learn actively from here

1. **Predict before you run.** Before each command or click, say (or write) what you expect it to do. If you're wrong, that gap is where you learn.
2. **Ask "what would an attacker do with this?"** For each setting: what does it protect against, and what's still exposed?
3. **Break it on purpose (safely).** Example: temporarily remove the NSG rule for 1514 and watch the agent go "Disconnected". Now you *know* why the rule exists.
4. **Read the raw log, not just the alert.** Click into an alert and find the original Windows event or `auth.log` line. Alerts are summaries; analysts work from evidence.
5. **Keep a lab journal.** A few lines per session: what you did, what surprised you, what you'd ask. It becomes your case-study draft for free.
6. **Explain it back.** If you can explain a step to a friend in two sentences, you understand it. If you can't, ask here.

### Self-check (beyond the ones in Part 1)

1. If an attacker stole your SSH private key, what could they do, and what's the first thing you'd do?
2. Why might a SIEM miss an attack completely? (Hint: logging.)
3. Your agent shows "Disconnected". Name three things that could cause that.
4. Why is "deny by default, allow by exception" safer than the reverse?
5. In 10.0.1.0/24, how many usable host addresses are there, and why not 256?

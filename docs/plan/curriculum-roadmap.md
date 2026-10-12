# Homelab curriculum: the whole roadmap

Last updated 2026-10-12. This is the map of the whole project. The other files in
this folder hold the details (see [README.md](README.md)).

**Every lesson, level by level, and the path through them:** [curriculum-lessons.md](curriculum-lessons.md).

**Status key**
- ✅ **Done**
- 🔄 **In progress**
- 📦 **Built, not deployed**: the code is merged into the repo, no VM yet
- 📝 **Plan only**: nothing built

**The one rule:** Units 1 and 2 come first. They are the case study, and nothing
after them should delay finishing it.

---

## At a glance

| # | Unit | Status | New VM? | Main skill |
|---|---|---|---|---|
| 1 | Build the lab | ✅ | built | Cloud setup, networking, SIEM install |
| 2 | First incidents + case study | 🔄 | none | The defender workflow: detect, investigate, fix, report |
| 3 | Practice range | 🔄 round 1 built | none | Repetition on the same skills, harder each level |
| 4 | Detection engineering | 📝 | none | Writing and testing your own alerts |
| 5 | Lab as code (Terraform) | 📦 | none | Infrastructure as code, cloud engineering |
| 6 | Company website (web-srv) | 📦 | Linux | Web security, vulnerability management |
| 7 | Company accounts (dc01, Active Directory) | 📦 | Windows | Identity and access |
| 8 | Network zones | 📝 | none | Segmentation, firewalls, network monitoring |
| 9 | Busy office | 📝 | none | Threat hunting in normal noise |
| 10 | Capstone breach | 📝 | none | Full incident response, final report |

Running alongside every unit: **GRC** (risk, policy, audits) and **Security+** study.
Optional later: **DevSecOps pipeline** and **container security**.

---

## Unit 1. Build the lab ✅

What exists:
- ✅ Azure for Students account, budget alert, `homelab-rg`, network 10.0.1.0/24
- ✅ Three VMs: `wazuh` (10.0.1.10), `win-srv` (10.0.1.20, your only way in), `linux-srv` (10.0.1.30)
- ✅ Wazuh installed, both agents Active, Windows audit policy on
- ✅ Repo: case-study README + doc templates (PR #1), lab configs, rules and simulation scripts (PR #2)

You learned: cloud resource setup, private networking, firewalls (NSGs), what a SIEM and an agent do.

## Unit 2. First incidents + case study 🔄

This is your original 9-step checklist. It's the heart of the case study.

| Step | Status |
|---|---|
| Incident 1: failed SSH logins on linux-srv | ✅ investigated by hand |
| Incident report IR-2026-001 | 🔄 drafting |
| More incidents: account changes, blocked connections, authorized port scan | 📝 scripts exist, not run yet |
| Vulnerability research: outdated software, CVEs, CVSS, NVD | 📝 |
| Remediation: fix a few, prove they're fixed | 📝 |
| Docs: asset inventory, network diagram, remediation ticket, security policy | 📝 templates exist |
| Publish the case study on GitHub | 📝 |

You learn: the core defender workflow, and writing it up so a recruiter can follow it.

## Unit 3. Practice range 🔄 (`lab/exercises/`, merged)

The lesson grid from [curriculum-lessons.md](curriculum-lessons.md), as a runner:
`./run.sh list` shows every box and how many of its lessons you can run now. Each
lesson quietly stages an incident; you find it, work it out, and check yourself
with hints, the answer key or `./run.sh verify`.

| Round | Status |
|---|---|
| 1 (current three VMs) | ✅ written: every A, B, C, D box at L1–L3 has a lesson. 📝 Not yet run on the live VMs |
| 2–8 (later environments) | 🔄 some written as readable briefs; tracks E and G and most L4/L5 boxes still to write |

L1 and L2 lessons overlap with Unit 2, so they count toward the case study too.
A4 "write your own first Wazuh rule" is where you write a rule yourself (the earlier rules are worked examples).

## Unit 4. Detection engineering 📝 (no new VMs)

In Unit 2 you *read* alerts. Here you *build* them.
- **Sysmon** on win-srv: logs what happens after a login, not just the login.
- **Your own rules**, kept in the repo and tested against sample logs ("detection as code").
- **MITRE ATT&CK mapping**: tag every rule and incident with its technique ID, then publish a coverage map.
- **Atomic Red Team**: an established test library that simulates one technique at a time. Did your rule fire? If not, fix it and retest ("purple teaming").
- **Suricata**: network intrusion detection, so scans show up as network alerts too.
- **Active response**: auto-block an IP after repeated failures (test on linux-srv only, never win-srv).
- Optional: Microsoft **Defender for Cloud** free tier on your Azure account.

## Unit 5. Lab as code (Terraform) 📦 (`infra/`, merged)

The whole lab described in files under `infra/`, so it rebuilds with one command.
Do it **before Unit 6**, so web-srv is the first machine you build with code.

How you learn it (not just run it):
1. **Read and predict:** read the commented network and firewall files; you predict what `terraform plan` will do.
2. **Change:** small edits, and see `plan` explain each one.
3. **Write:** you write the dc01 file yourself, using the web-srv file as your example.
4. **Fix a planted mistake:** find a risky setting with a scanner and fix it.
5. **Import:** bring your 3 hand-built VMs under code.

Useful beyond security: cloud engineering, cloud security, and reproducible, auditable systems.
The starting files are merged and pass `terraform validate`. Nothing has been planned or
applied yet: `terraform init` + `plan` in Azure Cloud Shell is the first step.

## Unit 6. Company website: web-srv 📦 (PR #5, merged)

Built: the Acme company site, an employee portal that logs every login, OWASP Juice Shop
as the practice target (official image, never public), install/verify/reset scripts, Wazuh config.
Deploy: Linux VM at 10.0.1.40, switched on only while in use.

You learn: web app security (OWASP Top 10), web logs vs host logs, vulnerability scanning,
CVE research on real software, patch and re-scan, secure code (compare the portal to Juice Shop).
Optional here: **container security** (scan and harden the Docker images).

## Unit 7. Company accounts: dc01 📦 (PR #5, merged, not yet tested on Windows)

Built: scripts that turn a Windows Server into the `acme.lab` domain controller and fill it
with a random fake staff, departments and groups.
Deploy: Windows VM at 10.0.1.50, switched on only while in use.

You learn: Active Directory, least privilege (who's an admin and shouldn't be), password
policy, logon baselining. Later: detecting identity attacks like password spraying.

## Unit 8. Network zones 📝 (written in Terraform)

Split the network into a DMZ (web-srv) and an internal zone (dc01, wazuh) with firewall
rules between them. Prove a compromised web server can't reach the domain controller.
You learn: segmentation, firewall design, and why Azure limits network monitoring.

## Unit 9. Busy office 📝 (placeholder in `lab/stages/`)

A generator that makes the fake staff act like people: logins, browsing, typos, odd hours,
harmless-but-suspicious red herrings. Randomized and silent.
You learn: baselining "normal", threat hunting, tuning out false positives.

## Unit 10. Capstone breach 📝

A multi-step scenario across the whole company, which can fire at a random time
("surprise mode"). You run the full response and write the final report: the centerpiece
of the case study.

---

## Running alongside every unit

- **GRC:** risk register, policies with evidence, a mini audit of Acme against a checklist (e.g. CIS Controls).
- **Security+:** study the chapter that matches the unit you're on.
- **Write-ups:** every unit ends with a short note in the repo, redacted per the publishing checklist.
- **Optional DevSecOps:** a GitHub Actions pipeline that scans the repo for secrets and risky Terraform on every push.

## Parked on purpose (mention as "what I'd do next")

Kubernetes, a second office site, malware analysis, threat-intel platforms. Each is a
project of its own. Naming them as next steps in an interview shows judgment without
the risk of never finishing.

## Old names → units

| You may have seen | Now |
|---|---|
| Phase 1 checklist | Units 1–2 |
| Exercises, Levels 1–5 | Unit 3 |
| Phase 2 steps 1, 2, 4, 5, 6, 7 / "Stage 1" | Unit 4 |
| Phase 2 step 3 (AD) / "Stage 3" / `lab/stages/3-dc01` | Unit 7 |
| "Stage 2" / `lab/stages/2-web-srv` | Unit 6 |
| Stages 4, 5, 6 | Units 8, 9, 10 |
| Ambition tracks A, B, C, D | Unit 5, Unit 4, DevSecOps, container security (Unit 6) |

## Where the details live

- Phase 1 setup: [azure-setup.md](azure-setup.md), [vm-create-settings.md](vm-create-settings.md)
- The ideas behind the lab: [concepts.md](concepts.md)
- Detection engineering: [detection-engineering.md](detection-engineering.md)
- Stages, deploy steps, randomness, lab as code: [expansion-stages.md](expansion-stages.md)
- In the repo: `lab/exercises/README.md`, `lab/stages/README.md`, `infra/README.md`

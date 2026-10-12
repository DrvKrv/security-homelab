# CLAUDE.md

Handoff notes for Claude (or anyone) picking up work in this repo. Read this
first, then [docs/plan/curriculum-roadmap.md](docs/plan/curriculum-roadmap.md).

## What this repo is

A defensive-security homelab in Azure, documented as a public case study. A
small simulated company network sends logs to a Wazuh SIEM; the owner (KT)
stages incidents, investigates them, researches and fixes vulnerabilities, and
writes it all up. It grows unit by unit into a fake company ("Acme") that KT
defends. One focused project, not a pile of experiments.

## How to work with KT

KT is new to homelabs and wants to **learn**, not just follow steps.

- **Explain the why** behind each step, in plain language.
- **Ask KT to predict** what a command or change will do before running it.
- **Let KT do the parts where the learning is:** investigating alerts, writing
  incident reports, writing their own Wazuh rules and Terraform files. Claude
  provides worked examples, hints and answer keys, not the finished answer.
- **"Could we…?" / "Would it be a good idea…?" are questions, not build
  requests.** Answer them. Don't start building until KT says go.
- Do the hands-off work yourself (docs, configs, scripts, repo upkeep), as
  draft PRs for KT to review.

## Rules that always apply

- **The repo is public.** Never commit secrets, passwords, keys, real public
  IPs, home IP, Azure subscription/tenant IDs, or Terraform state. Use
  `<REDACTED>` or placeholders. See [docs/publishing-checklist.md](docs/publishing-checklist.md).
  Never invent findings: a result only goes in the docs once KT actually got it.
- **Staging and simulation scripts run quietly.** They print only "done" (or
  an error), never what they did, which account, or when, because that spoils
  the investigation. Answers come only through `hint`, `reveal` or a clearly
  named spoilers/answers folder. Start screens and briefs don't name rule IDs,
  event IDs or the account to find.
- **Randomize** simulated details so repeating an exercise doesn't repeat the answer.
- **Attack activity stays inside the lab:** VM-to-VM within 10.0.1.0/24, never
  through the public RDP door, never against anything KT doesn't own.
- **Don't write new attack or exploit code.** Reuse the existing simulation
  scripts in `lab/linux/` and `lab/windows/`, standard admin tools, established
  training apps from their official images (OWASP Juice Shop), and published
  Atomic Red Team test IDs. Build the defensive and infrastructure pieces.
  Deliberately vulnerable apps must never get a public IP (installers check).
- **Incident reports are KT's.** They live in `docs/incidents/IR-YYYY-NNN-name.md`
  with screenshots in `docs/evidence/`. KT writes them on a branch and opens the
  PR; Claude reviews and comments without rewriting KT's analysis.
- **Claude can't reach the VMs.** It has no Azure login, and win-srv's RDP only
  accepts KT's IP. Build and test in the repo (Docker works in Claude's
  sandbox); KT deploys and runs things on the VMs. Don't create Azure resources.

## The lab

Azure, West US 2, resource group `homelab-rg`, VNet 10.0.0.0/16, `lab-subnet`
10.0.1.0/24.

| VM | IP | Role |
|---|---|---|
| `wazuh` | 10.0.1.10 | Ubuntu 24.04, Wazuh all-in-one; dashboard at https://10.0.1.10 |
| `win-srv` | 10.0.1.20 | Windows Server 2025. **Only public IP**, RDP from KT's IP only; the jump host for everything else |
| `linux-srv` | 10.0.1.30 | Ubuntu 24.04, small VM. **Key-only SSH** (password auth off) |
| `web-srv` | 10.0.1.40 | Planned (unit 6), no public IP |
| `dc01` | 10.0.1.50 | Planned (unit 7), `acme.lab` domain controller, no public IP |

Both existing agents report to Wazuh; Windows audit policy (logon, user account
management) is on. Automatic patching is off on purpose so there's something to
find. Verified behavior worth knowing: an invalid SSH user triggers rule 5710
then 5712 (brute force, level 10); a real user rejected by key-only auth only
gives 5762 (level 4) with no correlation rule, a detection gap KT noticed.

## Repo map

| Path | What |
|---|---|
| `README.md` | The case study (recruiter-facing). `TODO`s get filled only with real results |
| `docs/` | Asset inventory, network diagram, policy, CVE worksheet, templates for incidents and tickets, publishing checklist |
| `docs/plan/` | **The plans:** roadmap, lesson grid, setup guides, later units |
| `lab/wazuh/`, `lab/linux/`, `lab/windows/`, `lab/runbooks/` | Wazuh rules/decoders, simulation scripts, setup runbook |
| `lab/exercises/` | Practice range: `./run.sh list / start / stage / hint / reveal / verify` |
| `lab/stages/` | Units 6–7: web-srv (site, portal, Juice Shop) and dc01 (AD scripts). Built, not deployed |
| `infra/` | Units 5+: Terraform for the lab, with KT exercises and an answers folder (draft PR #6) |

## The curriculum

Ten units ([roadmap](docs/plan/curriculum-roadmap.md)): 1 build the lab ·
2 first incidents + case study · 3 practice range · 4 detection engineering ·
5 lab as code (Terraform) · 6 web-srv · 7 dc01 / Active Directory ·
8 network zones · 9 busy office noise · 10 capstone breach. GRC and Security+
study run alongside every unit.

Lessons ([grid](docs/plan/curriculum-lessons.md)) are 7 concepts (A logins,
B accounts/privileges, C network, D vulnerabilities, E web, F processes/Sysmon,
G cloud/IaC) × 5 levels (L1 Spot, L2 Explain, L3 Respond, L4 Prevent, L5 Hunt),
2–5 randomized lessons per box, worked in 8 rounds, one per environment. Go
across before up; concepts spiral back in each new environment.

## Where things stand (2026-10-12)

- ✅ Unit 1: all three VMs built, Wazuh running, both agents active.
- 🔄 Unit 2: first incident (failed SSH on linux-srv from win-srv) investigated;
  KT is drafting IR-2026-001. Other incidents, vulnerability research,
  remediation, docs and the published case study are still to do. **Unit 2
  comes first.**
- 🔄 Unit 3: `lab/exercises/` merged (13 exercises, quiet staging); being
  reworked to follow the lesson grid. Tested in a container, not yet on the
  live VMs. Each VM needs its own clone of the repo to stage from it.
- 📦 Unit 5: `infra/` in draft PR #6. Only `terraform fmt` has run; first step
  is `terraform init` + `validate` in Azure Cloud Shell.
- 📦 Units 6–7: `lab/stages/` merged, not deployed. dc01 PowerShell is untested
  on real Windows. Attack scenarios and busy-office noise are placeholders.
- 📝 Units 4, 8, 9, 10: plan only.

When work lands, update the status markers here and in
`docs/plan/curriculum-roadmap.md`. Check open PRs before starting, since work
may be in flight on `lab/exercises/` and `infra/`.

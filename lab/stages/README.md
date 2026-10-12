# Lab stages: growing the lab into a small company

Phase 1 (the `lab/` scripts and `lab/exercises/`) gives you three machines and
a set of practice incidents. **Stages** take the same lab further: one at a time
they turn it into a small fake company ("Acme Corp") with a website, staff
accounts and more realistic network layers, so you can practise the rest of a
security team's job, not just reading a SIEM.

This folder is the **plan made real**: the code and scripts live here now, in the
repo, and you deploy a stage onto a VM only when you're ready. Nothing here
creates Azure resources or costs money by sitting in git.

See the full write-up: `/mnt/project-files/homelab/expansion-stages-plan.md`
(in the project, not the repo).

## The stages

| Stage | Folder | New VM | What it adds |
|---|---|---|---|
| 2 | `2-web-srv/` | `web-srv` (Linux, 10.0.1.40) | Company website, employee portal, a training target app, web logs in Wazuh |
| 3 | `3-dc01/` | `dc01` (Windows, 10.0.1.50) | Active Directory: a domain, staff accounts, groups |
| 4+ | *(later)* | none | Network zones, busy-office noise, a capstone breach |

Do the stages **after** Phase 1 (finish the incidents and the case study first),
and don't let them delay applying to internships.

## How every stage works the same way

1. **You create the VM** in the Azure portal — the only clicking you do. No public IP.
2. **Get in** the way you already reach the other VMs: RDP to `win-srv`, then SSH
   (Linux) or RDP (Windows) from there to the new VM.
3. **Clone the repo** on the VM: `git clone https://github.com/DrvKrv/security-homelab.git`
   (the repo is public, so no login or token is needed).
4. **Run that stage's installer** (`install.sh` or `Install-*.ps1`).
5. **Load any new Wazuh rules** on the `wazuh` VM (each stage's `wazuh/` folder says how).
6. **Run the stage's `verify`** script — it prints pass/fail for each check.

### Rules every stage follows

- **No real secrets in the repo.** Account passwords are generated **on the VM at
  install time** and never committed. The only weak passwords anywhere are
  obviously-fake ones that exist purely as training targets, and they only work
  inside your private lab.
- **Nothing dangerous is exposed.** The training target app and the portal are for
  the lab network only. `install.sh` **refuses to run on a VM that has a public IP**.
- **The target app is an established, trusted training app** (e.g. OWASP Juice Shop /
  DVWA) pulled from its official image — not something hand-written here. That's a
  deliberate choice: these apps are purpose-built, widely reviewed teaching tools,
  so you practise finding and fixing *known* classes of weakness against a
  well-documented target instead of a homemade one.
- **Generated data is random**, so you can't memorise one fixed company. Re-running
  the generator rolls a new roster; each roll saves its seed so you can reproduce it.

### Still to come (placeholders for now)

`2-web-srv/scenarios/` and a future noise generator are **documented placeholders**.
Attack-simulation and traffic-generation scripts are not written yet; for now the
target app's own built-in challenges give you plenty to detect and investigate.
The staged practice-exercise runner lives in `lab/exercises/` (a separate piece of
work) — these stages feed it realistic infrastructure to run against later.

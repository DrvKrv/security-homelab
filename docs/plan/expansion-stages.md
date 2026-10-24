# Expanding the lab: later stages with more VMs

> Part of the combined curriculum: stages 2–6 here are **units 6–10** in [curriculum-roadmap.md](curriculum-roadmap.md).

**Status (2026-10-12):** stages 2–6 are built in `lab/stages/` but not deployed.
Stage 2's scripted web-srv attack scenarios are still a documented placeholder (its
training app's own challenges cover that gap). Stage 5 (busy-office noise, `5-office/`)
and stage 6's automated breach conductor (`6-capstone/run-breach.sh`) are now built.
Lab as code (`infra/`) is merged. Builds on [detection-engineering.md](detection-engineering.md).

## The idea in one sentence

Your lab turns into a small fake company ("Acme"): one stage at a time it gets a website, then a company login system, then a separated network, then a full attack story you investigate end to end. I build the company; you defend it.

This still counts as **one focused project**, because every stage is the same company network getting more realistic. It is not a pile of separate experiments.

## The stages

| Stage | What gets added | New VM | What you do |
|---|---|---|---|
| **0. Finish Phase 1** | Nothing new | none | Finish the incidents, publish the case study |
| **1. Phase 2, no new VMs** | Sysmon, custom rules, ATT&CK tags, Atomic Red Team, Suricata, active response | none | Detection engineering (see [detection-engineering.md](detection-engineering.md)) |
| **2. Company website** | `web-srv` (Ubuntu): public-style homepage, employee portal with login, a deliberately vulnerable training app (OWASP Juice Shop, official image) | 1 Linux | Detect web attacks in Wazuh, scan it, research CVEs in its old software, patch, add a WAF |
| **3. Company accounts (Active Directory)** | `dc01` (Windows Server domain controller). win-srv joins the domain; the portal logs in with AD accounts | 1 Windows | Detect password spraying, Kerberoasting, sneaky admin-group changes |
| **4. Network zones** | Split the network into a DMZ (web) and an internal zone (dc01, wazuh) with firewall rules between them | none (subnets and NSG rules are free) | Design and test segmentation; prove a hacked web server can't reach the DC directly |
| **5. Busy office** (`5-office/`, built) | Scripts that make fake employees log in, browse, and use apps all day, so real attacks hide in normal noise | none | Find the needle in the haystack, tune out false positives |
| **6. Capstone breach** (`6-capstone/`, built) | A seeded multi-step attack conductor that chains the existing sims across VMs: recon, password guessing, a valid account, persistence, lateral probing | none | Full incident response and a final report: the centerpiece of your case study |

**One thing to check before stage 2:** some subscriptions (student ones especially) have a limit on how many CPU cores can be running in a region. Your three VMs use 6 cores. In the portal, go to Subscriptions > Usage + quotas and look at "Total Regional vCPUs" for West US 2. If the limit is 6, you'd need to stop another VM (or request more) before a 4th can start. (Worth ruling out before creating a 4th VM.)

## What you learn beyond the SIEM

The SIEM is just where alerts show up. A growing fake company lets you practice most of the other jobs on a security team. Each row says which stage gives you the hands-on practice.

| Skill area | What you'd actually do | Stages | Job titles it maps to |
|---|---|---|---|
| **Web app security** | Find and exploit OWASP Top 10 bugs (SQL injection, XSS, broken access control) in the Acme apps with Burp Suite, then fix them | 2, 6 | AppSec analyst, pentester |
| **Vulnerability management** | Scan the company (OpenVAS, OWASP ZAP), rank findings by CVSS and real risk, patch, rescan to prove the fix | 2, 3 | Vulnerability analyst |
| **Secure coding / code review** | Read the app source in the repo, spot the bug in the code, write the patch, add a dependency and secrets scanner to the repo | 2 | AppSec, DevSecOps |
| **Identity and access** | AD users, groups, password policy, least privilege, finding risky admin rights and stale accounts | 3 | IAM analyst, SOC |
| **System hardening** | Apply CIS Benchmark settings to Linux and Windows, then measure before and after | 2, 3 | Security engineer, auditor |
| **Network security** | Design zones, write firewall rules, watch traffic with Suricata and Wireshark, prove the web server can't reach the DC | 4 | Network security, SOC |
| **Threat hunting** | Search for attacker behavior that *didn't* trigger an alert, inside normal office noise | 5, 6 | SOC tier 2, threat hunter |
| **Incident response and forensics** | Build a timeline, scope which machines and accounts were touched, contain, recover, write the report | 6 | IR analyst |
| **Backup and recovery** | Back up the database and DC, "lose" them, restore, measure how long it took | 3, 6 | Security/IT ops, business continuity |
| **Cloud security** | Review Azure NSGs, Defender for Cloud findings, who has access to the subscription | 4 | Cloud security |
| **Governance, risk, compliance (GRC)** | Asset inventory, risk register, a short audit of Acme against a checklist (e.g. CIS Controls), policies with evidence | every stage | GRC / audit analyst |

**How this connects to Security+:** almost every row is a Security+ objective. Web attacks and hardening sit in Threats & Vulnerabilities, identity and network zones in Architecture, scanning/IR/hunting in Security Operations, and GRC in Program Management.

**Keep it focused:** you don't need every row. Pick 3 or 4 to go deep on, and the case study tells one story: "I defended a small company across its web, identity and network layers."

## IP plan (a small change from the roadmap)

| Machine | IP | Stage |
|---|---|---|
| wazuh | 10.0.1.10 | existing |
| win-srv | 10.0.1.20 | existing |
| linux-srv | 10.0.1.30 | existing |
| web-srv | 10.0.1.40 | 2 (moves to a DMZ subnet, e.g. 10.0.2.40, in stage 4) |
| dc01 | 10.0.1.50 | 3 (the Phase 2 roadmap suggested .40; web-srv now comes first) |

Rule for every stage: **none of the deliberately vulnerable apps ever gets a public IP.** You reach them from win-srv inside the lab, and attacks still run VM-to-VM inside the lab, same as your exercises.

## How you deploy a stage from the repo

The goal: creating a VM is the only clicking you do. Everything after that is "get the repo onto the VM, run one script, run one check."

### How the repo is laid out (planned shape; see `lab/stages/` for what exists)

```
lab/stages/
  2-web-srv/
    README.md        step-by-step guide with the why, and predict-first questions
    install.sh       sets up everything on web-srv (safe to run again)
    verify.sh        checks the apps are up and logs are reaching Wazuh
    apps/            the Acme website, portal, vulnerable app (Docker)
    wazuh/           agent config + custom rules for web logs
  3-dc01/
    README.md
    install.ps1      turns a fresh Windows Server into the Acme domain controller
    verify.ps1
    seed/            fake employees, groups, OUs
  ...
lab/wazuh/
  apply-rules.sh     run on the wazuh VM to load every stage's custom rules
```

### The flow for a Linux stage (web-srv)

1. **Create the VM** in the portal (same steps as linux-srv): `homelab-rg`, `lab-subnet`, **no public IP**, static private IP 10.0.1.40, auto-shutdown on. Or run the optional Azure template from Cloud Shell.
2. **Get in:** RDP to win-srv, then `ssh` from win-srv to 10.0.1.40, the same way you reach the wazuh VM today.
3. **Get the repo onto it:** `git clone https://github.com/DrvKrv/security-homelab.git`. The repo is public, so no token or login is needed.
4. **Run the installer:** `sudo ./lab/stages/2-web-srv/install.sh`. It installs Docker, starts the Acme apps, installs the Wazuh agent pointed at 10.0.1.10, and opens only the ports the lab needs.
5. **Load the new detection rules on Wazuh:** SSH to the wazuh VM, `git pull`, `sudo ./lab/wazuh/apply-rules.sh`.
6. **Check it:** `./verify.sh` says pass/fail for "site is up," "agent is Active," and "a test request shows up as a Wazuh event."
7. **Use it:** browse the apps from win-srv at http://10.0.1.40.

### The flow for a Windows stage (dc01)

Same idea: create the VM (no public IP, 10.0.1.50), RDP to win-srv, then RDP from win-srv to 10.0.1.50 (a "double hop"). Get the repo there with `git clone` (public repo, no login), run `install.ps1` in an admin PowerShell (it reboots once when it becomes a domain controller, and you run it again after), then run `verify.ps1`.

### How the simulated stuff actually runs

There are three kinds of moving parts, and the install script sets up all three:

| Part | What it is | How it runs | Who starts it |
|---|---|---|---|
| **The company's apps** | Acme website, portal, vulnerable app, database | Docker containers, set to restart automatically whenever the VM boots | Install script, once |
| **Fake employees ("busy office")** | Small programs that act like people: log in to the portal, browse pages, open files, sometimes typo a password | Background services on a schedule: **systemd timers** on Linux, **Scheduled Tasks** on Windows. They run whenever the VM is on, during "work hours" you set | Install script turns them on; `office.sh stop` pauses them |
| **Attacks (scenarios)** | Scripts that do one attack technique, like a SQL injection or a password spray | Run **on demand** from linux-srv, which plays the attacker's foothold, against other lab VMs only | You, with one command like `./scenario.sh run web-01` |

So once a stage is installed, the company "lives" on its own while the VMs are on: the apps serve pages and the fake staff generate normal activity in Wazuh. Nothing hostile happens until you start a scenario. That mirrors a real SOC: lots of normal noise, and an attack shows up somewhere inside it.

### Randomness, so you can't memorize "normal"

Requirement: the fake company must not become predictable. Randomness goes in at four levels:

1. **A different company every install.** The installer rolls a random roster from large name/department/job pools: who works there, who's an admin, which accounts are service accounts, which one has the weak password. Run `reroll` and it's a new company.
2. **Unpredictable daily behavior.** Each fake employee gets a personality (early bird, night owl, chronic password-typo person, heavy file user, rarely logs in) and every action has random timing jitter, so no two days produce the same log pattern.
3. **The company changes over time.** Random "life events": new hires, people leaving, password resets, someone on vacation then locked out on return, IT occasionally running a legitimate scan or admin PowerShell. Those last ones are deliberate **red herrings**: they look suspicious but are fine, and telling them apart from real attacks is the actual skill.
4. **Random attacks.** Each scenario picks its own target account, timing and variant, so the same scenario doesn't play out the same way twice. A **surprise mode** (`./scenario.sh surprise --within 3d`) secretly picks a scenario and fires it at a random time in that window, so you don't know when or what. That's the closest thing to real on-call work.

Every roll is saved with a seed in the spoilers folder, so afterward you can check your answer or replay the exact same run.

**One thing worth knowing:** real analysts *do* learn what normal looks like for their company. It's called **baselining**, and it's a skill you'll practice here. The randomness is meant to stop you memorizing the specific details, not to make "normal" meaningless.

### Quiet by design

Rule: staging scripts never print what they're doing, because the output would spoil the investigation. This applies to every stage: web-srv attacks, AD scenarios, the busy-office noise, and surprise mode.

- Scripts print only a neutral line like "done" (or an error if something failed to start). They never say which attack ran, which account was targeted, or when.
- They don't leave obvious clues on the lab VMs either: no tell-tale file names or log lines written by the script itself.
- Answers come only when you ask: a `hint` command (one nudge at a time), a `reveal` command, or the spoilers folder with the run's seed.

### What being public changes

- **Easier:** `git clone` just works on every VM, no tokens.
- **Normal practice:** lots of public projects ship deliberately vulnerable apps for training (OWASP Juice Shop, DVWA). The protection is that it only runs inside your private lab network, plus the "no public IP" check in the installer.
- **No real secrets in the repo, ever.** Passwords for the fake company are generated randomly by the install script on the VM and never committed. The only exceptions are the deliberately weak passwords that *are* the exercise (e.g. a fake user with `Summer2026!`), which are fake and only work inside your lab. Your real IPs, Azure IDs and Wazuh admin password stay out, same as now.
- **Spoiler risk:** the scenario scripts show exactly what each attack does. Don't read a scenario's folder before you investigate it. Answer keys live in a separate folder with a clear "spoilers" name. Coordinate with the exercise system being built in "Understanding the lab so far" so the two use the same rule.
- **Recruiter bonus:** anyone can see the lab is reproducible and well organized, which is part of the case study.

### Updates, resets and teardown

- **When something changes:** merge the PR, then `git pull` on the VM and run the installer again. The scripts are written to be safe to re-run.
- **Broke it while practicing?** Each stage has a `reset` option that puts the apps and fake data back to the starting state, so you can redo an exercise.
- **Done with a stage:** delete the VM. Nothing is lost, because the whole stage lives in the repo and can be rebuilt in minutes.

### Why do it this way (the security idea)

This is called **infrastructure as code**: the setup lives in version-controlled scripts instead of someone's memory. Real teams do it so servers can be rebuilt the same way every time and every change can be reviewed. It also gives you something to talk about in interviews: "my whole lab can be rebuilt from the repo."

**Safety note:** the vulnerable app's install script refuses to run if it detects a public IP on the VM, so it can't accidentally be exposed to the internet.

## Guardrails

- Stage 0 comes first. None of this should delay finishing the case study.
- Each stage ends like Phase 1: a short write-up in the repo, redacted per the publishing checklist.
- Deallocate new VMs when you finish a session; delete a stage's VM if you're done with it for good (its scripts stay in the repo, so you can rebuild it anytime).

## Being more ambitious (without wrecking the plan)

How to be more ambitious and learn even more. The tradeoff first, then options.

### The honest tradeoff

Your stated aims are **one focused project and a finished case study.** The biggest risk to all three is *breadth* — adding more
VMs and more unrelated topics until nothing is actually finished. A recruiter is
far more impressed by one credible, complete project than by ten half-built ones.

So the ambitious move is **not "more stages."** It's **more depth and more polish
on the single project you already have** — the kind of depth that makes a reviewer
think "this person works like a real engineer," not "this person collected tools."
Everything below is a *cross-cutting track* that weaves through the stages you
already have, not a new box to stand up.

### Four ambition tracks (pick at most one or two, later)

| Track | What you'd add | Why it's a big signal | Cost |
|---|---|---|---|
| **A. Lab as code (IaC)** | Define the whole lab — VNet, VMs, NSGs — in Terraform or Bicep, plus a little Ansible to configure them. "My entire lab rebuilds from the repo with one command." | This is the senior-sounding skill. It proves reproducibility and is exactly how real cloud/security teams work. Ties every stage together. | Free (code); VMs cost the same whether clicked or coded |
| **B. Detection as code** | Keep every Wazuh rule in the repo, test each against sample logs (you already have `logtest-samples`), and publish a MITRE ATT&CK coverage map. | Turns "I used a SIEM" into "I engineer, test and measure detections" — the actual SOC-engineering job. | Free |
| **C. DevSecOps on this repo** | A GitHub Actions pipeline that lint-checks the scripts, scans for secrets, and validates configs on every push. | You learn the CI/CD-security pipeline internships ask about, and it hardens your own portfolio repo. | Free |
| **D. Container security** | Scan the stage-2 Docker images (e.g. Trivy), harden them, optionally add runtime detection (Falco). | Container security is in high demand, and stage 2 already uses Docker, so it's a natural extension, not a new topic. | Free |

**Recommendation (2026-10-12):** **A (lab as code)** is the best fit, because cloud
infrastructure skills transfer to security, cloud engineering and cloud security alike.
Do B as well, writing the rules yourself, if there's room. Details below.

### Breadth I'd deliberately hold back (the "pile of experiments" trap)

Tempting, but park these as "future work" notes in the case study rather than
building them now: a second physical site, Kubernetes, a malware-analysis sandbox,
threat-intel platforms (MISP), or a full red-team toolkit. They're each a project
in their own right. Mentioning them as "what I'd do next" is itself a good
interview answer — you don't have to build them to get credit for the judgment.

### Where each track slots in

- **A (IaC):** a new top-level `infra/` folder; written alongside stage 2/3, used to
  stand them up.
- **B (detection as code):** extends `lab/wazuh/` and each stage's `wazuh/` folder.
- **C (DevSecOps):** a `.github/workflows/` pipeline on this repo.
- **D (container security):** extends `lab/stages/2-web-srv/`.

None of this changes the rule: finish Phase 1 and publish the case study, *then*
add one ambition track for depth.


## Lab as code: how it fits the repo

### Where it lives

A new top-level folder, next to `docs/` and `lab/`:

```
infra/
  README.md            guide: what Terraform is, how to run it, predict-first questions
  main.tf              provider (Azure) + resource group
  network.tf           VNet, lab-subnet, later the DMZ subnet (stage 4)
  firewall.tf          NSG rules (RDP from your IP only, nothing else open)
  core-vms.tf          wazuh, win-srv, linux-srv
  stage2-web-srv.tf    web-srv, switched on by a variable
  stage3-dc01.tf       dc01, switched on by a variable
  variables.tf         your IP, VM sizes, which stages are on
  terraform.tfvars.example   copy to terraform.tfvars (git-ignored)
  outputs.tf           the private IPs it created
```

**Terraform, not Bicep.** It works on Azure, AWS and Google Cloud, and it's in far
more job postings.

### How it changes each stage

Today a stage is: click to create the VM, SSH in, clone, run `install.sh`.
With lab as code it's one change in a file:

```
enable_web_srv = true
```

then `terraform plan` (shows exactly what will be created, nothing changes yet)
and `terraform apply`. Terraform creates the VM with the right settings, and the
VM runs that stage's `install.sh` by itself on first boot (cloud-init on Linux,
a startup script extension on Windows). Set it back to `false` and apply, and the
VM is deleted. So the stage scripts already in PR #5 get reused, not replaced.

Stage 4 (network zones) becomes much easier in code than in the portal: a DMZ
subnet and its firewall rules are a few lines each, and you can see the whole
design in one file.

### Your existing three VMs

They were built by clicking, so Terraform doesn't know about them yet. Two options:
- **Import them** (`terraform import`): Terraform adopts the real VMs and the code
  is adjusted until `plan` shows no changes. This is a very real-world skill: most
  companies have click-built systems to adopt.
- **Leave them** and use Terraform only for new stages.

Recommended: build stages 2 and 3 with Terraform first (low risk, they're new),
then import the core three once you're comfortable. Always read `plan` before
`apply`: a wrong setting on an imported VM can make Terraform want to delete and
recreate it, and `plan` is where you catch that.

### Security rules for a public repo

- **The state file never goes in git.** Terraform keeps a "state" file describing
  everything it built, and it can contain sensitive values. It's git-ignored and
  stays on the machine you run Terraform from (later: an Azure storage account).
- **No subscription ID, home IP or passwords in the code.** They go in
  `terraform.tfvars`, which is git-ignored. The repo only has the `.example` file.
- **Scan the code.** A free scanner (Trivy or Checkov) flags risky settings, like
  a firewall rule open to the internet, before anything is built. This is the
  cloud-security slice, and it pairs with track C (a CI pipeline) later.

### Where you run it

Azure Cloud Shell (the `>_` icon in the portal) has Terraform preinstalled and is
already signed in to your account, so nothing to install. You clone the repo
there and run it.

### Cost

Terraform is free. The VMs cost the same whether clicked or coded. The cheapest
habit it enables: switch stages off when you're not using them, instead of
leaving VMs around.

### How to actually learn it (not just run it)

Copying finished files and only running `apply` teaches very little. So the work
ramps up, with more written from scratch at each step:

1. **Read and predict:** start from the network and firewall files, with heavy
   comments. Predict what `terraform plan` will create, then checks.
2. **Change:** small edits (VM size, a new firewall rule); `plan` shows the effect.
3. **Write:** `stage2-web-srv.tf` is the example; write
   `stage3-dc01.tf` from a blank file with hints. `plan` is the checker; an answer
   file (spoiler) shows one working version afterward.
4. **Fix a planted mistake:** a risky setting (e.g. RDP open to the internet) to
   find with the scanner and fix.
5. **Import the existing VMs:** the hardest, most real-world step.

### Order

1. Phase 1 + case study (unchanged).
2. Lab as code for stages 2 and 3 (`infra/`), then stand up stage 2 with it.
3. Import the core three VMs.
4. Stage 4 network zones, written in Terraform from the start.

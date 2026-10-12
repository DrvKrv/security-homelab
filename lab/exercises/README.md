# Lab exercises — a self-paced defensive-security range

A menu of hands-on exercises for your homelab. Each one stages a realistic event
on your own VMs, then has you **detect it, investigate it, respond to it, and
prove you fixed it** — the actual workflow of a SOC analyst. The point isn't to
"finish"; it's to be able to *explain* what you did, which is what a recruiter or
interviewer cares about.

Everything here runs **inside your own private lab network**, machine to machine,
against VMs you own. Nothing touches the internet or any system you don't control.

## Why it's built this way

- **You activate it, not me.** The heavy lifting is done once, as scripts and
  briefs. Running an exercise later costs you nothing and needs nothing extra — you just
  run a command and work the problem.
- **Several variants per level.** Each difficulty level has multiple
  interchangeable scenarios, so you can practise the *same* skill repeatedly
  without jumping to something harder before you're ready. The runner can pick a
  fresh variant for you at random.
- **Progressive difficulty.** Levels build on each other: spot it → explain it →
  fix it → prevent it → engineer the detection yourself.
- **Learn actively.** Every brief asks you to **predict before you run**, gives
  **progressive hints** (so you can get unstuck without spoiling it), and keeps
  the full **answer key** one command away for when you want to check yourself.

## The levels

| Level | Skill | What you do | Variants |
|---|---|---|---|
| 1 | **Detect** | Find that something happened and identify the alert | 6 (SSH brute force, Linux & Windows account changes, blocked connections, port scan, Windows failed logons) |
| 2 | **Investigate** | Build a timeline and reach an evidence-backed conclusion | 3 |
| 3 | **Respond** | Contain and clean up, then *prove* it's clean | 2 (Linux & Windows) |
| 4 | **Vulnerabilities** | Inventory, research CVEs/CVSS, prioritise, patch, verify | 1 (open-ended) |
| 5 | **Detection engineering** | Write and test your own Wazuh rule | 1 (+ stretch goals) |

## How to use it

Run the menu from the `lab/exercises/` directory:

```bash
./run.sh list                      # see all levels and variants
./run.sh start 1                   # a random Level 1 exercise
./run.sh start 1/ssh-bruteforce    # a specific one
./run.sh stage 1/ssh-bruteforce    # stage the incident quietly (on the VM the brief names)
./run.sh hint 1/ssh-bruteforce     # reveal the next hint (progressive)
./run.sh reveal 1/ssh-bruteforce   # show the full answer key
./run.sh verify 3/linux-backdoor-user   # auto-check your fix (where supported)
./run.sh reset 3/linux-backdoor-user    # undo the staged incident (asks first)
```

`start` prints the brief, tells you **which VM** stages the incident, and gives
you a neutral Wazuh search to begin from. Then run `./run.sh stage <id>` on that
VM. Staging runs **quietly**: you see "Done", not a play-by-play, because the
script's own output would tell you the answers. The full output is saved to a
log file (the path is printed) so you can compare it with your findings
afterwards. You then investigate in the Wazuh dashboard and fill a case file.

- **Each staging VM needs its own copy of the repo.** The Linux network
  exercises stage from **wazuh**; the account-change, Level 3 Linux and Level 4
  exercises stage on **linux-srv**; the Windows ones stage on **win-srv**. Clone
  the repo on each VM you use (on win-srv, install Git for Windows or download
  the repo as a ZIP). If you run `stage` on the wrong VM, it tells you which one
  to use instead.
- **Windows exercises:** `./run.sh stage` prints a one-line PowerShell command.
  Run it in an Administrator PowerShell from the repo's `lab\` folder on win-srv.
  It also prints only "Done" and saves the details to a log in `%TEMP%`.
- **Where to run the runner otherwise:** `start`, `hint` and `reveal` work
  anywhere you have the repo. For Level 3–4 the `verify`/`reset` steps act on a
  specific VM, so run them **on that VM** (noted at the top of each brief).
- **Case files:** copy `case-file-template.md` for each exercise. A filled case
  file is a portfolio entry and interview prep in one.

## Dependency on the rest of `lab/`

The exercises **stage** their incidents using the scripts in `lab/linux/` and
`lab/windows/` (the Wazuh rules, simulation scripts and runbooks added in the lab
configs PR). The exercise framework references those scripts — it doesn't
duplicate them. Make sure you have the full `lab/` tree checked out on your VMs.
If a staging script is missing, the runner tells you which file to get; the brief
still teaches the concept either way.

## Ground rules (same as the rest of the lab)

- Only ever target your **own** lab VMs, inside your VNet. The staging scripts
  refuse non-private addresses by design.
- Take screenshots and notes as you go — they become your GitHub case study.
- Never commit secrets: passwords, keys, your public IP, or subscription IDs.
  `lab/.gitignore` already blocks the usual suspects.

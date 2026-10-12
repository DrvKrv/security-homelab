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
  briefs. Running an exercise later costs you nothing and needs no AI — you just
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
./run.sh hint 1/ssh-bruteforce     # reveal the next hint (progressive)
./run.sh reveal 1/ssh-bruteforce   # show the full answer key
./run.sh verify 3/linux-backdoor-user   # auto-check your fix (where supported)
./run.sh reset 3/linux-backdoor-user    # show how to return to a clean state
```

`start` prints the brief, tells you exactly **which VM** to stage the incident
on and **what command** to run there, and gives you a Wazuh search to begin from.
You then investigate in the Wazuh dashboard and fill a case file.

- **Where to run the runner:** for Level 1–2 you can run it anywhere you have the
  repo (it just prints guidance). For Level 3–4 the `verify`/`reset` steps act on
  a specific VM, so run the runner **on that VM** (noted at the top of each
  brief).
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

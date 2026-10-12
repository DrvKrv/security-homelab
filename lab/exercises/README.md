# Lab lessons — a self-paced defensive-security range

A menu of hands-on lessons for your homelab. Each one stages a realistic event
on your own VMs, then has you **spot it, explain it, respond to it, prevent it,
and hunt for it** — the actual workflow of a SOC analyst. The point isn't to
"finish"; it's to be able to *explain* what you did, which is what a recruiter or
interviewer cares about.

Everything here runs **inside your own private lab network**, machine to machine,
against VMs you own. Nothing touches the internet or any system you don't control.

## The shape: a grid you spiral through

Lessons sit on a grid of **7 concept tracks × 5 difficulty levels**. Each box
(say `A1`) holds a few interchangeable lessons of the same type and difficulty,
and every lesson randomizes its details, so repeating a box never repeats the
same answer.

### The 7 tracks

| | Track | About |
|---|---|---|
| A | Logins and passwords | brute force, spraying, who logged in |
| B | Accounts and privileges | new accounts, admin rights, backdoors |
| C | Network | scans, blocked traffic, movement between machines |
| D | Vulnerabilities and hardening | CVEs, patching, hardening, benchmarks |
| E | Web applications | web logs, web attacks, a firewall in front |
| F | What runs on a machine | processes, Sysmon, scheduled tasks, services |
| G | Cloud and infrastructure as code | Terraform, the Azure activity log |

### The 5 levels

| | Level | What you do |
|---|---|---|
| L1 | **Spot** | Something happened. Find the alert. You're told which machine. |
| L2 | **Explain** | Who, what, when, from where. Build a timeline from a neutral start. |
| L3 | **Respond** | Contain it, clean it up, prove it's clean. |
| L4 | **Prevent** | Harden something or write/tune a rule, then test it works. |
| L5 | **Hunt** | No alert to start from, or a story hidden in normal activity. |

A lesson's id is `<track><level>/<name>`, for example `A1/ssh-bruteforce`.

## Environments: what's built so far

Most of the grid needs machines you haven't built yet. The runner only lets you
*stage* a lesson once its environment exists; you can always *read* any lesson.

| Environment | What it is | Round |
|---|---|---|
| `core` | your 3 current VMs (always on) | 1 |
| `detect` | Sysmon, Suricata, Atomic Red Team on the core VMs | 2 |
| `cloud` | the lab described in Terraform under `infra/` | 3 |
| `web` | web-srv, the company website | 4 |
| `ad` | dc01, Active Directory | 5 |
| `zones` | the network split into zones | 6 |
| `office` | the busy-office noise generator | 7 |
| `capstone` | the final multi-step breach | 8 |

When you build one, tell the runner: `./run.sh env add web`. That unlocks its
lessons. Today, only `core` is on, so start with the round-1 lessons in tracks
A, B, C and D.

## How to use it

Run the menu from the `lab/exercises/` directory:

```bash
./run.sh list                      # the whole grid, with how many lessons you can run now
./run.sh list A1                   # the lessons in a box (or a track: A, or a level: L2)
./run.sh start A1                  # a random lesson in box A1
./run.sh start A1/ssh-bruteforce   # a specific one (prints the brief)
./run.sh stage A1/ssh-bruteforce   # stage the incident quietly (on the VM the brief names)
./run.sh hint A1/ssh-bruteforce    # reveal the next hint (progressive)
./run.sh reveal A1/ssh-bruteforce  # show the full answer key
./run.sh verify B3/linux-backdoor-user   # auto-check your fix (where supported)
./run.sh reset B3/linux-backdoor-user    # undo the staged incident (asks first)
./run.sh done A1/ssh-bruteforce    # mark a lesson finished
./run.sh progress                  # what you've done, and what to do next
./run.sh env add web               # mark an environment as built, to unlock its lessons
```

`start` prints the brief, tells you **which VM** stages the incident, and gives
you a neutral Wazuh search to begin from. Then run `./run.sh stage <id>` on that
VM.

### Staging runs quietly

Staging prints only "Done", not a play-by-play, because the script's own output
would tell you the answers. The full output is saved to a log file (the path is
printed) so you can compare it with your findings afterwards. Some lessons
randomize their details (which account, how many tries); `./run.sh reveal`
shows *this run's* details at the end, after the answer key.

Add `--surprise` to a stage command (`./run.sh stage A1/ssh-bruteforce
--surprise`) and the incident happens at a random time in the next 15 minutes,
so you practise noticing it rather than knowing exactly when it started.

### Each staging VM needs its own copy of the repo

A lesson stages on one specific machine, and that machine needs the repo cloned
on it. In the core lab:

- **wazuh** stages the Linux network lessons (SSH, blocked connections, scan).
- **linux-srv** stages the Linux account and vulnerability lessons.
- **win-srv** stages the Windows lessons. There `./run.sh stage` prints a
  one-line PowerShell command to run in an Administrator PowerShell from the
  repo's `lab\` folder; it also prints only "Done" and logs the details to
  `%TEMP%`.

If you run `stage` on the wrong machine, it tells you which one to use.
`start`, `hint`, `reveal` and `progress` work anywhere you have the repo. For a
lesson with a fix, run `verify`/`reset` on the VM the brief names.

## Moving through the grid

1. **Go across before going up.** Do L1 in each open track, then L2 in each, and
   so on. `./run.sh progress` points at the next open box.
2. **Level up after two.** Move up once you've done two lessons at your level in
   *different* tracks and could explain both without hints.
3. **Shaky? Repeat the box.** Another lesson from the same box has different
   details, so you can't just remember the answer.
4. **New environment, back to L1.** Building web-srv or dc01 opens the same
   concepts on new ground. Familiar ideas, so you climb faster.

**Before Oct 26:** round 1, at least L1 and L2 in tracks A, B and C, plus a
Track D lesson. That's enough for the case study and the interview stories.

## Case files

Copy `case-file-template.md` for each lesson. A filled case file (what happened,
the evidence, the MITRE ATT&CK tag, what you'd fix) is a portfolio entry and
interview prep in one.

## Writing or changing a lesson

`LESSON-GUIDE.md` is the authoring guide: the folder layout, every `meta.sh`
field, the brief and answer-key templates, the no-spoiler rule, and the facts
and ids you may cite. The staging scripts live in `lab/linux/` and
`lab/windows/`; lessons reference them, they don't duplicate them.

## Ground rules (same as the rest of the lab)

- Only ever target your **own** lab VMs, inside your VNet. The staging scripts
  refuse non-private addresses by design.
- Take screenshots and notes as you go — they become your GitHub case study.
- Never commit secrets: passwords, keys, your public IP, or subscription IDs.
  `lab/.gitignore` already blocks the usual suspects.

# How to write a lesson

This is the authoring guide for `lab/exercises/`. Every lesson follows it, so the
runner can treat all of them the same way and the learner always knows where to
look. The plan the lessons come from is the curriculum grid: 7 concept tracks ×
5 levels, a few lessons per box.

## Where a lesson lives

```
tracks/<T>-<track>/<N>-<level>/<lesson-slug>/
  meta.sh       what the runner needs (below)
  brief.md      the mission, with hints at the end
  solution.md   the answer key, shown only by `./run.sh reveal`
  verify.sh     optional: exits 0 when the learner's fix is correct
```

The lesson's id is `<T><N>/<lesson-slug>`, for example `A1/ssh-bruteforce`.
Slugs are short, lowercase, hyphenated, and unique across the whole grid.

| Track folder | Concept |
|---|---|
| `A-logins` | Logins and passwords |
| `B-accounts` | Accounts and privileges |
| `C-network` | Network: scans, blocked traffic, movement |
| `D-vulnerabilities` | Vulnerabilities and hardening |
| `E-web` | Web applications |
| `F-processes` | What runs on a machine (processes, Sysmon) |
| `G-cloud` | Cloud and infrastructure as code |

| Level folder | Level | The learner... |
|---|---|---|
| `1-spot` | L1 Spot | finds the alert. They're told which machine. |
| `2-explain` | L2 Explain | builds who/what/when/from where, from a neutral start. |
| `3-respond` | L3 Respond | contains, cleans up, proves it's clean. |
| `4-prevent` | L4 Prevent | hardens something or writes/tunes a rule, then tests it. |
| `5-hunt` | L5 Hunt | has no alert to start from, or a multi-step story hidden in normal activity. |

## meta.sh

```bash
# shellcheck shell=bash
EX_TITLE="SSH brute force against linux-srv"
EX_SUMMARY="Someone is hammering SSH on linux-srv. Find it in Wazuh."   # no spoilers
EX_ENV="core"          # core detect cloud web ad zones office capstone
EX_ROUND="1"           # curriculum round, 1-8
EX_WHERE="wazuh"       # VM the staging runs on: wazuh linux-srv win-srv web-srv dc01 none
EX_FIX_WHERE=""        # optional: VM where the fix, verify and reset happen (default EX_WHERE)
EX_STAGE="bash linux/simulate-ssh-bruteforce.sh"   # run from lab/; or "# note"
EX_RESET=""            # optional undo command, run from lab/ on EX_FIX_WHERE
EX_WAZUH_SEARCH="agent.name: linux-srv"            # neutral: an agent filter, never a rule id
EX_HAS_VERIFY="no"     # "yes" only if verify.sh exists
EX_STAGE_CONFIRM="no"  # "yes" if the staging script asks for a typed YES
EX_ATTACK="T1110.001"  # MITRE ATT&CK technique id(s); shown only by reveal
```

**Environments** (`EX_ENV`) say what has to exist before the lesson can be staged.
`core` is always on. The others unlock when the learner runs `./run.sh env add <name>`:

| EX_ENV | Means | Round |
|---|---|---|
| `core` | the 3 current VMs: wazuh 10.0.1.10, win-srv 10.0.1.20, linux-srv 10.0.1.30 | 1 |
| `detect` | detection add-ons on the core VMs: Sysmon on win-srv, Suricata, Atomic Red Team | 2 |
| `cloud` | the lab described in Terraform under `infra/` | 3 |
| `web` | web-srv 10.0.1.40 (`lab/stages/2-web-srv/`) | 4 |
| `ad` | dc01 10.0.1.50, domain `acme.lab` (`lab/stages/3-dc01/`) | 5 |
| `zones` | the network split into DMZ and internal zones | 6 |
| `office` | the busy-office noise generator | 7 |
| `capstone` | the final multi-step breach | 8 |

**Staging.** Pick the first that fits:
1. **A bash function** `ex_stage` (and `ex_reset`) in meta.sh, when details should
   be randomized. It runs from `lab/` on `EX_WHERE`, with all output going to a log.
   It can use:
   - `pick a b c` prints one of its arguments at random.
   - `rand_between 3 9` prints a random whole number in that range.
   - `answer "<key>" "<value>"` records a detail of this run. `reveal` shows these, and
     `verify.sh` sees each one as `LAB_ANSWER_<KEY>` (key upper-cased, non-letters
     become `_`).
   - `$WAZUH_IP`, `$WIN_IP`, `$LINUX_IP` are the lab addresses.
2. **`EX_STAGE="<command>"`**, a fixed command run from `lab/`.
3. **A PowerShell command** for win-srv lessons, run from the repo's `lab\` folder
   (e.g. one of the scripts in `lab/windows/`). The runner can't run it from Linux,
   so `stage` prints it wrapped in one line that sends its output to a log in
   `%TEMP%` and prints only "Done".
4. **`EX_STAGE="# <note>"`** when nothing is scripted. The note says what the learner
   does instead (for example "Solve the Juice Shop 'Score Board' challenge from
   win-srv's browser, then come back"), or that staging arrives with the environment.

**Safety rules for staging.** Staging reuses what already exists:
- the scripts in `lab/linux/` and `lab/windows/`, with their documented arguments;
- standard admin tools such as `useradd`, `ufw`, `systemctl`, `New-LocalUser` and `schtasks`;
- OWASP Juice Shop's built-in challenges, solved by the learner;
- published Atomic Red Team tests, referenced by technique id.

Never write new exploit, brute-force, scanning or malware code, attack payloads, or
step-by-step attack instructions. Staging only ever targets the lab's own private
VMs.

## brief.md

```markdown
# A1 Spot: SSH brute force against linux-srv

> Optional one-line note: where to run things, or what environment it needs.

## The concept
Plain-language explanation of the idea (2-3 short paragraphs). Define every term
the first time. Say why a defender cares.

## Your mission
Numbered list of what to determine or do. Concrete and checkable.

## The analyst workflow
Numbered steps: where to look and what to compare. Teach the method, not the answer.

## Predict before you run
One question the learner answers before staging. It should have a real answer.

## What good looks like
What the finished case file (`../../../../case-file-template.md`) contains.

## Hints
1. A nudge on where to look.
2. A narrower nudge.
3. Nearly there: the key comparison or command.
4. The last step before the answer key.
```

Rules for briefs:
- **No spoilers before `## Hints`.** No Wazuh rule ids, Windows event ids, account
  names, IPs of the attacker, or the specific answer in the concept, mission, workflow,
  predict or "what good looks like" sections. (Telling the learner which VM to look
  at is fine at L1, and only at L1.) Hints may name ids and commands.
- **Each hint is one line** starting with `1.`, `2.`... The runner shows one per
  `./run.sh hint`, so a hint that wraps onto a second line gets cut. Aim for 3-5
  hints, from gentle to nearly-the-answer.
- **Randomized details:** if `ex_stage` randomizes something (account, count,
  port, timing), the brief must not assume a fixed value, and the solution says
  "this run's value is shown under *This run's details* at the end of `reveal`."
- **Not core?** Start the brief with a note such as
  `> Needs web-srv (unit 6). Read it any time; stage it once web-srv is built.`
- Write for a beginner: short sentences, define acronyms, explain the why. Use
  "you". No em-dashes; use commas, colons or full stops.
- Relative links from a lesson folder to the repo's `docs/` are `../../../../../../docs/`.
  Links to the case file template are `../../../../case-file-template.md`.

## solution.md

```markdown
# Answer key: SSH brute force against linux-srv

## What happened
The story in a few sentences.

## The evidence
Where it shows up (Wazuh alerts, logs, commands) and what each piece proves.

## Answers to the mission
One numbered answer per mission item.

## MITRE ATT&CK
Technique id and name, one line on why it fits.

## Common mistakes
2-4 bullets.

## Interview talking point
2-4 sentences the learner could say in an interview.
```

For a fix lesson (L3, L4), include the exact commands and how to prove the fix.

## Facts you can rely on

Use only these specific ids. For anything else, describe the alert and ask the
learner to note its id.

- **Wazuh built-in:** 5710 (sshd attempt to log in as a non-existent user), 5712
  (sshd brute force, many non-existent users), 5760 (sshd authentication failed),
  5763 (sshd brute force), 5762 (sshd connection reset), 5715 (sshd authentication
  success), 5501/5502 (PAM login session opened/closed), 5402 (successful sudo to ROOT),
  5902 (new user added), 5903 (user deleted), 2961 (user added to a group), 5555
  (password changed), 550/554 (file-integrity: file modified / added), 553 (file
  deleted), 60122 (Windows logon failure), 60204 (multiple Windows logon failures),
  60115 (Windows account locked out).
- **Lab rules** (`lab/wazuh/manager/local_rules.xml`): 100100/100101 UFW blocked a
  connection, 100102 possible port scan (8 blocks in 60 s), 100110 Linux user added
  to sudo (level 10). Your own rules use ids 100300-100399.
- **web-srv rules** (`lab/stages/2-web-srv/wazuh/local_rules.xml`): 100400 portal
  login success, 100401 portal login failure, 100402 portal brute force (6 failures
  in 120 s from one IP).
- **Windows Security events:** 4624 logon success, 4625 logon failure, 4634 logoff,
  4648 logon with explicit credentials, 4672 special privileges at logon, 4688
  process created, 4698 scheduled task created, 4720 user created, 4722 enabled,
  4724 password reset, 4725 disabled, 4726 deleted, 4728/4732/4756 member added to
  a global/local/universal group, 4733 removed from a local group, 4740 locked out,
  4768/4769 Kerberos TGT/service ticket, 4771 Kerberos pre-auth failed, 4776 NTLM
  credential validation, 7045 service installed (System log).
- **Sysmon:** event 1 process create, 3 network connection, 11 file create, 13
  registry value set, 22 DNS query.
- **linux-srv file-integrity** (lab agent.conf) watches `/etc/passwd`, `/etc/group`,
  `/etc/shadow`, `/etc/gshadow`, and with diffs `/etc/sudoers`, `/etc/sudoers.d`,
  `/etc/ssh/sshd_config`, `/etc/ssh/sshd_config.d`, `/etc/ufw`.
- **linux-srv SSH** is key-only by default. `lab/linux/setup-linux-srv.sh` turns
  password logins on for the test account `labuser`.
- **web-srv:** company site and employee portal at `http://10.0.1.40/` and
  `/portal/`; OWASP Juice Shop at `http://10.0.1.40:3000/`, reached only from inside
  the lab (from win-srv's browser).
- **dc01:** domain `acme.lab`, random fake staff, departments and groups from
  `lab/stages/3-dc01/Seed-Company.ps1`.

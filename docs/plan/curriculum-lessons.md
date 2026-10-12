# Homelab curriculum: every lesson and the path through it

Written 2026-10-12. This is the lesson plan. The unit list and costs are in
[curriculum-roadmap.md](curriculum-roadmap.md).

## How it's shaped

The curriculum is a grid, plus a spiral:

1. **7 concepts** (the rows). The same concepts come back again and again across the whole curriculum.
2. **5 difficulty levels** (the columns). Every concept uses the same 5 levels.
3. **Several lessons per box.** Each concept × level box has 2–5 lessons of the same type and difficulty, and every lesson randomizes its details (accounts, times, sources). Repeating a box never repeats the same answer.
4. **The spiral.** Each new environment (the website, the company accounts, the busy office) brings the same concepts back on new ground, a bit harder each time.

So you get exactly the three things you described: repeats of the same lesson type, the same difficulty across different concepts, and the same concepts across the whole curriculum.

### The 5 difficulty levels

| Level | Name | What you do |
|---|---|---|
| L1 | **Spot** | Something happened. Find the alert. You're told which machine. |
| L2 | **Explain** | Who, what, when, from where. Build a timeline from a neutral starting point. |
| L3 | **Respond** | Contain it, clean it up, prove it's clean. |
| L4 | **Prevent** | Harden something or write/tune a rule, then test that it works. |
| L5 | **Hunt** | No alert to start from, or a multi-step story hidden in normal activity. |

### The 7 concepts

| Track | Concept | Starts in |
|---|---|---|
| A | Logins and passwords | the core lab |
| B | Accounts and privileges | the core lab |
| C | Network: scans, blocked traffic, movement | the core lab |
| D | Vulnerabilities and hardening | the core lab |
| E | Web applications | the company website |
| F | What runs on a machine (processes, Sysmon) | detection engineering |
| G | Cloud and infrastructure as code | lab as code |

**Where each lesson happens:** Core = your 3 current VMs · Web = web-srv · AD = company accounts (dc01) · Cloud = Azure/Terraform · Zones = split network · Office = busy-office noise · Capstone = the final breach.

★ = one of the 13 lessons that already exist in `lab/exercises/`.

---

## The full grid

### Track A: Logins and passwords

| Level | Lessons |
|---|---|
| L1 Spot | ★ SSH brute force against linux-srv (Core) · ★ Windows failed logons on win-srv (Core) · Failed portal logins (Web) · Failed domain logons (AD) |
| L2 Explain | ★ Did the SSH attacker get in? (Core) · Windows failed logons, then one success (Core) · Portal brute force: which accounts, which source (Web) · Password spraying: one password tried on many accounts (AD) |
| L3 Respond | Block the attacking source and prove it's blocked (Core) · Switch SSH to keys only and prove passwords stop working (Core) · Reset a compromised portal account and end its sessions (Web) · Disable a compromised domain account and find everywhere it logged in (AD) |
| L4 Prevent | ★ Write your own first Wazuh rule (Core) · Tune the brute-force threshold: catch attacks, ignore typos (Core) · Auto-block with active response, tested on linux-srv (Core) · Spraying rule: many accounts, one source (AD) · Account lockout policy, before and after (AD) |
| L5 Hunt | A slow brute force spread over hours of normal activity (Office) · A valid login at a strange hour from an odd machine (Office) · The stolen password behind the breach (Capstone) |

### Track B: Accounts and privileges

| Level | Lessons |
|---|---|
| L1 Spot | ★ A new Linux admin account appears (Core) · ★ A new Windows admin account appears (Core) · A new domain account created out of hours (AD) |
| L2 Explain | ★ Triage the backdoor account (Core) · Unexpected sudo rights: who granted them, when (Core) · Someone added to a domain admin group (AD) |
| L3 Respond | ★ Remove the Linux backdoor account (Core) · ★ Remove the Windows backdoor account (Core) · Remove an unauthorized admin-group member and check for others (AD) |
| L4 Prevent | Alert on changes to sudoers and user files, then test it (Core) · Alert on admin-group changes (AD) · Least-privilege audit: who's an admin and shouldn't be (AD) |
| L5 Hunt | A dormant account that suddenly wakes up (Office) · The account the attacker left behind to get back in (Capstone) |

### Track C: Network

| Level | Lessons |
|---|---|
| L1 Spot | ★ A port scan against linux-srv (Core) · ★ Firewall-blocked connections (Core) · A scan of the web server (Web) |
| L2 Explain | ★ Triage the port scan (Core) · Where did the blocked traffic come from, and did anything get through? (Core) · What does the web server expose, and to whom? (Web) |
| L3 Respond | Close a port that shouldn't be open and verify (Core) · Tighten an Azure firewall rule (Cloud) |
| L4 Prevent | Make a scan show up as a network alert with Suricata (Core) · Prove the split network works: web-srv can't reach dc01 (Zones) |
| L5 Hunt | A quiet scan buried in normal traffic (Office) · The attacker moving from web-srv toward the internal zone (Capstone) |

### Track D: Vulnerabilities and hardening

| Level | Lessons |
|---|---|
| L1 Spot | Read Wazuh's vulnerability findings for one VM (Core) · List the software running on web-srv (Web) |
| L2 Explain | Research one CVE: CVSS score, NVD record, does it really apply here? (Core) · Rank a list of findings by real risk, not just score (Core, Web) |
| L3 Respond | ★ Find, prioritise and fix outdated software, then re-scan (Core) · Patch web-srv and prove it (Web) |
| L4 Prevent | Harden a VM against a CIS benchmark, score before and after (Core) · Strengthen the domain password policy (AD) · Scan and harden the Docker images (Web) |
| L5 Hunt | Root cause: which weakness let the attacker in? (Capstone) |

### Track E: Web applications (from the website unit on)

| Level | Lessons |
|---|---|
| L1 Spot | Find training-app attack attempts in the web access log · Spot a burst of errors in the web error log |
| L2 Explain | Reconstruct a web attack: what was requested, and did it work? · Compare a normal portal session with a suspicious one |
| L3 Respond | Find the weakness in code by comparing the portal's safe login with the target app's · Put a web application firewall in front and verify it |
| L4 Prevent | Write a rule for one web-attack pattern and test it · Tune the firewall: block attacks without breaking normal use |
| L5 Hunt | The web foothold at the start of the breach (Capstone) |

### Track F: What runs on a machine (from detection engineering on)

| Level | Lessons |
|---|---|
| L1 Spot | See process-start events from Sysmon on win-srv · Spot an unusual program running on linux-srv |
| L2 Explain | Trace what a user ran after logging in · Find a scheduled task or service that appeared |
| L3 Respond | Remove an unwanted scheduled task and prove it's gone · Stop and remove an unwanted service |
| L4 Prevent | Rule for hidden (encoded) PowerShell, tested with an Atomic Red Team test · Map all your rules to MITRE ATT&CK and publish a coverage map |
| L5 Hunt | An odd chain of programs launching each other, hidden in normal activity (Office) |

### Track G: Cloud and infrastructure as code (from lab as code on)

| Level | Lessons |
|---|---|
| L1 Spot | Read a `terraform plan` and say what it will do · Read the Azure activity log: who changed what |
| L2 Explain | What changed in the lab this week, and who did it? · Someone changed a setting by hand in the portal: find it with `plan` |
| L3 Respond | Fix a risky firewall rule in code and apply it · Write the dc01 file yourself, using the web-srv file as your example |
| L4 Prevent | A scanner that flags risky settings before anything gets built · A pipeline that blocks a risky change on every push |
| L5 Hunt | Bring your 3 hand-built VMs under code without breaking them · Rebuild the whole lab from code after a "disaster" |

84 lessons in total. Each one randomizes its details, so every lesson can be repeated.

---

## The expected path

You go through the grid in **rounds**, one per environment. Each round opens new boxes.

| Round | Environment (roadmap unit) | Boxes you work |
|---|---|---|
| 1 | Core lab (units 2–3) | A, B, C, D at L1 → L3, then your first rule (A L4) |
| 2 | Detection engineering (unit 4) | L4 for A, B, C · all of F up to L4 |
| 3 | Lab as code (unit 5) | All of G up to L4 |
| 4 | Company website (unit 6) | A, C, D again on web-srv, L1 → L4 · all of E up to L4 |
| 5 | Company accounts (unit 7) | A, B, D again on AD, L1 → L4 |
| 6 | Network zones (unit 8) | C at L3–L4 · G at L3–L5 |
| 7 | Busy office (unit 9) | L5 hunts in A, B, C, F |
| 8 | Capstone (unit 10) | The L5 lessons marked Capstone, chained into one breach story |

**First milestone (the case study):** Round 1, at least L1 and L2 in tracks A, B and C, plus one Track D lesson. That's enough for the case study and the interview stories.

### The rules for moving through it

1. **Go across before going up.** Within a round, do L1 in each available track, then L2 in each, and so on.
2. **Level up after two.** Move to the next level once you've done two lessons at your current level in *different* tracks and could explain both without hints.
3. **Shaky? Repeat the box.** Do another lesson from the same box (same concept, same difficulty). The randomized details mean you can't just remember the answer.
4. **New round, back to L1, faster climb.** A new environment starts you at L1 on new ground, but the concepts are familiar, so you'll move up faster.
5. **You don't have to fill every box.** Per round, aim for at least one lesson per open track at each level.

### One concept through the spiral (Track A)

| Round | Lesson |
|---|---|
| 1 | SSH brute force on linux-srv (L1) → did they get in? (L2) → block them (L3) → write your first rule (L4) |
| 4 | Brute force against the employee portal: same idea, web logs instead of system logs |
| 5 | Password spraying in Active Directory: one password, many accounts, so your round-1 rule misses it |
| 7 | A slow brute force spread over hours, buried in office noise |
| 8 | The stolen password that starts the capstone breach |

Every lesson ends the same way: a short case file (what happened, evidence, MITRE ATT&CK tag, what you'd fix). After each round, one write-up goes into the repo, redacted per the publishing checklist.

### How this lines up with `lab/exercises` today

The exercise runner's Levels 1–3 (Detect, Investigate, Respond) are L1–L3 here. Its Level 4 (Vulnerabilities) is Track D. Its Level 5 (Detection engineering) is L4.

# Detection engineering (curriculum unit 4, formerly "Phase 2")

> Part of the combined curriculum: this is **unit 4**, except Step 3 (Active Directory), which became **unit 7**. See [curriculum-roadmap.md](curriculum-roadmap.md).

Start this once Phase 1 is done: the exercises are finished and the case study README is published. Phase 2 doesn't need a new project. You make the **same lab** more realistic and get better at the work, and it all goes in the same repo as a "Phase 2" section. That still counts as one focused project, because each step makes the first lab deeper. It doesn't sit next to it as a separate thing.

The big idea: in Phase 1 you **used** a SIEM. In Phase 2 you **build detections**, **add the things real companies have**, and **prove your detections work** against real attack techniques.

---

## Step 1. Better eyes on Windows: Sysmon + custom Wazuh rules (start here)

**What:** Install Microsoft **Sysmon** on win-srv. It logs things like process starts, network connections, and file creation. Then write your own Wazuh rules for behavior you care about, for example "PowerShell launched with an encoded command."

**Why it matters:** Windows' default logs tell you *who logged in*. Sysmon tells you *what they did after*. Writing your own rules is a SOC job called **detection engineering**. It's the difference between reading alerts and creating them.

**Cost:** free, no new VMs.

**Security+:** Security Operations domain (log sources, SIEM tuning, false positives).
**Interview line:** "I wrote a custom rule that catches X, tested it, and tuned out the false positives."

> Predict first: once Sysmon is on, will you see *more* alerts or just more *logs*? (Hint: those aren't the same thing. Why?)

## Step 2. Map everything to MITRE ATT&CK

**What:** Tag each incident and each custom rule with its **MITRE ATT&CK** technique ID (failed SSH logins = T1110 Brute Force, for example). Wazuh already shows ATT&CK tags on many alerts.

**Why it matters:** ATT&CK is the shared vocabulary security teams use. Recruiters and interviewers recognize it right away.

**Cost:** free, it's documentation.

## Step 3. Add Active Directory (the biggest realism jump)

**What:** Add a small domain controller VM (Windows Server, `dc01`, now planned at 10.0.1.50 because web-srv took .40) and join win-srv to the domain. Then detect identity attacks inside your lab: password spraying, Kerberoasting, and new users added to the Domain Admins group.

**Why it matters:** Almost every company runs Active Directory, and most real breaches involve stolen or abused accounts in it. "I detected Kerberoasting in my AD lab" is a strong interview story.

**Cost:** one more Windows VM, so deallocate it whenever you aren't using it.

**Security+:** Identity and access management, attack types (Threats domain).

## Step 4. Prove your detections: safe attack simulation

**What:** Use **Atomic Red Team**, small scripted tests where each one simulates a single ATT&CK technique. Run them VM-to-VM inside 10.0.1.0/24, the same assumed-breach rule as your exercises and never through the public RDP door. For each test, ask: did Wazuh alert? If not, write a rule (Step 1) and test again.

**Why it matters:** This is called **purple teaming** (attack, check detection, fix, repeat). You end up with a coverage table that says "these techniques are detected, these aren't yet." That's honest, measurable evidence.

**Cost:** free tools, and it runs on VMs you already have.

## Step 5. Network visibility: Suricata IDS

**What:** Install **Suricata** (a network intrusion detection system) on linux-srv or the Wazuh VM and send its alerts to Wazuh. Your port-scan exercises will then show up as *network* alerts as well as host logs.

**Why it matters:** Host logs and network logs catch different things. This is also where your Network+ material (ports, protocols, packet capture) becomes hands-on.

**Note:** Azure won't let one VM easily see another VM's traffic (no network "mirror" port like a physical switch has), so Suricata mostly sees traffic to and from the VM it runs on. That limit is a good thing to explain in an interview.

## Step 6. Automated response

**What:** Turn on Wazuh **active response**. For example, automatically block an IP on linux-srv after repeated failed SSH logins. Optionally add the **VirusTotal** integration to check suspicious files.

**Why it matters:** Detection alone isn't enough, because someone has to respond. Automation is how small security teams keep up.

**Careful:** auto-blocking can lock *you* out. Test it on linux-srv, never on win-srv (your only way in).

## Step 7 (optional). Cloud security on Azure itself

**What:** Turn on **Microsoft Defender for Cloud's** free tier and review what it flags about your own Azure setup (open ports, missing updates, NSG rules).

**Why it matters:** Your lab runs *in* the cloud, so securing the cloud account is its own skill. This is a good bridge if you get interested in cloud security roles.

---

## Suggested order and pacing

| Order | Step | New cost | Good time to do it |
|---|---|---|---|
| 1 | Sysmon + custom rules | none | Right after Phase 1 |
| 2 | ATT&CK mapping | none | Alongside step 1 |
| 3 | Atomic Red Team testing | none | After step 1 |
| 4 | Active Directory | 1 VM | When ready for another VM |
| 5 | Suricata | none | While studying Security+ networking topics |
| 6 | Active response | none | Anytime after step 1 |
| 7 | Defender for Cloud | free tier | Optional |

Every step should end the same way as Phase 1: a short write-up in the repo (incident report or detection note), redacted per the publishing checklist.

## What *not* to do yet

- Don't start a second, unrelated lab (malware analysis, a home router, a big Kubernetes cluster). That's the "pile of experiments" trap your plan warns about.
- Don't let this delay finishing and publishing the unit 2 case study. It's something to talk about in interviews as "what I'm doing next."
- Don't do offensive work outside your own lab, ever.

## How it connects to Security+

Steps 1 to 6 cover a lot of the Security Operations and Threats/Vulnerabilities domains hands-on. A good rhythm is to study the Security+ chapter that matches the Phase 2 step you're on, so the theory and the practice back each other up.

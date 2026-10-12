# 06 · Detection engineering (unit 4)

**Story for the write-up:** in unit 2 you *read* alerts. Here you *build* them:
better logs on Windows, network alerts, your own rules, tests that prove they
work, and a map of what you can and can't detect.

Do the steps in order. Each ends with something to screenshot. The plan and the
why are in [docs/plan/detection-engineering.md](../../docs/plan/detection-engineering.md);
the matching lessons are round 2 in `lab/exercises` (`./run.sh env add detect`
once steps 1 and 2 are done).

## 0. Pull the latest repo everywhere

On wazuh, linux-srv and win-srv: `git pull` in your copy of the repo. Then on
**wazuh** re-run the manager setup so the agents get the new configs:

```bash
sudo bash ~/security-homelab/lab/wazuh/setup-manager.sh
```

## 1. Sysmon on win-srv

Windows' own logs say *who logged in*. Sysmon says *what they did after*: every
program started, with its command line and parent.

In an **administrator** PowerShell on win-srv, from the repo's `lab\windows` folder:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Install-Sysmon.ps1
```

It downloads Sysmon from Microsoft, checks the signature, installs it with
`sysmon\sysmon-lab.xml`, and shows the first events. Read the XML first: it's
short, and every section says what it logs and why.

**Check:** in Wazuh, search `agent.name: win-srv` and
`data.win.system.channel: Microsoft-Windows-Sysmon/Operational`. Open Notepad
on win-srv and find its process-start event. 📸

> Predict first: will Sysmon give you more *alerts*, or just more *logs*?

**Tuning:** if one program floods the log, add an exclude to the XML, write a
comment saying why, and run `.\Install-Sysmon.ps1` again to apply it.

## 2. Suricata on linux-srv

A network IDS reads the traffic itself and matches it against published rules.
On **linux-srv**:

```bash
free -m                                    # how much memory is there?
sudo bash ~/security-homelab/lab/linux/setup-suricata.sh
```

linux-srv has 1 GB of memory, so the script will stop and explain. Re-run with
`--low-memory-ok` to use Suricata's low-memory profile and a swap file, then
check `free -m` again: the Wazuh agent must still be running
(`systemctl is-active wazuh-agent`).

**Check:** `sudo tail -n 3 /var/log/suricata/eve.json` shows events, and in
Wazuh, `agent.name: linux-srv` with `rule.groups: suricata` shows alerts once
something matches (lesson C4 gives it something to match). 📸

**What Suricata can't see:** in Azure, only traffic to and from linux-srv.
There's no mirror port for other VMs' traffic. Say that in your write-up; it's a
good interview point.

## 3. Rules as code: test before you trust

Every rule the lab relies on has a test in `lab/wazuh/tests/`: a sample log
line and the rule it must fire. On **wazuh**:

```bash
sudo bash ~/security-homelab/lab/wazuh/test-rules.sh
```

All should pass. When you write your own rule (lessons A4, B4), add a test for
it in a new file, for example `tests/my-rules.tests`, using the same format
(the top of `test-rules.sh` explains it). A rule without a test is a guess.

Anywhere with Docker you can run the same tests against a throwaway manager,
without touching the lab: `bash lab/wazuh/test-rules-docker.sh`.

## 4. Atomic Red Team: prove a detection with a real technique

Atomic Red Team is a public library of small tests, each one simulating a single
MITRE ATT&CK technique, so you can check whether your detections notice it. Use
it on **win-srv only**, one test at a time, and always run the cleanup.

In an administrator PowerShell on win-srv:

```powershell
Install-Module -Name invoke-atomicredteam, powershell-yaml -Scope CurrentUser
Import-Module invoke-atomicredteam
```

Then get the test definitions (the "atomics" folder, normally
`C:\AtomicRedTeam\atomics`) the way the project's own guide says, since the
exact command changes between versions:
https://github.com/redcanaryco/invoke-atomicredteam/wiki/Installing-Atomic-Red-Team

Microsoft Defender may quarantine parts of the atomics folder, because it
contains examples of attacker behaviour. Read what it flagged before deciding
anything. Don't turn Defender off; an exclusion for `C:\AtomicRedTeam` only, while
you work, is the usual approach, and you remove it afterwards.

The loop (lesson F4 walks you through one):
1. `Invoke-AtomicTest <technique id> -ShowDetailsBrief`: read what each test does.
2. `Invoke-AtomicTest <technique id> -TestNumbers <n> -CheckPrereqs`
3. Run that one test, look for it in Wazuh, note whether an alert fired.
4. `Invoke-AtomicTest <technique id> -TestNumbers <n> -Cleanup`
5. No alert? Write a rule, add a test for it, try again.

## 5. Active response (optional)

Lesson A4/active-response-block sets up Wazuh to block a brute-forcing source on
linux-srv automatically. Never on win-srv: it's your only way in.

## 6. What to hand over

- Screenshots: a Sysmon process event, a Suricata alert in Wazuh, the rule tests passing.
- Your own rule(s) and their test file.
- A coverage table: technique, data source, detected yes or no, rule id (lesson F4).
- One paragraph on what Sysmon and Suricata *can't* see in this lab.

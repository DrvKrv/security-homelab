# Level 1 — Detect: SSH brute force

## The concept
A **brute-force** (or password-guessing) attack is when someone tries many
username/password combinations against a login service, hoping one works. SSH
(port 22) is the main remote-login service on Linux, and it's one of the most
scanned services on the internet. Each failed attempt leaves a line in the
Linux authentication log (`/var/log/auth.log`), and the Wazuh agent ships those
lines to the SIEM, which turns a burst of them into a single, higher-severity
alert.

Being able to recognise this pattern is the most basic SOC-analyst skill. In
this exercise nothing is compromised — you're learning to *see* the attempt.

## Your mission
Someone on the network is hammering SSH on **linux-srv**. Using only the Wazuh
dashboard, work out:
1. That a brute-force attempt is happening (which alert fires, and at what level).
2. **Which machine** the attempts are coming from.
3. **Which account(s)** are being targeted.
4. Whether any attempt actually **succeeded**.

## The analyst workflow (how to approach it, not the answer)
1. Open the dashboard and go to **Threat Hunting > Events**. Set the time range
   to the last 15 minutes.
2. Don't start from the answer. Start broad: filter to the linux-srv agent, then
   look at what rule groups light up (`authentication_failed`, `authentication_failures`).
3. Notice the difference between *one* failed login (noise) and a *burst* that
   trips a dedicated "multiple authentication failures" rule. That escalation is
   the whole point of a SIEM.
4. For each interesting alert, click it and read the **raw log line** inside
   (`data.srcip`, `data.srcuser`, the full message). The alert is a summary; the
   raw line is the evidence you cite.

## Predict before you run
Before you stage it, write down: how many failed logins in a short window do you
think it should take to turn individual "failed login" events into one
"brute force" alert? Then check what actually happened.

## What good looks like
Fill a copy of `../../case-file-template.md`: the timeline of the burst, the
source IP, the targeted account(s), the rule IDs that fired, and your
conclusion about whether it succeeded. One or two screenshots of the alerts make
it portfolio-ready.

## Hints
1. The attack runs in two rounds. Round one uses usernames that don't exist on the box; round two uses a real account with wrong passwords. They trip *different* rules — look for two distinct alert types, not one.
2. In an event, `data.srcip` is the attacker and `data.srcuser` (or the message text) is the account being tried. The source IP will be one of your own lab VMs.
3. A "non-existent user" burst and a "valid user, wrong password" burst are both brute force but are logged differently. Find the rule for each.
4. To answer "did it succeed?", search the same window for a *successful* SSH login (rule group `authentication_success`) from that same source IP. Its absence is itself a finding — say so explicitly.

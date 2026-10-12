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

**One detail about your lab:** out of the box, linux-srv accepts **SSH keys
only**. Password login is disabled, which is the Azure default and a real
hardening win. The lab's `setup-linux-srv.sh` turns password login back on for
a throwaway test account so this exercise has something to guess against.
Whether that's been done on your linux-srv changes what the logs show, and
working that out from the logs is part of the exercise.

## Your mission
Someone on the network is hammering SSH on **linux-srv**. Using only the Wazuh
dashboard, work out:
1. That an SSH attack is happening (which alert fires, and at what level).
2. **Which machine** the attempts are coming from.
3. **Which account(s)** are being targeted.
4. Whether any attempt actually **succeeded**.
5. Whether the attacker could even **try passwords** on this server, and how
   the logs tell you.

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
1. The attack tries two things: usernames that don't exist on the box, and a real account (`labuser`) with wrong credentials. The **invalid-user** attempts are your most reliable signal here — look for them first.
2. In an event, `data.srcip` is the attacker and `data.srcuser` (or the message text) is the account being tried. The source IP will be one of your own lab VMs.
3. Compare the two kinds of attempt. If password login is on, guesses against the real account show up as failed passwords. If the server is key-only, they never reach a password check, so you'll see something quieter instead. Which did you get, and what does that say about linux-srv's SSH settings?
4. To answer "did it succeed?", search the same window for a *successful* SSH login (rule group `authentication_success`) from that same source IP. Its absence is itself a finding — say so explicitly.

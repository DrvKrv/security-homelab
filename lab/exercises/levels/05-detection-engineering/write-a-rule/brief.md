# Level 5 — Detection engineering: write your own rule

## The concept
So far you've *consumed* detections. Now you'll *build* one. This is the step
from analyst toward engineer, and it's a strong portfolio signal because it shows
you understand how the SIEM actually works, not just how to read its output.

Wazuh turns a raw log line into an alert in two stages:
1. A **decoder** pulls fields out of the line (user, source IP, program).
2. A **rule** matches on those fields and assigns a **level** (severity) and a
   **rule id**. Rules can **chain**: your rule can say "when the built-in rule X
   fires *and also* this extra condition holds, raise it higher."

Your custom rules live in `lab/wazuh/manager/local_rules.xml`, and custom rule
ids use the **100000+** range so they never clash with Wazuh's own. You test them
**offline** with `wazuh-logtest` — paste a log line, see which rules fire — so you
never have to stage a real event to know your rule works.

## Your mission
The default ruleset logs a **successful SSH login as root** the same as any other
successful login. But direct root login over SSH is a red flag (it should be
disabled, and admins should log in as themselves and then `sudo`). Write a rule
that **raises a successful root SSH login to a high level** (say level 12) with
its own rule id, and prove it fires using `wazuh-logtest`.

## The analyst workflow
1. Look at how the lab's existing custom rules are written
   (`lab/wazuh/manager/local_rules.xml`) — copy the shape.
2. Find the built-in rule id for a *successful* SSH login (use `wazuh-logtest` on
   a normal success line and read which rule id matches). You'll chain to it with
   `if_sid`.
3. Write a new rule (id in the 100300 range) that chains to that success rule and
   adds the condition "user is root", with `<level>12</level>` and a clear
   `<description>`.
4. Validate the ruleset (`wazuh-analysisd -t`) and test with `wazuh-logtest`.

## Predict before you run
Before writing anything, ask: should your rule match the *raw text* "root", or
the decoded **user field**? Why is matching the decoded field more reliable?

## What good looks like
A new rule in `local_rules.xml`, a clean `wazuh-analysisd -t`, and a
`wazuh-logtest` run showing your rule id (100300) firing at level 12 on a root
SSH-success line. Paste that logtest output into your case file — it's the proof.

## Hints
1. Don't start from scratch. Open `lab/wazuh/manager/local_rules.xml` and mimic an existing custom rule's structure (`<rule id=... level=...>`, `<if_sid>`, `<description>`).
2. Find the base rule to chain from: run a normal "Accepted password/publickey for <user>" line through `wazuh-logtest` and note the rule id it triggers. Your rule uses `<if_sid>that id</if_sid>`.
3. Match on the decoded user, not raw text — e.g. `<field name="dstuser">^root$</field>` (check the exact field name your version decodes to via logtest's output).
4. Always `wazuh-analysisd -t` before restarting, so a typo can't take the manager down. Then confirm with `wazuh-logtest`.

## Stretch goals (more variants, same level)
- A rule that fires when a successful login follows a brute-force from the same
  IP (chain off the brute-force rule).
- A rule that raises FIM alerts on `/etc/shadow` specifically to a higher level.
- A rule for a service account (like `svc_backup`) using sudo.

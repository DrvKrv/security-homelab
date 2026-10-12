# Answer key: Map your detections to MITRE ATT&CK and publish a coverage map

Your map is your own. This key shows the shape of a good one and the entries
the lab supports today, so you can check yours. Status is what the repo's tests
prove; your own staging results may move more rows to "tested".

## A starting table
| Technique | Name | Tactic | Detection | Evidence | Status |
|---|---|---|---|---|---|
| T1110.001 | Password Guessing | Credential Access | 5710/5712, 5760/5763 (SSH); 60122/60204 (Windows); 100401/100402 (portal) | `lab/wazuh/tests/` (SSH, portal); lessons A1, A2 | tested |
| T1046 | Network Service Discovery | Discovery | 100100-100102 (UFW blocks, port scan); your C4 Suricata rule | `tests/firewall.tests`; lessons C1, C4 | tested |
| T1136.001 | Create Account: Local Account | Persistence | 5902 (Linux); Windows account-created events | `tests/ssh-and-accounts.tests`; lessons B1, B3 | tested |
| T1098 | Account Manipulation | Persistence | 100110 (added to sudo group) | `tests/ssh-and-accounts.tests` | tested |
| T1548.003 | Sudo and Sudo Caching | Privilege Escalation | your B4 rule on sudoers files | lesson B4 verify | tested if you did B4 |
| T1059.001 | PowerShell | Execution | Sysmon process events; your F4 encoded-PowerShell rule | lesson F4 (encoded-powershell-rule) | tested if you did it |
| T1053.005 | Scheduled Task | Persistence | Windows task-created event; Sysmon file events in `System32\Tasks` | lessons F2, F3 | untested until staged |
| T1021 | Remote Services | Lateral Movement | network zones (prevention, not detection) | lesson C4 (zones) | prevented, not detected |

## The assigned atomic
Whatever happened is the right answer, as long as it's recorded honestly:
- **Alert fired:** note the rule id and level, and move the row to "tested".
- **Only raw events (no alert):** the data is there but no rule raises it; that's
  a "detectable, not alerted" gap, and the fix is a rule plus a test.
- **Nothing at all:** the log source is missing (for example Sysmon doesn't log
  that event type in the lab config); the fix starts with collection.
Always run the atomic's `-Cleanup`.

## A good gaps section names
- what's missing (a technique, a log source, or a rule),
- why it matters here (which machine, which story),
- the next step and how you'll prove it (a test or an atomic).

## Common mistakes
- Copying a rule's existing `<mitre>` tag without checking it fits.
- Marking a row "covered" because a rule exists, with no test.
- Listing hundreds of techniques. A short, honest map beats a big, hopeful one.

## Interview talking point
"I mapped every detection in my lab to MITRE ATT&CK and marked each one tested
or untested based on evidence: rule tests that run sample logs through Wazuh,
staged lessons, or Atomic Red Team. Then I used an atomic test to check a gap,
recorded that it didn't alert, and wrote the rule and test to close it."

# Incident Report: `TODO short title, e.g. "Repeated failed logons on win-client"`

Copy this file to `IR-YYYY-NNN-short-name.md` for each incident. Fill every
section from real evidence; cite the screenshot or log excerpt for each claim.

| Field | Value |
|---|---|
| **Incident ID** | IR-`YYYY`-`NNN` |
| **Date / time detected** | `YYYY-MM-DD HH:MM` (timezone) |
| **Detected by** | Wazuh alert, rule ID `TODO`, level `TODO` |
| **Reported by** | KT (analyst) |
| **Severity** | Low / Medium / High / Critical (justify below) |
| **Status** | Open / Contained / Resolved / Closed |
| **Affected hosts** | `TODO` |
| **Affected accounts** | `TODO` |
| **Simulated?** | Yes: authorized exercise in an isolated lab |

## 1. Summary

Two to four sentences a manager can read: what happened, what was affected,
whether it was malicious, and what was done.

## 2. Detection

- Which alert fired, the rule description, and its level.
- Data source (e.g. Windows Security log via Wazuh agent, `/var/log/auth.log`).
- Screenshot: `../evidence/IR-YYYY-NNN-alert.png`

## 3. Timeline

All times in `TODO timezone`.

| Time | Host | Event (with Event ID / log line) | Source |
|---|---|---|---|
| | | | |

## 4. Investigation

Answer the five questions with evidence:

- **Who:** which account(s)? (e.g. `TargetUserName` in Event 4625)
- **What:** what action was attempted, and did it succeed?
- **Where from:** source host / IP (e.g. `IpAddress`, `WorkstationName`, `sshd` "from" field)
- **When:** first and last occurrence, count of events
- **How:** logon type, protocol, tool used

Queries or filters used in the Wazuh dashboard:

```
TODO paste the search / filter used (no secrets)
```

## 5. Impact assessment

What could this mean in a real organization? Was any data accessed or changed?

## 6. Containment, eradication and recovery

What was done to stop it and restore normal state (e.g. account locked,
password reset, IP blocked, firewall rule added).

## 7. Root cause

Why was this possible? (e.g. no lockout policy, password authentication
enabled on SSH, unnecessary port open)

## 8. Recommendations and follow-up

| Recommendation | Ticket | Owner | Status |
|---|---|---|---|
| | [REM-YYYY-NNN](../tickets/) | KT | |

## 9. Lessons learned

What would make this faster to detect or easier to investigate next time?

---

### Reference: useful log events

| Source | ID / pattern | Meaning |
|---|---|---|
| Windows Security | 4624 | Successful logon |
| Windows Security | 4625 | Failed logon (check `Status` / `SubStatus` codes) |
| Windows Security | 4740 | Account locked out |
| Windows Security | 4720 | User account created |
| Windows Security | 4722 / 4725 | Account enabled / disabled |
| Windows Security | 4724 | Password reset attempted |
| Windows Security | 4728 / 4732 | Member added to global / local security group |
| Windows Security | 5152 / 5157 | Windows Filtering Platform blocked a packet / connection |
| Linux `auth.log` | `sshd ... Failed password for` | Failed SSH password |
| Linux `auth.log` | `sshd ... Invalid user` | Login attempt for a non-existent account |
| Linux `kern.log` / syslog | `[UFW BLOCK]` | Firewall dropped a connection |

Some Windows events only appear after the matching audit policy is enabled
(see [`lab/`](../../lab/)).

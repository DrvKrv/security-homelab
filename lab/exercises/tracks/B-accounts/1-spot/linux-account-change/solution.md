# Answer key: a new Linux admin account

## What happened
On **linux-srv**, acting as an attacker who already had root, the staging
script performed three steps a few seconds apart:
1. Created a user with a service-style name (a deliberately innocuous-looking name;
   it changes every run, see *This run's details* at the end).
2. Added it to the **`sudo`** group, granting admin rights.
3. Set a random password for it.

The account is still present after the exercise. Removing it safely is B3/linux-backdoor-user.

## The alerts you should have found
| Rule | Meaning |
|---|---|
| 5902 | **New user added to the system** |
| 2961 | User added to a group (base rule for the sudo change) |
| 100110 | Lab rule, level 10: user **granted sudo** (raised above the plain 2961) |
| 5555 | PAM: user password changed |
| 550 / 554 | **File-integrity**: `/etc/passwd`, `/etc/group`, `/etc/shadow` modified/added |

- **Account:** the service-style name shown under *This run's details*
- **Privilege:** member of `sudo`
- **Corroboration:** the OS audit events (5902/2961) and the FIM events
  (550/554) describe the same change from two independent sources.

## Why it matters / interview answer
"I detected creation of a new privileged account on a Linux host. Wazuh flagged
the user-add, the addition to the sudo group (raised to level 10 by a custom
rule), and the password set, and file-integrity monitoring independently
confirmed that /etc/passwd, /etc/group and /etc/shadow had changed. The account
name mimicked a service account, which is a classic persistence tactic." That
shows you understand both the tactic and defence-in-depth detection.

## Detect it faster next time
- Alert on *any* addition to the `sudo` (or `wheel`) group — admin changes
  should always be deliberate and reviewed.
- Keep FIM on account files; it catches edits made by tools that bypass the
  normal `useradd` logging.

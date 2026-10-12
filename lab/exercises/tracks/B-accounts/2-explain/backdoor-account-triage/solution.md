# Answer key: triage the backdoor account

## The findings
**Account:** `<account>` (random each run; see *This run's details* at the end), created on linux-srv, added to the **sudo** group,
with a password set. Sequence (a few seconds apart):
1. `useradd` → rule 5902 (new user) + FIM 550/554 on `/etc/passwd`.
2. `gpasswd -a <account> sudo` → rule 2961, raised to level 10 by lab rule
   100110, + FIM on `/etc/group`.
3. password set → rule 5555 + FIM on `/etc/shadow`.

## Live state (confirmed read-only on linux-srv)
- `getent passwd <account>` → the account exists, home `/home/<account>`,
  shell `/bin/bash`.
- `id <account>` / `getent group sudo` → `<account>` is a member of `sudo`.
- `ls -la /home/<account>/.ssh/` → **no** authorized_keys planted by this
  scenario (the backdoor here is the password account itself, not a key). Saying
  "I checked for a planted key and found none" is a real finding.

## Corroboration
Two independent sources agree:
- **OS audit** (Wazuh rules 5902 / 2961 / 5555) — what the system's own tooling
  logged.
- **File-integrity monitoring** (550 / 554) — that `/etc/passwd`, `/etc/group`,
  `/etc/shadow` actually changed.
When both agree, your finding is solid; if only one fired, you'd ask why.

## Scope
Within the window, the only anomalous activity is this account and its three
changes. No other new users, no SSH key persistence, no sudo *use* yet. A
defensible conclusion: **scope limited to creation of one rogue privileged
account; no evidence of further activity** — backed by having actually searched
the window, not assumed.

## Why it matters / interview answer
"Before remediating, I scoped the change: I built the timeline from OS audit and
file-integrity alerts, confirmed the account's live state and sudo membership
on-box read-only, checked for key-based persistence (none), and searched the
surrounding window for other activity (none). Only then was I ready to remove it.
Investigating before responding preserves evidence and tells you whether you're
dealing with one change or a beachhead." That's the textbook ordering, and
interviewers notice when you get it right.

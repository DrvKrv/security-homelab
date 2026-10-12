# Answer key: SSH brute force

## What happened
The **wazuh VM played the attacker** and tried two kinds of SSH guessing against
**linux-srv (10.0.1.30)**:
- **Non-existent users** (admin, oracle, test, postgres, ...). sshd logs each as
  `Invalid user <name> from <srcip>` during preauth, *regardless* of which auth
  methods are enabled.
- **The real test account `labuser`** with random wrong passwords. What this
  produces depends on linux-srv's SSH settings:
  - **Password login on** (after `setup-linux-srv.sh`): each guess is a
    "Failed password" event.
  - **Key-only** (the Azure default): the staging script notices the server
    refuses passwords and skips this round, so there are no password events at
    all.

No attempt succeeded. There is **no** matching `authentication_success` event
from the attacker's IP, so "it did not succeed" is the correct, evidence-backed
conclusion.

## The alerts you should have found
| Rule | Meaning | Note |
|---|---|---|
| 5710 | Attempt to log in with a **non-existent user** | one per invalid-user try — your main signal |
| 5712 | **sshd: brute force trying to get access** (non-existent users) | fires after ~6–8 invalid-user tries |
| 5760 | sshd: authentication failed (wrong password, real user) | only if password login is on |
| 5763 | **sshd: brute force** (multiple auth failures) | only if password login is on |
| 5503 / 5551 | PAM's view of the same failed passwords | only if password login is on |

- **Source (attacker):** the wazuh VM's IP, 10.0.1.10.
- **Target:** linux-srv, 10.0.1.30, port 22.
- **Accounts targeted:** a list of invalid names, plus `labuser`.

**If you saw no password failures at all**, linux-srv is key-only, so the
password round never ran. On a key-only server a real user's connection
attempts show up at most as rule 5762 ("sshd: connection reset", level 4), with
no password check. Spotting that an expected alert is missing, and explaining
why, is a strong finding.

The single-try rules (5710, 5760) are low level. The correlation rules (**5712**,
and **5763** when passwords are on) are the ones that matter, because they're how
a SIEM turns a burst of noise into one actionable alert.

## Why it matters / interview answer
"I spotted an SSH attack by its signature: a burst of invalid-user logins from a
single source, which tripped Wazuh's correlation rule 5712. I confirmed the
source IP and the targeted accounts from the raw auth.log events, and confirmed
there was no successful login from that source. I also checked whether
the password guesses reached a password check, which told me whether the server
allows password login at all. If it's key-only, that's the host's hardening doing
its job, and recognising *why* an expected alert is absent is as important as
reading the ones that fire." That detect-confirm-*and-explain* story
is exactly what interviewers want.

## Detect it faster next time
- An **active response** that blocks the source IP after N failures (fail2ban,
  or Wazuh active-response) would stop the attack mid-stream.
- A dashboard **visualisation** of failed-logins-by-source makes a spike obvious
  at a glance.

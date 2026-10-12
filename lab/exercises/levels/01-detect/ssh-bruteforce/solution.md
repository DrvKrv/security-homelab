# Answer key — SSH brute force

## What happened
The **wazuh VM played the attacker** and tried two kinds of SSH guessing against
**linux-srv (10.0.1.30)**:
- **Non-existent users** (admin, oracle, test, postgres, ...). sshd logs each as
  `Invalid user <name> from <srcip>` during preauth, *regardless* of which auth
  methods are enabled.
- **The real test account `labuser`** with random wrong credentials. But
  linux-srv is **key-only** (password auth disabled), so sshd refuses the
  password method before any password is checked. These attempts show up as
  rejected / closed connections, **not** as "Failed password" events.

No attempt succeeded. There is **no** matching `authentication_success` event
from the attacker's IP. "It did not succeed" is the correct, evidence-backed
conclusion — and here it's doubly true, because password login wasn't even
possible.

## The alerts you should have found
| Rule | Meaning | Note |
|---|---|---|
| 5710 | Attempt to log in with a **non-existent user** | one per invalid-user try — your main signal |
| 5712 | **sshd: brute force trying to get access** (non-existent users) | fires after ~6–8 invalid-user tries |
| 5758 / "Connection closed … [preauth]" | repeated connections refused before auth completes | the valid-user attempts land here, since password auth is off |

- **Source (attacker):** the wazuh VM's IP, 10.0.1.10.
- **Target:** linux-srv, 10.0.1.30, port 22.
- **Accounts targeted:** a list of invalid names, plus `labuser`.

**What you will NOT see, and why:** rules **5760 / 5763** ("sshd authentication
failed" / password brute force) and the PAM failure rules (5503 / 5551). Those
require the server to actually process a password attempt. Because linux-srv only
accepts keys, the password method is refused up front, so those events never
fire. On a host with password login *enabled*, the `labuser` round would trip
5760/5763 — that's worth knowing, but it's not this lab.

The single-try rule (5710) is low level; the **5712** correlation rule is the one
that matters — it's how a SIEM turns a burst of invalid-user noise into one
actionable alert.

## Why it matters / interview answer
"I spotted an SSH attack by its signature: a burst of invalid-user logins from a
single source, which tripped Wazuh's correlation rule 5712. I confirmed the
source IP and the targeted accounts from the raw auth.log events, and confirmed
there was no successful login from that source. I also noted that the
password-guessing attempts produced no 'Failed password' alerts — because the
host is key-only, so sshd refused the password method outright. That's the host's
hardening doing its job, and recognising *why* an expected alert is absent is as
important as reading the ones that fire." That detect-confirm-*and-explain* story
is exactly what interviewers want.

## Detect it faster next time
- An **active response** that blocks the source IP after N failures (fail2ban,
  or Wazuh active-response) would stop the attack mid-stream.
- A dashboard **visualisation** of failed-logins-by-source makes a spike obvious
  at a glance.

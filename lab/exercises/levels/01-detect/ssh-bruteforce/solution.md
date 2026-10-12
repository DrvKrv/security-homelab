# Answer key — SSH brute force

## What happened
The **wazuh VM played the attacker** and ran two rounds of SSH login attempts
against **linux-srv (10.0.1.30)**:
- **Round 1 — non-existent users** (admin, oracle, test, postgres, ...). sshd
  logs each as `Invalid user <name> from <srcip>`.
- **Round 2 — the real test account `labuser`** with random wrong passwords.
  sshd logs each as a failed password for a valid user.

No attempt succeeded. The script never sends a correct password, so there is
**no** matching `authentication_success` event. "It did not succeed" is the
correct, evidence-backed conclusion.

## The alerts you should have found
| Rule | Meaning | From |
|---|---|---|
| 5710 | Attempt to log in with a non-existent user | each round-1 try |
| 5712 | **sshd: brute force trying to get access** (non-existent users) | fires after ~6–8 round-1 tries |
| 5760 | sshd: authentication failed | each round-2 try |
| 5763 | **sshd: brute forcing / multiple auth failures** | fires after the round-2 burst |
| 5503 / 5551 | PAM authentication failures (same events, PAM's view) | round 2 |

- **Source (attacker):** the wazuh VM's IP, 10.0.1.10.
- **Target:** linux-srv, 10.0.1.30, port 22.
- **Accounts targeted:** a list of invalid names (round 1) and `labuser` (round 2).

The single-try rules (5710, 5760) are low level; the **5712 / 5763** correlation
rules are the ones that matter — they're how a SIEM turns noise into one
actionable alert.

## Why it matters / interview answer
"I spotted an SSH brute-force by its signature: a burst of failed logins from a
single source in a short window, which tripped Wazuh's correlation rules 5712
and 5763. I confirmed the source IP and target account from the raw auth.log
events, and confirmed there was no successful login from that source, so the
attempt failed." That is exactly the detect-then-confirm story interviewers want.

## Detect it faster next time
- An **active response** that blocks the source IP after N failures (fail2ban,
  or Wazuh active-response) would stop the attack mid-stream.
- A dashboard **visualisation** of failed-logins-by-source makes a spike obvious
  at a glance.

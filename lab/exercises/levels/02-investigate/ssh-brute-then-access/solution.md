# Answer key — did the SSH attacker get in?

## The conclusion
**No. The brute-force attempt failed; no SSH session was ever established.**

The staging tries invalid usernames and a real account (`labuser`) with wrong
credentials. It never sends a correct credential, so there is no
`authentication_success` event from the attacker's IP. On top of that, linux-srv
is **key-only** (password login disabled), so the password attempts can't even
be processed. The correct finding is a *failed* attempt, not a breach.

## The timeline you should have built
| Time | Source | Event | Evidence |
|---|---|---|---|
| T+0 | 10.0.1.10 | First invalid-user attempt | rule 5710 |
| ~T+6–8 | 10.0.1.10 | Brute-force (non-existent users) alert | rule 5712 |
| ~T+mid | 10.0.1.10 | `labuser` attempts refused before a password check | connection closed/refused (key-only host) |
| — | 10.0.1.10 | **No** "Failed password" (5760/5763) | password method disabled → those rules can't fire |
| — | 10.0.1.10 | **No** successful login | *absence* of `authentication_success` |

- **Source:** 10.0.1.10 (wazuh VM). **Target:** 10.0.1.30 (linux-srv), port 22.
- **Accounts:** invalid names, plus `labuser`.
- **Note:** the absence of 5760/5763 isn't a gap in your investigation — it's a
  consequence of the host being key-only. Call that out explicitly; it shows you
  understand *why* the logs look the way they do.

## If it HAD succeeded — what you'd check next (scoping)
This is the part that shows investigative depth:
- A successful SSH login (the event that's *missing* here) from that IP.
- **Privilege escalation**: sudo use (rule groups around `sudo`), or a new
  account (the Level 3 scenario — rules 5902/2961).
- **Execution**: unusual processes or commands run by `labuser`.
- **Persistence**: new SSH keys in `~/.ssh/authorized_keys`, new cron jobs.
- **Exfil / C2**: unexpected outbound connections from linux-srv.

## Why it matters / interview answer
"I was handed an SSH brute-force alert and treated it as an incident. I built the
timeline from the auth log, bracketed the attack window, and then specifically
searched for a successful authentication from the attacker's source inside and
after that window. There was none, so my finding was a failed attempt — no
compromise. I also documented what I *would* have pivoted to if it had
succeeded." Reaching a correct negative conclusion, with evidence, is a mark of a
disciplined analyst.

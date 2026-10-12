# Answer key: Failed logins on the employee portal

## What happened
You typed wrong passwords into the Acme portal from win-srv's browser. Each
attempt made the portal write one line to `/var/log/acme-portal/auth.log` on
web-srv, for example:

```
2026-10-12T14:03:11Z acme-portal AUTH result=failure user=demo.user src=10.0.1.20
```

The Wazuh agent shipped the line, the lab's `acme-portal` decoder pulled out the
fields, and the web-srv rules turned it into an alert.

## The evidence
| Rule | Level | Meaning |
|---|---|---|
| 100401 | 5 | Acme portal: failed login for `$(srcuser)` from `$(srcip)`. One per attempt. |
| 100402 | 10 | Acme portal: possible brute force. 6 failures within 120 s from one address. |
| 100400 | 3 | Acme portal: successful login. Only if you also signed in correctly. |

Decoded fields on each event: `status` (success or failure), `srcuser` (the
username typed) and `srcip` (where the request came from).

## Answers to the mission
1. **Single failure:** rule **100401**, level 5, "Acme portal: failed login for
   ... from ...".
2. **Account and count:** whatever username you typed (most people use the demo
   account shown on the login page, `demo.user`). The count matches your tries.
   Note that the portal logs a failure even for a username that does not exist.
3. **Source:** `10.0.1.20`, which is **win-srv**. nginx adds an
   `X-Forwarded-For` header and the portal logs that, so you see the real visitor
   rather than the proxy's internal Docker address. That is the predict answer.
4. **Correlation:** rule **100402** fires only if 6 failures land within 120
   seconds from the same address. Fewer tries, or slow typing, means no 100402.
   Both outcomes are correct as long as you explain which happened.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing. Repeated wrong passwords against a
login page is the textbook example, even when the "attacker" is you.

## Common mistakes
- Searching the wrong agent. The portal runs on web-srv, so its alerts carry
  `agent.name: web-srv`, not win-srv where you typed.
- Expecting the operating system's auth log to show portal logins. It does not;
  only the app's own log does.
- Reporting the source as the Docker proxy address instead of checking `srcip`.
- Calling it an attack. Here it was a test. The skill is reading the evidence.

## Interview talking point
"Web applications need their own authentication logging, because the OS never
sees an app login. In my lab the portal writes a structured auth log, Wazuh
decodes it, and I have one rule per failure plus a correlation rule for six
failures in two minutes from one address. I also checked that the logged source
was the real client, not the reverse proxy, because a wrong source IP makes every
later investigation point at the wrong machine."

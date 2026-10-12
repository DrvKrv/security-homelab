# Answer key: Failed domain logons

## What happened
You tried to sign in to dc01 with a domain account and a wrong password a few
times. dc01 is both the machine you were signing in to and the DC that checks
domain passwords, so it logged both sides: the failed logon and the failed
password check.

## The evidence
| Where | Id | Meaning |
|---|---|---|
| Windows Security on dc01 | 4625 | An account failed to log on. One per attempt. |
| Wazuh | 60122 | Windows logon failure (built from 4625). |
| Wazuh | 60204 | Multiple Windows logon failures. Only if enough failures land close together. |
| Windows Security on dc01 | 4776 | NTLM credential validation (with an error code when it fails). |
| Windows Security on dc01 | 4771 | Kerberos pre-authentication failed. |

Fields inside each 4625 that matter: `targetUserName` and `targetDomainName`
(who), `logonType` (how), `status` and `subStatus` (why), `workstationName` and
`ipAddress` (from where).

## Answers to the mission
1. **Event and alert:** Windows **4625**, shown in Wazuh as rule **60122**.
2. **Account:** the account you used, most likely `demo.user` in `ACME`. The
   count matches your tries (3 or fewer).
3. **Logon type and reason:** with Remote Desktop and Network Level
   Authentication, the password is checked before the desktop opens, so the
   failure is usually logon type **3** (network). A wrong password shows
   `subStatus` **0xC000006A**; a username that does not exist shows **0xC0000064**.
4. **Source:** `ipAddress` is **10.0.1.20** (win-srv), and `workstationName` is
   win-srv's computer name.
5. **Password check:** connecting by IP address means Kerberos cannot be used
   (Kerberos needs a name to find the right service), so Windows falls back to
   NTLM and the DC logs **4776**. If you connected by name you may see **4771**
   instead. Seeing 4776 is the predict answer. If neither appears, the DC's
   credential-validation auditing may be off; note it as a gap.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing. Repeated wrong passwords for one
domain account. A real case would need more tries, but the evidence looks the same.

## Common mistakes
- Typing a wrong password more times than the lockout policy allows and locking
  the account. Then you are investigating a lockout (4740, rule 60115) too.
- Reading only the Wazuh description and skipping `subStatus`. The reason code
  is what tells "wrong password" from "no such user".
- Treating the logon type as a guess. Look it up: 2 is at the keyboard, 3 is
  over the network, 10 is a full remote desktop session.

## Interview talking point
"For domain accounts I watch the domain controller, because every domain logon
asks it to check the password. A failed attempt gives me a 4625 with the target
account, logon type and a status code, plus the DC's own credential check, 4776
for NTLM or 4771 for Kerberos. In my lab, connecting by IP forced NTLM, which is
a nice example of why you need to know how authentication works to read the logs."

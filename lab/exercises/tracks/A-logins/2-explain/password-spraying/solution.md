# Answer key: Password spraying: one password tried on many accounts

## What happened
One source tried a single wrong password once each against several real domain
accounts, inside a few minutes. No account got more than one failure, so nothing
locked out. Until the scripted staging arrives, the "attacker" is you at win-srv.

## The evidence
| Where | Id | What it shows |
|---|---|---|
| dc01 Security log | 4625 / Wazuh 60122 | One failed logon per account tried |
| 4625 fields | `targetUserName` | A different account on almost every event |
| 4625 fields | `ipAddress`, `workstationName` | The same source on every event |
| 4625 fields | `subStatus` 0xC000006A | Real accounts, wrong password |
| dc01 Security log | 4776 or 4771 | The DC checking each password (NTLM or Kerberos) |
| dc01 Security log | 4624 | A success from that source, if one happened |

## Answers to the mission
1. **Spraying.** Distinct accounts per source: several (4 or 5 in the hand-made
   version, many more in a real attack). Failures per account: 1. A brute force
   would show one account with many failures.
2. **Window:** first to last 4625 from that source. Typically a few minutes.
3. **Source:** `ipAddress` 10.0.1.20 and win-srv's workstation name.
4. **Accounts:** real staff accounts from the seeded roster. The 0xC000006A
   code proves they exist, which means the attacker already had a list of valid
   usernames. A list of made-up names would show 0xC0000064 instead.
5. **Success:** no 4624 from the source if every password was wrong, which is
   the hand-made case. A real spray that finds one weak password shows a single
   4624 for that account, and that account is now compromised.
6. **The "many failures" rule:** 60204 most likely did **not** fire. Read its
   definition: it needs several failures that share a condition (check which
   field it groups on in your version). One failure per account across a handful
   of accounts stays under it. That is the whole point of spraying.

## MITRE ATT&CK
T1110.003 Brute Force: Password Spraying. One password, many accounts, staying
below lockout. A success would lead to T1078.002 Valid Accounts: Domain Accounts.

## Common mistakes
- Calling it "a few typos" because each account only failed once. Look across
  accounts, not within one.
- Assuming lockout would have stopped it. Lockout counts per account; spraying
  never reaches the count.
- Forgetting to check for a success. The failures are noise; one 4624 is the incident.
- Trying the hand-made version on one account several times. That is a brute
  force, not a spray, and it may lock the account.

## Interview talking point
"Password spraying looks harmless account by account: one failure each. I caught
it by pivoting the other way, counting distinct accounts per source, which showed
one address touching many accounts in minutes. The status code told me the
usernames were real, so the attacker had a staff list. Per-account rules and
lockouts miss this by design, which is why I then wrote a rule that counts
accounts per source."

# Answer key: Portal brute force: which accounts, which source

## What happened
You played the attacker from win-srv's browser: a fast run of wrong passwords
against a few portal usernames, then one correct sign-in with the demo account.
The portal logged every attempt, Wazuh raised one alert per failure, and once
enough failures landed close together it raised the brute-force correlation
alert. The final correct sign-in produced a success alert from the same source.

## The evidence
| Time | Source | Event | Evidence |
|---|---|---|---|
| T+0 | 10.0.1.20 | First failed portal login | rule 100401 |
| T+6th failure | 10.0.1.20 | Correlation: possible brute force | rule 100402 (6 failures in 120 s) |
| last failure | 10.0.1.20 | End of the guessing | rule 100401 |
| just after | 10.0.1.20 | Successful login | rule 100400, `srcuser` = the account that worked |

Each alert carries `data.srcuser` (the username typed) and `data.srcip`. The
access log on web-srv has one `POST /portal/login` line per attempt, from the
same address, with status **200** for each failure (the form is shown again)
and **302** for the success (redirect to the dashboard).

## Answers to the mission
1. **Window:** from your first 100401 to your last 100401. Use real timestamps.
2. **Source:** `10.0.1.20`, which is win-srv.
3. **Accounts:** the two or three usernames you typed, with a failure count for
   each. Usernames that do not exist are logged too, so they still count.
4. **Success:** yes. One 100400 from 10.0.1.20 right after the last failure, for
   the demo account (`demo.user`). In a real case that is the moment the incident
   becomes a compromise.
5. **Access log:** yes. The `POST /portal/login` lines match the count and the
   source, and the single 302 lines up with the 100400 time.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing. Many guesses in a short burst from one
source. Once a guess works, the follow-on use is T1078 Valid Accounts.

## Common mistakes
- Searching only for 100402 and missing the 100400 success. The correlation
  alert tells you guessing happened, not how it ended.
- Treating the 100402 time as the start of the attack. It fires on the sixth
  failure; the attack began at the first.
- Expecting web requests to show up as Wazuh alerts. Normal 200 responses are
  low-level events that are not stored as alerts, so you read the file directly.
- Counting a failure for a made-up username as harmless. It still shows intent.

## Interview talking point
"I reconstructed a portal brute force from two independent sources: the app's
auth log in Wazuh and the nginx access log on the server. I bracketed the attack
window, counted failures per account, and then looked specifically for a success
from the same address. There was one, so I reported a compromised account rather
than just an attempt. When two logs agree, the conclusion is hard to argue with."

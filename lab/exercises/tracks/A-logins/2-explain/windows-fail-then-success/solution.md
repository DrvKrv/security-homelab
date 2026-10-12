# Answer key: Windows failed logons, then one success?

## What happened
`lab/windows/Simulate-SuccessfulLogon.ps1 -Phase Scenario` ran on win-srv:
1. **Setup (first run only):** it created a throwaway local account with a
   staff-style name (one of `j.morgan`, `t.nguyen`, `a.patel`, `r.santos`,
   `m.kowalski`), in the Users group, with a random password it saved
   encrypted. That's the 4720/4722/4738 events you may have seen before the
   failures.
2. **After a pause:** 2 to 4 wrong passwords for that account, then one each for
   the made-up names `admin`, `administrator`, `backup` and `test`, using
   `Simulate-FailedLogons.ps1`. That stays under the 5-failure lockout.
3. **On about two runs in three:** after another pause, one **successful**
   network logon as the lab account, with its real password.

This run's account, its number of wrong passwords, and whether the success
happened are on the last line of the staging log: `$env:TEMP\lab-stage-A2-windows-fail-then-success.log`.

## The evidence
- **Failures:** event 4625 (Wazuh 60122), one per attempt. `subStatus`
  0xc000006a for the real lab account (right name, wrong password), 0xc0000064
  for the made-up names (no such user). With 8 or more failures in 4 minutes
  you may also see 60204 (multiple logon failures); with 6 or 7 you won't.
- **The success (if it happened):** event 4624 for the lab account,
  **logon type 3** (network), workstation win-srv, typically with no remote
  source address because it was made on win-srv itself. It's followed shortly by
  4634 (logoff). Note the Wazuh rule id on your 4624 alert.
- **Your own logons:** 4624 with **logon type 10** (Remote Desktop) for your
  admin account, with your own source address. Different account, different
  logon type, so they're not part of the story.

## Answers to the mission
1. From the timeline; the account and count are in the staging log.
2. The lab account is real (0xc000006a); `admin`, `administrator`, `backup` and
   `test` don't exist (0xc0000064). (Azure renames the built-in Administrator to
   the admin name you chose, which is why `administrator` doesn't exist.)
3. Either a type 3 success for the lab account some seconds to a minute or so
   after the last failure, or none at all. Check the staging log.
4. Your RDP logons: your admin account, logon type 10, your address.
5. **Success after failures, same account, made-up names tried around it:** treat
   it as a guessed password. Disable the account or reset its password, find
   what it did after logging on, and look for the same source elsewhere.
   **A success with no made-up names, a couple of typos, from the person's usual
   machine:** likely a legitimate user; confirm with them. **No success:** a
   failed attempt; record it, and check the account is not locked out.
   In this lab the "attacker" is the script on win-srv, which is why the source
   is the machine itself.

Cleanup when you're done: `./run.sh reset A2/windows-fail-then-success` prints the
line to remove the lab account.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing. A guessed password used to log on is
also T1078 Valid Accounts.

## Common mistakes
- Filtering only on failures (4625), so the success never shows up.
- Counting your own RDP logon as the attacker's success.
- Ignoring the failure reason codes, which tell real accounts from made-up ones.
- Calling it a breach without checking the success is for an account that was
  being guessed at.

## Interview talking point
"I investigated a run of failed Windows logons and pulled failures and successes
together so a success couldn't hide. Reason codes separated real accounts from
made-up ones, and logon types separated my own Remote Desktop sessions from the
story. Then I checked whether a success for a guessed-at account followed the
failures, and wrote a verdict with next steps for each outcome."

# Answer key: Account lockout policy, before and after

## What happened
You measured the domain's lockout settings, tested them, changed them in the
Default Domain Policy, and tested again with the demo account (`demo.user`).

## The evidence
| Where | Id | Meaning |
|---|---|---|
| dc01 | 4625 / Wazuh 60122 | Each wrong password |
| dc01 | 4740 / Wazuh 60115 | The account was locked out (after the change) |
| dc01 | 4625, `subStatus` 0xC0000234 | Logon refused because the account is locked, even with the right password |
| dc01 | 4624 | The successful sign-in after you unlocked it |

## Answers to the mission
1. **Before:** whatever `net accounts /domain` showed. Many new domains ship with
   lockout **off** (a threshold of 0 means "never lock"), but record your real values.
2. **Before test:** one 4625 per attempt (maybe a 60204 roll-up) and no 4740,
   because you stayed under the threshold or lockout was off.
3. **Change:** in `gpmc.msc`, edit **Default Domain Policy** > Computer
   Configuration > Policies > Windows Settings > Security Settings > Account
   Policies > **Account Lockout Policy**. Set the threshold to 5 attempts, and the
   window and duration to 15 minutes (the lab policy's targets). Windows offers
   suggested values for the other two when you set the threshold; replace them with
   yours. Then on dc01:
   ```powershell
   gpupdate /force
   Get-ADDefaultDomainPasswordPolicy | Format-List LockoutThreshold, LockoutObservationWindow, LockoutDuration
   ```
   Update the two `TODO` values in `docs/security-policy.md`.
4. **After test:** the fifth wrong password inside 15 minutes locks the account:
   **4740** on dc01, Wazuh **60115**. The correct password then fails with
   `subStatus` **0xC0000234**.
5. **Unlock:** `Unlock-ADAccount -Identity demo.user`; `LockedOut` is False and a
   correct sign-in gives a 4624. Without the unlock it would free itself after the
   15-minute duration.
6. **Limits:** lockout does not stop **password spraying** (one try per account
   never reaches the threshold), does not help if the password is already known,
   and can be **abused**: an attacker can lock out everyone on purpose. That is the
   predict answer: the help desk gets a flood of calls and nobody can work.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing is what this control slows down.
T1531 Account Access Removal describes the abuse case, where mass lockouts deny
staff their own accounts.

## Common mistakes
- Testing with your own admin account and locking yourself out of dc01.
- Changing the policy and not reading it back, so you never prove it applied.
- Using `Set-ADDefaultDomainPasswordPolicy` alone; the Default Domain Policy GPO
  is where domain account policy belongs, so set it there.
- Claiming lockout "stops brute force". It slows it and makes it loud.

## Interview talking point
"I treated the lockout policy as a measured change. I recorded the domain's
settings, showed a few bad passwords did nothing, set five attempts in fifteen
minutes in the Default Domain Policy to match our written policy, and proved it:
a 4740 and Wazuh 60115 on the fifth attempt, and the right password refused while
locked. I also documented its limits: it does not stop spraying and it can be
abused to lock everyone out, which is why it sits next to detection rules, not
instead of them."

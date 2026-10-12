# A4 Prevent: Account lockout policy, before and after

> Needs dc01 (unit 7). Read it any time; stage it once dc01 is built. **Test only
> with the demo account.** Never test with the admin account you use to reach
> dc01, and know how to unlock an account before you start.

## The concept
An **account lockout policy** freezes an account after too many wrong passwords,
which turns unlimited guessing into a handful of guesses. It has three settings:
- **Threshold:** how many wrong passwords before the account locks.
- **Observation window:** how long Windows remembers the wrong passwords before
  the count resets.
- **Duration:** how long the account stays locked (or until an admin unlocks it).

In a domain you set this once, in the **Default Domain Policy** (a Group Policy
object), and it applies to every domain account.

Lockout is a trade-off. Too strict, and staff lock themselves out with typos, and
an attacker can lock out everyone on purpose. Too loose, or switched off, and a
guesser gets as many tries as they like. It also does nothing against an attacker
who tries each account only once. A change like this should be **measured
before and after**, so you can show it did what you claimed.

## Your mission
1. **Before:** record the domain's current threshold, window and duration.
2. **Before test:** make a few wrong-password attempts for the demo account (4 if
   lockout is off, otherwise fewer than the threshold you recorded). Record what
   Wazuh shows.
3. **Change:** set the policy to the lab target in
   [the security policy](../../../../../../docs/security-policy.md) (section 4),
   and replace its `TODO` values with what you set.
4. **After test:** repeat wrong passwords for the demo account until it locks. Find
   the lockout in the Windows log and in Wazuh, and show that even the correct
   password is refused while it is locked.
5. **Unlock** the account and confirm it works again.
6. Write one paragraph on what lockout does **not** protect against.

## The analyst workflow
1. Read the current policy on dc01 two ways and check they agree.
2. Generate the before test and check Wazuh for failures and for any lockout.
3. Change the policy in Group Policy, refresh it, and read it again to confirm.
4. Generate the after test. Count your attempts and compare with the threshold.
5. Find the lockout event and the Wazuh alert, then the refused correct password.
6. Unlock, sign in successfully, and put everything in a before/after table.

## Predict before you run
With the new policy on, an attacker who knows every username types wrong
passwords for each one on purpose. What happens to the company the next morning?

## What good looks like
A case file (`../../../../case-file-template.md`) with a before/after table
(settings, attempts, locked or not, events seen), the lockout event and alert,
the refused correct password, the unlock, and your paragraph on the limits.

## Hints
1. On dc01, `net accounts /domain` and `Get-ADDefaultDomainPasswordPolicy` both show the lockout settings.
2. In `gpmc.msc`, edit Default Domain Policy: Computer Configuration > Policies > Windows Settings > Security Settings > Account Policies.
3. Run `gpupdate /force` on dc01; the lockout is event 4740 (Wazuh 60115), and a locked logon shows `subStatus` 0xC0000234.
4. `Unlock-ADAccount -Identity demo.user`, then `Get-ADUser demo.user -Properties LockedOut` should say False.

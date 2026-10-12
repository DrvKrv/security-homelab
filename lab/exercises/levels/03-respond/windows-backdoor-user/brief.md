# Level 3 — Respond: remove the Windows backdoor account

> Remediation and verification happen **on win-srv** in PowerShell. The runner
> (`run.sh`) is just your guide; there's no auto-verify for Windows, so you'll
> verify with the PowerShell commands below.

## The concept
The Windows version of the response exercise. Same two halves — **remediate**,
then **verify with evidence** — but Windows gives you an extra, important idea:
**disable before you delete.**

In a real incident you often *disable* a suspicious account first (instant, and
reversible) so it can't be used while you investigate, and only delete once
you're sure. Deleting a Windows account also destroys its SID and profile, which
can erase evidence. So the mature order is: disable → confirm scope → remove from
privileged groups → delete.

## Your mission
A rogue account is in the local **Administrators** group on win-srv. Remediate
and verify:
1. **Disable** the account (stop it being usable immediately).
2. **Remove** it from Administrators (revoke privilege).
3. **Delete** the account.
4. **Verify** it's gone and no longer privileged, using PowerShell.

## The analyst workflow
1. List local admins and confirm the rogue account is there.
2. Disable it, remove it from Administrators, then delete it.
3. Verify: the account is absent, and the Administrators group no longer lists
   it. Each remediation step is itself logged (account disabled, removed from
   group, deleted) — note those events in Wazuh as proof.
4. Capture before/after in your case file.

> The lab's `Reset-Lab.ps1` performs the cleanup correctly. Do it by hand first
> to learn the commands; use the reset to recover or to reset between attempts.

## Predict before you run
Why might a security team *disable* a suspicious admin account for a while before
deleting it, instead of deleting immediately? (Think about evidence and about
being wrong.)

## What good looks like
A case file with: the admin list before, the exact remediation commands, the
verification output after (account absent, not in Administrators), and the Wazuh
events that recorded the removal.

## Hints
1. `Get-LocalGroupMember -Group Administrators` lists local admins — your before/after proof.
2. `Disable-LocalUser`, `Remove-LocalGroupMember`, then `Remove-LocalUser` are the three PowerShell verbs you need, in that order.
3. Verify the account is gone with `Get-LocalUser <name>` (it should error "user not found") and re-run the group listing.
4. The removal is audited: 4726 = account deleted, 4733 = removed from a local group, 4725 = account disabled. Confirm them in Wazuh as independent proof.

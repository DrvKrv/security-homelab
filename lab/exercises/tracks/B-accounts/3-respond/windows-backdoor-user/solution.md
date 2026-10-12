# Answer key: remove the Windows backdoor account

## The correct response, in order (PowerShell on win-srv, as admin)
Substitute the rogue account's name (from the B1 Windows detection, or from
`Get-LocalGroupMember -Group Administrators`):
1. **Disable:** `Disable-LocalUser -Name <acct>` — instantly unusable, reversible.
2. **Revoke privilege:** `Remove-LocalGroupMember -Group Administrators -Member <acct>`.
3. **Delete:** `Remove-LocalUser -Name <acct>`.
4. **Verify:**
   - `Get-LocalUser <acct>` → errors with "user not found".
   - `Get-LocalGroupMember -Group Administrators` → no longer lists it.

The lab's `Reset-Lab.ps1` performs this cleanup correctly.

## The events that prove it (Wazuh)
| Windows Event ID | Meaning |
|---|---|
| 4725 | A user account was disabled |
| 4733 | A member was **removed** from a security-enabled local group |
| 4726 | A user account was **deleted** |

Seeing these is your independent, audited confirmation — not just your own
command output.

## Why "disable before delete"
- **Reversibility:** if you're wrong about the account being malicious, disabling
  is undoable; deletion isn't.
- **Evidence:** a deleted Windows account takes its SID and profile with it. If
  you still need to prove what it did, disable-and-preserve first.
- **Containment speed:** disabling is instant and stops the account being used
  while you finish scoping.

## Why it matters / interview answer
"On Windows I followed disable → remove-from-Administrators → delete, then
verified the account was absent and no longer privileged, and confirmed the
removal through the Security log (4725/4733/4726). I lead with *disable* because
it contains the account immediately, is reversible if I'm wrong, and preserves
evidence I might still need." That reasoning — containment, reversibility,
evidence — is exactly what a hiring manager wants to hear.

# Answer key — a new Windows admin account

## What happened
On **win-srv**, `Simulate-AccountChanges.ps1` created a new local account and
added it to the **Administrators** group, with the usual supporting steps. Each
is a distinct Windows Security event:

| Windows Event ID | Meaning |
|---|---|
| 4720 | **A user account was created** |
| 4722 | A user account was enabled |
| 4724 | An attempt was made to reset an account's password |
| 4732 | **A member was added to a security-enabled *local* group** (Administrators) |
| 4728 / 4756 | Added to a security-enabled *global / universal* group (domain cases) |

- **New account:** the name created by the script (read `TargetUserName`).
- **Privilege:** member of **Administrators**.
- **Acting account (`SubjectUserName`):** the account that performed the change —
  in a real incident, your lead on what was already compromised.

The account remains after the exercise. Level 3 is where you remove it and prove
it's gone.

## Why it matters / interview answer
"On Windows, I reconstructed a privilege-escalation-via-new-account from the
Security log: 4720 created the user, 4722/4724 enabled it and set a password, and
4732 added it to the local Administrators group. I also captured the
SubjectUserName — the account that made the change — because that's the thread
you pull on to find the initial compromise." Shows you can read a Windows event
sequence as a narrative, and that you know to chase the acting account.

## Detect it faster next time
- Alert on **any** 4732/4728 where the target group is Administrators / Domain
  Admins — privileged group changes should be rare and reviewed.
- Correlate 4720 immediately followed by a privileged group add; that tight
  sequence is a strong signal of malicious account creation rather than normal
  IT provisioning.

# Level 3 — Respond: remove the Linux backdoor account

> Run the exercise runner **on linux-srv** for response exercises, so `verify`
> can check the box directly.

## The concept
Detecting and investigating come first; now you **respond**. Response has two
halves that beginners often skip the second of:
1. **Remediate** — undo the attacker's change (remove the account, revoke its
   access).
2. **Verify** — *prove* the system is actually clean, with evidence, not a
   feeling. "I deleted the user" is a claim; "the user no longer exists, is not
   in sudo, and its home directory is gone" is verification.

You'll also think about **order of operations**: revoke privilege before (or as
you) delete, kill any live sessions, and make sure you're not destroying evidence
you still need (you investigated in Level 2, so you're clear to act here).

## Your mission
A rogue admin account (`svc_backup`) exists on linux-srv. Remove it safely and
prove it's gone:
1. **Revoke** its admin rights.
2. **Terminate** any processes/sessions it owns.
3. **Delete** the account and its home directory.
4. **Verify** — confirm the account is gone, not in `sudo`, home removed. Then run
   `./run.sh verify 3/linux-backdoor-user` for an automated check.

## The analyst workflow
1. You already scoped this in Level 2, so you may act. (In a real incident, scope
   first.)
2. Remove from `sudo` first (revoke power), then kill its sessions, then delete
   the account with its home directory.
3. Confirm with read-only checks, then let the verifier confirm independently.
4. Capture the before/after in your case file — that contrast is the proof.

> The lab ships a cleanup command (shown by `./run.sh reset`) that does this
> correctly. Try it **by hand first** to learn the steps; use the reset if you
> get stuck or to reset between attempts.

## Predict before you run
If you delete the account but forget to remove it from `sudo` first, or forget
`-r` on the delete — what's left behind? (That leftover is exactly what the
verifier checks for.)

## What good looks like
A case file showing the account present (before), the remediation steps you ran,
and the verification output (after) proving it's gone — including a passing
`./run.sh verify`.

## Hints
1. Order matters: take away admin rights before deleting, so there's no window where a privileged session lingers.
2. A logged-in or running account can't always be deleted cleanly — terminate its processes first.
3. Deleting the user is not the same as deleting their home directory. Use the option that removes both, or the home dir lingers.
4. Verify with `getent passwd svc_backup` (should return nothing), `getent group sudo` (should not list it), and check `/home/svc_backup` is gone. Then run the automated verifier.

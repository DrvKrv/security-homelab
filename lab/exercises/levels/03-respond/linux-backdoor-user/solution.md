# Answer key — remove the Linux backdoor account

## The correct response, in order
Acting with sudo on linux-srv (the lab's cleanup command does exactly this):
1. **Revoke admin:** remove `svc_backup` from the `sudo` group.
2. **Terminate sessions:** kill any processes owned by the account so the delete
   is clean.
3. **Delete the account and home directory** together (the delete option that
   also removes the home dir).
4. **Verify** (read-only):
   - `getent passwd svc_backup` → returns nothing.
   - `getent group sudo` → does not list `svc_backup`.
   - `/home/svc_backup` → gone.
   - no processes owned by the account.

Wazuh records the deletion too (rule **5903**, "group/user deleted"), which is a
nice symmetry: the removal is itself an audited event.

## Common mistakes the verifier catches
- Deleting the user but leaving it in the `sudo` group's member list, or leaving
  the **home directory** behind (forgetting `-r`).
- Trying to delete while a session/process is still alive.

Each is a real-world footgun, which is why the verifier checks all four
conditions, not just "does the user exist".

## Why it matters / interview answer
"Remediation isn't done when you run the delete command; it's done when you've
*verified* the system is clean. I revoked the account's sudo rights, killed its
sessions, removed the account and its home directory, and then proved removal
with independent read-only checks — the account's absence from passwd, its
absence from the sudo group, and the missing home directory. The deletion was
also captured by the SIEM (rule 5903)." That 'remediate **and** verify, with
evidence' habit is exactly what separates finished work from hopeful work.

## Reset
`./run.sh reset 3/linux-backdoor-user` shows the cleanup command, and
`... start ...` re-stages the account if you want another attempt.

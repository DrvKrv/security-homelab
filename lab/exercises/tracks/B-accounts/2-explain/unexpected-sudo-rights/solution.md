# Answer key: Unexpected sudo rights: who granted them, when

## What happened
Staging gave the lab test account (`labuser`, from `setup-linux-srv.sh`) sudo
rights by installing a one-line file in `/etc/sudoers.d/`, after checking it with
`visudo`. It did **not** touch the `sudo` group. The file name, the command
allowed and whether a password is required are random each run; they're under
*This run's details* at the end of `reveal`.

The account that made the change is **your own admin account**, because you ran
the staging with sudo. That's the honest answer for this lab. In a real incident,
the same evidence would point at whichever account was used, and that account
would become your next question: was it really that person?

## The evidence
- **On linux-srv:** `sudo -l -U labuser` shows the granted line. `ls -l
  /etc/sudoers.d/` shows a new file next to the normal ones: `90-cloud-init-users` (which gives
  your Azure admin account its sudo rights) and Ubuntu's `README`.
- **Wazuh, file integrity:** a syscheck alert for a file **added** under
  `/etc/sudoers.d/` (rule 554), with the line shown in the diff because the lab
  agent config sets `report_changes` on that folder. Its timestamp is "when".
- **Wazuh, sudo log:** rule 5402 ("Successful sudo to ROOT executed"), or
  5403 ("First time user executed sudo") if it's that account's first sudo, with
  `data.srcuser` = your admin account and `data.command` showing `install ...
  /etc/sudoers.d/<file>`, plus a `visudo -cf` just before it.
- **Wazuh, login:** an sshd authentication success (5715) for your admin account
  on linux-srv shortly before, with the source address of win-srv (10.0.1.20).

## Answers to the mission
1. `labuser`; the command in this run's `grant` (either `ALL` or one program).
   With `NOPASSWD:` it needs no password; without it, sudo asks for labuser's own
   password (which nobody knows, as it's random), but the right is still granted
   and still dangerous once that password is set.
2. A file in `/etc/sudoers.d/`, the line in this run's `grant`.
3. Your admin account, via sudo, in an SSH session from win-srv; the time from the
   sudo (5402/5403) and syscheck alerts.
4. The lab's loud sudo alert, rule 100110 (level 10), is chained to the
   built-in "user added to group" event (2961). No group changed, so it had
   nothing to fire on. File integrity monitoring on
   `/etc/sudoers.d` recorded it, at a much lower level. This is a **detection
   gap**: the same privilege, a different path, a quieter alert.
5. Confirm first if you can (a change ticket, the person who owns the account),
   because removing a legitimate right breaks someone's work. But a right granted
   to a test account with no ticket and a vague file name should be removed the
   same day (`sudo rm /etc/sudoers.d/<file>`, then `sudo visudo -c`), or with
   `./run.sh reset B2/unexpected-sudo-rights`.

## MITRE ATT&CK
T1548.003 Abuse Elevation Control Mechanism: Sudo and Sudo Caching. Editing
sudoers to give an account root is the textbook case.

**Predict:** most people expect the level-10 sudo-group alert. Here the only
evidence is a file-integrity alert and a routine sudo log line, both low level,
easy to miss on a busy day. Lesson B4 (round 2) is where you'd write a rule for it.

## Common mistakes
- Checking only the `sudo` group (`getent group sudo`) and concluding nothing changed.
- Reading `/etc/sudoers` but not the files in `/etc/sudoers.d/`.
- Stopping at "a file appeared" without finding the command and session behind it.
- Treating "only one command" as harmless.

## Interview talking point
"I investigated an account that had gained sudo rights without being added to the
sudo group, so our group-change alert never fired. I found the grant in a sudoers
drop-in file through file integrity monitoring, then used sudo's own logs to tie
the change to a specific admin session and time. It showed me a detection gap: we
alerted on one way of granting admin rights but not the other."

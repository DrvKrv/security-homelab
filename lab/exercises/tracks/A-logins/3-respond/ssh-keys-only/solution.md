# Answer key: Switch SSH to keys only and prove passwords stop working

## What happened
Staging added a small file to `/etc/ssh/sshd_config.d/` containing
`PasswordAuthentication yes`, with a vague comment, and restarted sshd. Its name
sorts before the image's own file that says `no` (`50-cloud-init.conf` or
`60-cloudimg-settings.conf`, depending on the image), and sshd keeps the first
value it reads, so passwords were switched back on. The file's
name is random each run; it's under *This run's details* at the end of `reveal`.

## The evidence
- **Wazuh, file integrity:** a syscheck alert on linux-srv for a file **added**
  in `/etc/ssh/sshd_config.d/` (rule 554, "File added to the system"), with the
  file's contents shown because the lab agent config turns on `report_changes`
  for that folder. Its timestamp is the "when". Note the rule id from your alert.
- **Before the fix:** `sudo sshd -T | grep -i passwordauthentication` prints
  `passwordauthentication yes`. From wazuh, the methods test prints
  `Permission denied (publickey,password)`.
- **After the fix:** `passwordauthentication no`, and the methods test prints
  `Permission denied (publickey)`. Removing the file also raises a file-deleted
  alert (553), which is good evidence that you made the change and when.

## The fix
```bash
ls -l /etc/ssh/sshd_config.d/
grep -ri passwordauthentication /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
sudo rm /etc/ssh/sshd_config.d/<the staged file>
sudo sshd -t && sudo systemctl restart ssh
sudo sshd -T | grep -iE 'passwordauthentication|kbdinteractiveauthentication'
```

Both lines should end in `no`. Keyboard-interactive is a second way of asking
for a password, so it must be off too (Ubuntu ships it off).

Changing the line in the staged file to `no` also works, but deleting a file
nobody can explain is cleaner. Editing `/etc/ssh/sshd_config` itself is the
weakest fix: a file in `sshd_config.d` is read first, so it would still win.

If `lab/linux/setup-linux-srv.sh` was ever run, its own
`10-lab-password-auth.conf` turns passwords on too. Runbook 05 removes it; so
should you.

## Answers to the mission
1. Effective setting `yes`, and `password` in the offered methods.
2. What: `PasswordAuthentication yes`. Where: the staged file. When: the file
   integrity alert's timestamp.
3. Delete the file and restart sshd. It holds after a reboot because it's the
   on-disk configuration, not a running change.
4. Methods test shows only `publickey`; a new session with your key works.
5. Verify passes.

## MITRE ATT&CK
T1110 Brute Force. Turning off passwords removes the thing being brute-forced.

## Common mistakes
- Reading `/etc/ssh/sshd_config` only and concluding passwords are off.
- Restarting sshd without `sshd -t` first: a typo can stop sshd from starting.
- Closing your only session before testing a new key login.
- Proving it from linux-srv itself instead of from another machine.

## Interview talking point
"I hardened SSH on a Linux server by turning off password authentication. A file
integrity alert told me a drop-in config file had turned passwords back on, so I
checked sshd's effective configuration rather than trusting one file, removed the
cause, validated the config before restarting, and proved from another host that
the server now only offers public-key login."

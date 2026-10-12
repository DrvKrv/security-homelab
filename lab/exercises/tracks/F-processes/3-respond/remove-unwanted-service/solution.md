# Answer key: Stop and remove an unwanted service

## What happened
An unwanted systemd service was installed and started on linux-srv. The stand-in
is harmless: its `ExecStart` is a shell loop that just sleeps. It is set to start
at boot and to restart if killed, so it behaves like real persistence, which is
the point. The lesson is removing it at every layer and proving it.

## The correct response, in order
Acting with sudo on linux-srv. Use this run's service name (see *This run's
details*) in place of `<name>`.

1. **Identify (before):**
   ```
   systemctl status <name>
   cat /etc/systemd/system/<name>.service
   ```
   Note the ExecStart line and that the unit is enabled.
2. **Stop and disable:**
   ```
   sudo systemctl disable --now <name>
   ```
   `--now` stops the running process; `disable` removes the boot-time start.
3. **Remove the definition:**
   ```
   sudo rm /etc/systemd/system/<name>.service
   sudo systemctl daemon-reload
   ```
4. **Verify (after):**
   ```
   systemctl status <name>     # -> "Unit <name>.service could not be found."
   pgrep -af sleep             # -> the service's sleep loop is gone
   ```

## How to prove the fix
`systemctl status` reports the unit cannot be found, the service no longer appears
in `systemctl list-units`, and no matching `ExecStart` process is running. Because
you disabled it before removing the file, it will not come back on reboot, and
because you stopped it, `Restart=always` has nothing to restart.

## MITRE ATT&CK
**T1543.002 Create or Modify System Process: Systemd Service.** An enabled
systemd service is a durable persistence mechanism: it restarts on reboot and can
auto-restart if killed. The full remediation (stop, disable, remove the unit
file) is what actually closes it, which is why killing the process alone is not
enough.

## Common mistakes
- Only running `kill`. `Restart=always` brings it straight back, and the enabled
  unit brings it back on reboot.
- Deleting the unit file but forgetting `daemon-reload`, so systemd still
  remembers the unit.
- Not verifying. Re-check status and the process list, do not assume.

## Interview talking point
"A malicious systemd service has three layers of staying power: the running
process, the restart policy, and the enable-at-boot flag. I stopped and disabled
the unit in one step, removed the unit file, reloaded systemd, and then proved it
with a status check that reported the unit could not be found and no matching
process running, ATT&CK T1543.002. Killing the process alone would have let it
come straight back."

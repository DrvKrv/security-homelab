# Answer key: Close a port that shouldn't be open and verify

## What happened
Staging started Python's built-in web server, showing an empty folder
(`/srv/lab-share`), as the unprivileged `nobody` account under a **transient**
systemd unit with a harmless-sounding name, and opened its port to everyone with
`ufw allow <port>/tcp`. The port and the unit name are random; they're under
*This run's details* at the end of `reveal`.

## The evidence
- **Inside view:** `sudo ss -tlnp` shows `0.0.0.0:<port>` owned by `python3`.
  Everything else is expected: sshd on 22, and the system's local-only ports
  (the DNS stub on 127.0.0.53, for example).
- **Outside view:** from wazuh, `nc -z -w 3 10.0.1.30 <port> && echo open`
  prints `open`. The authorized scan from C1 would list it too.
- **The program:** `systemctl status <pid>` shows a unit loaded from
  `/run/systemd/transient/`. That means it was started by hand with
  `systemd-run`, not installed, so it would **not** come back after a reboot.
  The firewall rule, however, is saved and **would** survive a reboot.
- **When:** a file-integrity alert on linux-srv for `/etc/ufw/user.rules` (rule
  550, checksum changed) with a diff showing the new allow line. It sits right
  next to the staging time.

## The fix
```bash
sudo ss -tlnp                                  # find the port and PID
systemctl status <pid>                         # find the unit
sudo systemctl stop <unit>                     # half 1: nothing listening
sudo ufw delete allow <port>/tcp               # half 2: firewall closed
sudo rm -rf /srv/lab-share                     # tidy up what it served
sudo ss -tlnp ; sudo ufw status                # check both halves
```
Then from wazuh: `nc -z -w 3 10.0.1.30 <port> || echo closed`.

A transient unit disappears when stopped, so there's nothing to disable. For an
installed service you'd also run `sudo systemctl disable <unit>`, or it would
start again at the next boot.

## Answers to the mission
1. The staged port, seen in `ss -tlnp` and from another VM.
2. `python3 -m http.server`, as `nobody`, started as a transient systemd unit, so
   not persistent across a reboot (its firewall rule is).
3. The time of the file-integrity alert on `/etc/ufw/user.rules`.
4. Stop the unit and delete the UFW rule.
5. The outside test now fails, and verify passes.

**Predict answers:** program stopped but rule kept: the test fails right now (no
one answers), but the door is still open for whatever listens there next. Rule
removed but program running: the outside test fails because UFW drops it, but
the program still runs and anything already allowed (or a later firewall change)
exposes it again.

## MITRE ATT&CK
T1190 Exploit Public-Facing Application is what an exposed, forgotten web
service invites. (A web server showing an empty folder can't be used to get in
by itself, but a forgotten one rarely stays empty or patched.) Closing it is the
mitigation; there was no attack here.

## Common mistakes
- Closing only one half (process or firewall).
- Checking only from inside linux-srv. The attacker's view is from the outside.
- Killing the process by PID and not checking what started it, so it comes back.
- Removing the rule with the wrong syntax, then not checking `ufw status` again.

## Interview talking point
"I found an unexpected listening service on a server by comparing what the host
said was listening with what another machine could reach. I traced the process to
a hand-started systemd unit and used file integrity monitoring on the firewall's
rule file to find when the port was opened. I closed both halves, the service and
the firewall rule, and proved from another host that the port was no longer
reachable."

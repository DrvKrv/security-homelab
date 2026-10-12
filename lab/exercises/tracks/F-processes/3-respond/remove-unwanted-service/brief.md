# F3 Respond: Stop and remove an unwanted service

> Needs the detection add-ons from unit 4 (Sysmon on win-srv / process auditing on linux-srv). Read it any time; do it once they're installed.

## The concept
On Linux, **systemd** manages long-running background programs called
**services** (also called units). A service is defined by a small unit file that
says what to run (`ExecStart`) and whether to start it at boot. Services are the
normal way software runs quietly in the background, which is also why they are a
favourite place for an attacker to hide **persistence**: a service that is
**enabled** starts again on every reboot, and one set to restart comes straight
back if you just kill its process.

That last point is the trap for a beginner. If you only `kill` the process, two
things bring it back: `Restart=always` restarts it immediately, and even a reboot
restarts it because the service is enabled. To remove it for good you have to
undo all three layers:
1. **stop** the running process,
2. **disable** it so it does not start at boot,
3. **remove** the unit file so the definition is gone,

and then prove, with a fresh status check, that nothing is left.

## Your mission
An unwanted service is running on **linux-srv**. Remove it properly and prove it:
1. **Identify** the service: its name, its unit file, and what its `ExecStart`
   runs.
2. **Stop and disable** it so it is neither running now nor set to start at boot.
3. **Remove** the unit file and reload systemd.
4. **Verify**: show the service is unknown to systemd and its process is gone.

## The analyst workflow
1. Stage the lesson, then find the service. Process monitoring shows its
   `ExecStart` process running; `systemctl` shows the unit itself.
2. Read the unit file so you know exactly what you are removing (name, ExecStart,
   whether it is enabled).
3. Stop and disable in one step, then delete the unit file, then
   `daemon-reload`.
4. Check status again. "Unit could not be found" plus no matching process is your
   proof. Capture before and after.

## Predict before you run
Before you act: if you only run `kill` on the service's process, what are the two
separate reasons it could come back? Which step stops each one?

## What good looks like
Your case file names the service and its unit file, shows what `ExecStart` ran,
lists the stop/disable/remove steps you used, and ends with a status check proving
the service is gone and not coming back. This run's service name is under *This
run's details* in `reveal`.

## Hints
1. List services and find the odd one with `systemctl list-units --type=service` and `systemctl status <name>`; read its unit file under `/etc/systemd/system/`.
2. Stop and disable together: `sudo systemctl disable --now <name>` (disable removes the boot start, --now also stops it).
3. Then delete the definition: `sudo rm /etc/systemd/system/<name>.service` and `sudo systemctl daemon-reload`.
4. Prove it: `systemctl status <name>` should say the unit could not be found, and `pgrep -af sleep` (or ps) should show its process is gone.

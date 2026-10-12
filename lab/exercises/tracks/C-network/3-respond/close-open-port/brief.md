# C3 Respond: Close a port that shouldn't be open and verify

> Runs on the current lab. Staging, the fix and `./run.sh verify` run on
> linux-srv. For the proof you also test from another lab VM.

## The concept
Every **open port** is a door: a program listening for connections, plus a
firewall that lets them reach it. Each door is something an attacker can knock
on, so the fewer there are, the smaller the **attack surface**. A common real
finding is a service someone started "just for a minute" (a file share, a test
web page, a debug tool) and then forgot, with a firewall rule left open for it.

A port is only truly closed when **both** halves are dealt with:
1. **Nothing is listening.** Stop the program, and make sure it won't start again.
2. **The firewall doesn't allow it.** Remove the rule that opened it, so a
   program that starts listening there later still can't be reached.

Doing only one half leaves a trap for later. And as always, you **prove** it from
the outside, the way an attacker would see it, not just from inside the machine.

## Your mission
1. Stage, then find the new open port on linux-srv. Use **two** views: what the
   machine itself says is listening, and what another lab machine can reach.
2. Identify the program behind it: what it is, which account runs it, how it was
   started, and whether it would come back after a reboot.
3. Find when the firewall was opened for it, using Wazuh.
4. Close it properly: both halves.
5. Prove it's closed from another lab VM, and run
   `./run.sh verify C3/close-open-port` on linux-srv.

## The analyst workflow
1. On linux-srv, list listening TCP ports **with the program** that owns each.
   Compare with what you expect linux-srv to run.
2. From another lab VM, test the suspect port (a quick connection check, or the
   lab's authorized scan script from C1).
3. Follow the program back to what started it: its process, its service unit,
   and the folder it serves.
4. Read linux-srv's firewall rules. In Wazuh, find the file-integrity event for
   the firewall's rule file to see when the rule appeared.
5. Stop the service, remove the rule, then repeat steps 1 and 2.

## Predict before you run
If you stop the program but leave the firewall rule, what will a connection test
from another VM report? What if you remove the rule but leave the program running?

## What good looks like
A case file (`../../../../case-file-template.md`) with: the "listening" output
before and after, the outside test before and after, what the program was and how
it was started, when the firewall rule appeared (with the Wazuh evidence), the
exact commands you used, and a passing verify.

## Hints
1. `sudo ss -tlnp` lists listening TCP ports with the program; anything other than SSH (22) and local-only 127.0.0.x ports needs a reason.
2. `systemctl status <pid>` names the unit that owns a process; `ps -o user,cmd -p <pid>` shows the account and command.
3. In Wazuh, search linux-srv for `rule.groups: syscheck` with a `syscheck.path` under `/etc/ufw`; the diff shows the rule added.
4. `sudo systemctl stop <unit>`, then `sudo ufw delete allow <port>/tcp`. From wazuh, `nc -z -w 3 10.0.1.30 <port>` should then fail.

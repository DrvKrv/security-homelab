# A3 Respond: Switch SSH to keys only and prove passwords stop working

> Runs on the current lab. Staging, the fix and `./run.sh verify` all run on
> linux-srv. Keep your current SSH session open until you've proved you can
> still get in with your key.

## The concept
Blocking an attacker's address (the other lesson in this box) stops one source.
It doesn't stop the next one. The lasting fix for password guessing is to make
guessing **pointless**: if the server never accepts a password, there's nothing
to guess.

SSH can prove who you are in two common ways. A **password** is a secret you
type, and anyone can try typing it. A **key** is a pair of files: the private
key stays on your machine and the public key sits on the server. Without the
private key file, no amount of guessing gets in. Turning passwords off is one of
the most effective hardening steps on any Linux server.

On Ubuntu, SSH's settings live in `/etc/ssh/sshd_config` **and** in small extra
files in `/etc/ssh/sshd_config.d/`. Those files are read in name order, and for
most settings sshd keeps the **first** value it sees. So the setting you see in
one file is not always the one in effect. The reliable question is "what is sshd
actually using?", and sshd can tell you.

A change to a security setting is also an event worth noticing. This lab watches
the SSH configuration files, so changes to them show up in Wazuh.

## Your mission
1. Stage the incident. Then confirm that linux-srv now offers password logins,
   both from sshd's own view and from another machine.
2. Find **what** changed, **where**, and **when**, using Wazuh and the files.
3. Turn password logins off in a way that will still hold after a reboot or the
   next package update.
4. Prove it from another lab machine: the server no longer offers passwords.
   Prove you can still get in with your key.
5. Run `./run.sh verify A3/ssh-keys-only` on linux-srv.

## The analyst workflow
1. Ask sshd for its **effective** settings rather than reading one file.
2. From another lab VM, ask the server which login methods it offers, without
   sending any password.
3. In Wazuh, look at linux-srv's file-integrity events around the staging time.
   Read the file name and the change shown with it.
4. Fix the cause, not just the symptom: check every file in the settings folder.
5. Test the configuration before restarting sshd, then restart it.
6. Repeat steps 1 and 2. Open a **new** SSH session with your key before you
   close the old one.

## Predict before you run
If one settings file says passwords **on** and another says passwords **off**,
which one wins, and how would you check without guessing?

## What good looks like
A case file (`../../../../case-file-template.md`) with: the file-integrity alert
and the change it shows, the effective setting before and after, the "which
methods are offered" test from another VM before and after, the exact change you
made, a new key-based session working, and a passing verify.

## Hints
1. `sudo sshd -T | grep -i passwordauthentication` prints the setting sshd is really using.
2. From wazuh: `ssh -o PreferredAuthentications=none -o BatchMode=yes test@10.0.1.30` lists the methods offered; look for `password`.
3. In Wazuh, search linux-srv for `rule.groups: syscheck` around the staging time; the file path and diff show what was added.
4. Remove (or correct) the file in `/etc/ssh/sshd_config.d/` that turns passwords on, then `sudo sshd -t && sudo systemctl restart ssh`.

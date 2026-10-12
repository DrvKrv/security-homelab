# Level 1 — Detect: a new Linux admin account

## The concept
Once an attacker has a foothold, a common early move is to create a **new user
account** and give it **administrator (sudo) rights**. It's a form of
**persistence**: even if the original way in is closed, the attacker still has a
valid login. A name like `svc_backup` is chosen to blend in with legitimate
service accounts.

On Linux, three things get logged when this happens: the user creation, the
addition to the `sudo` group, and a password being set. On top of that, your
lab's Wazuh agent watches `/etc/passwd`, `/etc/group` and `/etc/shadow` with
**file-integrity monitoring (FIM)**, so you get a second, independent signal
that those sensitive files changed.

## Your mission
An account was just created on **linux-srv**. From Wazuh alone, determine:
1. **What account** was created, and **when**.
2. That it was **granted sudo** (admin) rights.
3. That its **password was set**.
4. Which **files changed** (the FIM angle).

## The analyst workflow
1. **Threat Hunting > Events**, last 15 minutes, filtered to linux-srv.
2. Look for the account-management rule group first (user added, group changed).
3. Then look at the `syscheck` (FIM) alerts. Notice you're seeing the *same*
   real-world event from two directions: the OS audit log **and** the file
   change. Corroborating evidence like this is what makes a finding solid.
4. Open the "added to sudo" alert and note its **level** — your lab raises it
   on purpose, because gaining admin is more serious than an ordinary group edit.

## Predict before you run
Which do you think fires first — the "new user" alert or the file-integrity
alert on `/etc/passwd`? Why might they arrive a few seconds apart?

## What good looks like
A case file (`../../case-file-template.md`) naming the account, the sequence of
the three changes with timestamps, the rule IDs, and the FIM alerts that
corroborate them. Note that the account is still present — removing it is Level 3.

## Hints
1. The account-management events are a small family of rules. Search the `adduser`/`account_changed` groups, or start from the Wazuh search this exercise gave you.
2. The account name is a plausible-looking service account, not an obvious "hacker" name. Read the `data` of the "new user" event for the exact username.
3. The jump to admin is a *separate* event from the user creation — look for a group-membership change adding the new user to `sudo`.
4. The FIM alerts have rule group `syscheck` and name the exact file path that changed. Three sensitive files are watched; see which ones moved.

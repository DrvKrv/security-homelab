# Level 2 — Investigate: triage the backdoor account

## The concept
In Level 1 you *spotted* a new admin account. Investigation goes further: before
you remove anything, you **scope** it. What exactly was changed? When? By whom?
Is this the only change, or part of a larger foothold? Removing evidence before
you understand it is a classic rookie mistake — you lose the ability to answer
"how did they get in?" and "what else did they do?".

This exercise is about discipline: **investigate first, respond second** (Level 3
is the response).

## Your mission
A rogue account exists on **linux-srv**. Without deleting it yet, determine:
1. The **full sequence** of changes (create → privilege → password), with times.
2. The account's **current state** — groups, home directory, whether it has a
   usable password or keys.
3. **Corroboration**: which independent signals (OS audit vs. file-integrity)
   agree on what happened.
4. **Scope**: is there any sign of *other* changes around the same time?

## The analyst workflow
1. Build the timeline from Wazuh (the account-management and FIM alerts).
2. Then go **on-box** (read-only) on linux-srv to confirm the live state:
   inspect the account's group membership and home directory, and check for
   attacker persistence like extra SSH keys. Observe; don't change.
3. Cross-check the OS audit events against the FIM events — do they tell the same
   story? Note where they agree.
4. Widen the lens: look a few minutes either side of the account creation for
   anything else unusual. Concluding "scope appears limited to this one account"
   is a valid, valuable finding when it's backed by having actually looked.

## Predict before you run
Which on-box file would confirm the account's sudo rights, and which would show
whether someone planted an SSH key for it? Name them before you look.

## What good looks like
A case file with the change sequence, the confirmed live state of the account,
the two corroborating evidence sources, and an explicit scope statement. Leave
the account in place — Level 3 removes it and proves it's gone.

## Hints
1. Read, don't write. `getent passwd <user>`, `id <user>`, `getent group sudo`, and `ls -la /home/<user>/.ssh/` are all read-only ways to confirm state.
2. The exact account name is in the Level 1 alerts (and in `/etc/passwd`). It's a service-account-style name.
3. "Corroboration" means the 5902/2961 audit events and the 550/554 FIM events point at the same change. Line them up.
4. For scope, search the whole agent's events for that 10-minute window, not just account rules. You're looking for anything that *doesn't* fit the backup story.

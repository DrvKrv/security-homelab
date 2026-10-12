# A1 Spot: Windows failed logons

## The concept
This is the Windows counterpart to the SSH brute-force exercise, and comparing
the two teaches you that **the tactic is the same across operating systems; only
the log format differs.** Windows records security activity in the **Windows
Event Log**, where each kind of event has its own numeric **Event ID**. Enough
failures in a row can also trip the account's **lockout** policy, which is its
own event. Part of this exercise is learning which IDs these are.

For any of this to reach Wazuh, Windows auditing has to be turned on first
(that's what `Enable-AuditPolicy.ps1` does in the prep runbook). No audit policy,
no events, no alerts — a point worth remembering: *a SIEM only sees what the OS
is told to log.*

## Your mission
win-srv just saw a run of failed sign-ins. From Wazuh, determine:
1. **Which account** was targeted.
2. **How many** failures, and whether the account **locked out**.
3. The **logon type** and failure **reason** (what Windows says went wrong).

## The analyst workflow
1. **Threat Hunting > Events**, last 15 minutes, filtered to the win-srv agent.
2. Find the failed sign-in events. Windows packs a lot into each one, so expand
   the `data.win.eventdata` fields.
3. Read **`TargetUserName`** (the account), **`LogonType`** (how they were trying
   to log in), and the **failure reason / status code**.
4. Check whether the account was **locked out**. If it was, the policy did its
   job; note how many failures came before it.

## Predict before you run
Windows won't log failed sign-ins at all unless logon auditing is enabled. If you saw
*nothing*, what would you check first — Wazuh, or the win-srv audit policy?

## What good looks like
A case file naming the targeted account, the count of failures, whether a lockout
fired, the logon type, and the failure reason. Compare it in your notes to
the SSH exercise: same attack, different log.

## Hints
1. Filter on Windows Event ID 4625. Each one is a single failed sign-in.
2. `TargetUserName` in the event data is the account being tried. It's a plausible-looking username, not an obvious attacker name.
3. `LogonType` tells you *how* they tried (e.g. 2 = interactive/console, 3 = network, 10 = remote desktop). The failure `Status`/`SubStatus` code says why it failed.
4. A burst of 4625s for one account is often followed by a 4740 **account lockout**. Search for it in the same window.

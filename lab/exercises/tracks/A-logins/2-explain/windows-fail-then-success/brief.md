# A2 Explain: Windows failed logons, then one success?

> Runs on the current lab. Staging runs on win-srv (`./run.sh stage` prints the
> PowerShell line). It takes a few minutes and pauses at random points. The
> first time you stage it, it also sets up a lab account it needs, so you'll see
> some account events that are part of the setup. Repeat runs don't.

## The concept
In A1 you spotted failed Windows logons. The question that matters to the
business comes next: **after all those failures, did anyone get in?**

A run of failures followed by **one success** for the same account is one of the
most important patterns in log analysis. It can mean someone finally guessed the
password. It can also mean a real person mistyped a few times and then got it
right. Telling those apart is the skill: you look at which account, how many
tries, which other names were tried, how the logon happened, from where, and how
quickly after the failures.

Windows describes every logon with a **logon type**: a number that says *how*
the logon happened, for example at the keyboard, over the network (file shares
and most remote tools), or by Remote Desktop. Comparing the logon type of the
success with that of the failures, and with your own Remote Desktop session, is
how you keep your own activity out of the story.

Proving a **negative** counts too. "There were failures and no success" is a
complete answer, if you can show you looked in the right place.

## Your mission
1. When did the failures start and stop? Which account names were tried, and how
   many times each?
2. Which of those names are real accounts on win-srv, and which don't exist? How
   can you tell from the events alone?
3. Was there a **successful** logon for any of the tried accounts after the
   failures? If yes: when, how long after the last failure, and which logon type.
4. Separate your **own** logons in the same window from the ones in the story.
5. Your verdict: guessed password, legitimate user, or no success at all? What
   would you do next in each case?

## The analyst workflow
1. In Wazuh, pull **all** logon events for win-srv in the window, failures and
   successes together, so a success can't hide.
2. For each failure, read the account name and the failure reason code.
3. Sort by time. Mark the first and last failure: that's the attack window.
4. Inside and just after the window, look for a success for any account that was
   tried. Read its logon type, workstation and source address.
5. Find your own logons in the same window and set them aside, with a reason.
6. Write the timeline and the verdict.

## Predict before you run
If an attacker guessed the password on the fourth try, what would the timeline
look like? And what would a person who mistyped their own password look like?
Write both down before you look.

## What good looks like
A case file (`../../../../case-file-template.md`) with: a timeline table (every
failure and success, with time, account, reason and logon type), the real versus
made-up names, your own logons set aside with the evidence, and a verdict with
the next steps for each outcome.

## Hints
1. Search win-srv for `data.win.system.eventID: (4624 or 4625)` over the window; add `data.win.eventdata.targetUserName` as a column.
2. On a 4625, `data.win.eventdata.subStatus` 0xc000006a means a real account with a wrong password; 0xc0000064 means no such account.
3. On a 4624, `data.win.eventdata.logonType` 3 is a network logon and 10 is Remote Desktop; your RDP session comes from your own address.
4. On win-srv, `.\Get-LabEvidence.ps1 -Minutes 60 -Id 4624,4625` (from `lab\windows`) shows the same events straight from Windows, to cross-check.

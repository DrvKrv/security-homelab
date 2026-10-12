# Answer key: Remove an unwanted scheduled task and prove it's gone

## What happened
An unwanted scheduled task was on win-srv (the benign stand-in you set up writes
the date into `C:\ProgramData\lab\`). The lesson is the response: remove the task
so it can never fire again, clean up what it left, and verify with a fresh query.

## The correct response, in order
Run in an Administrator PowerShell on win-srv. Use your task's real name in place
of `<name>`.

1. **Confirm and record (before):**
   ```
   schtasks /Query /TN "<name>" /V /FO LIST
   ```
   Note the task name and its action (the program and arguments it runs).
2. **Remove the task:**
   ```
   schtasks /Delete /TN "<name>" /F
   ```
   or, in PowerShell:
   ```
   Unregister-ScheduledTask -TaskName "<name>" -Confirm:$false
   ```
3. **Check for leftovers:** the delete removes the task registration, not the
   files. Look at the folder the action used:
   ```
   Get-ChildItem C:\ProgramData\lab\
   ```
   Remove any file the task created that you do not want to keep.
4. **Verify (after):**
   ```
   schtasks /Query /TN "<name>"
   ```
   This should now return "ERROR: The system cannot find the task specified",
   which is your proof. Save the before and after queries.

## How to prove the fix
The task no longer appears in `schtasks /Query` or `Get-ScheduledTask`, and the
folder it wrote to has been cleaned. The removal is also recorded in Windows as a
scheduled-task deletion event, so the SIEM shows your cleanup too (a nice
symmetry with the 4698 creation event from the explain lesson).

## MITRE ATT&CK
**T1053.005 Scheduled Task/Job: Scheduled Task.** This is the persistence
technique you are undoing. Removing the task closes the persistence, and checking
for the program it ran makes sure you did not leave the payload behind just
because the schedule is gone.

## Common mistakes
- Deleting the task but leaving the program it ran on disk. The schedule is gone,
  the file is not. Clean both.
- Trusting the delete without re-querying. Always verify with a fresh query.
- Not recording the before state, so you cannot show what you removed.

## Interview talking point
"Removing persistence is not done when the delete command returns; it is done
when I have proved it. I recorded the rogue scheduled task and its action,
deleted it with the standard admin tool, checked the folder its action used for
leftover files, and then re-queried to show the task no longer exists, ATT&CK
T1053.005. The deletion is audited too, so my own cleanup is in the logs."

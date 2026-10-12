# F3 Respond: Remove an unwanted scheduled task and prove it's gone

> Needs the detection add-ons from unit 4 (Sysmon on win-srv / process auditing on linux-srv). Read it any time; do it once they're installed.

## The concept
You found and explained a rogue scheduled task in the earlier F lessons. Now you
**respond**: remove it, and then **prove** it is really gone. Response always has
those two halves, and beginners skip the second one. "I deleted the task" is a
claim. "The task no longer appears in the task list, and nothing is scheduled to
run that program any more" is proof.

Removing a scheduled task is more than deleting one line. Think about what the
task leaves behind:
- the **task registration** itself (what `schtasks` or Task Scheduler shows),
- the **program or script** the task was set to run, which may still sit on disk,
- any **output or files** the task already created.

A clean response removes the task so it can never fire again, checks whether the
program it ran is something you also need to clean up, and then verifies with a
fresh query rather than trusting that the delete "probably worked". Removing the
task is itself an audited event, so your own cleanup shows up in the logs too.

## Your mission
An unwanted scheduled task exists on **win-srv**. Remove it safely and prove it:
1. **Confirm** the task is there and note its exact name and what it runs.
2. **Remove** the task so it cannot run again.
3. **Check for leftovers**: the program it ran, and anything it already wrote.
4. **Verify**: query for the task again and show it is gone. Capture before and
   after.

## The analyst workflow
1. Set up the stand-in (see the staging note), then confirm the task from Wazuh
   and on-box, and record its name and action before you touch anything.
2. Delete the task with the standard admin tool (`schtasks /Delete` or
   `Unregister-ScheduledTask`).
3. Decide if the action pointed at a file you should also remove, and check the
   folder it wrote to.
4. Re-query for the task. A query that returns nothing is your proof. Save the
   before query and the after query side by side.

## Predict before you run
Before you act: if you delete the task but leave the program it ran sitting on
disk, is the machine clean? What could still go wrong, and what does that tell you
about where to look besides the task list?

## What good looks like
Your case file shows the task present (before), the exact removal command you ran,
your check for leftovers, and a final query proving the task is gone (after). The
before/after contrast is the proof.

## Hints
1. Record the task name and its action before deleting: `schtasks /Query /TN <name> /V /FO LIST` or `Get-ScheduledTask -TaskName <name> | Get-ScheduledTaskInfo`.
2. Remove it with `schtasks /Delete /TN <name> /F`, or `Unregister-ScheduledTask -TaskName <name> -Confirm:$false`.
3. Deleting the task does not delete what it ran: check the folder its action pointed at (here, under `C:\ProgramData\lab\`) and remove leftovers if they are not wanted.
4. Prove it: run the same query again and show it now returns "the system cannot find the task", and note that the removal itself is logged.

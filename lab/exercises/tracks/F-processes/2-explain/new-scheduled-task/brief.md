# F2 Explain: Find a scheduled task that appeared

> Needs the detection add-ons from unit 4 (Sysmon on win-srv / process auditing on linux-srv). Read it any time; do it once they're installed.

## The concept
A **scheduled task** on Windows is a job the system runs automatically: on a
timer, at logon, at startup, or when some event happens. They are completely
normal (Windows ships with dozens), which is exactly why attackers like them. A
scheduled task is one of the most common ways to get **persistence**: a foothold
that survives a reboot or a logoff, because the task quietly re-runs the
attacker's program on a schedule.

So "a new scheduled task appeared" is a signal a defender takes seriously, and
the useful skill is reading the task to decide whether it is benign or not. Every
task has three parts worth checking:
- **the trigger**: when it runs (daily, at logon, at startup),
- **the action**: what program it runs, and with what arguments,
- **who created it and when**.

Windows records a task being created as **Security event 4698** ("a scheduled
task was created"), and the task's action, when it fires, shows up as a
process-start event (Sysmon event 1). Those two together let you explain a task
without logging in and clicking through Task Scheduler.

## Your mission
A scheduled task that was not there before now exists on **win-srv**. Explain it:
1. The **task name** and **when it was created**.
2. The **trigger**: what makes it run.
3. The **action**: the exact program and arguments it runs.
4. Your **verdict**: does this look benign or suspicious, and what single fact
   drove your call?

## The analyst workflow
1. Set up the stand-in (see the staging note), then start in Wazuh with the
   win-srv filter and find the task-creation event.
2. Read the task name and creation time off that event.
3. Find the action: either from the creation event's detail, or from the
   process-start event when the task runs. Note the program and arguments.
4. Weigh trigger plus action plus who created it, and commit to a verdict with the
   one fact that decided it.

## Predict before you run
Before you look: of the three parts of a task (trigger, action, creator), which
one would most quickly tell you a task is hostile rather than routine? Why that
one?

## What good looks like
Your case file names the task, its creation time, its trigger and its exact
action, and states a verdict backed by one clear fact. Do not just say "a task
exists": say what it runs and when.

## Hints
1. Filter to win-srv and search for the scheduled-task creation event rather than logon events.
2. The creation of a task is Windows Security event 4698, "a scheduled task was created".
3. The action (the program it runs) may be clearer in the process-start event, Sysmon event 1, captured when the task fires.
4. Verdict rule of thumb: a task that runs a script interpreter or something out of a user-writable or temp folder deserves suspicion; one that runs a signed system tool from a normal path usually does not.

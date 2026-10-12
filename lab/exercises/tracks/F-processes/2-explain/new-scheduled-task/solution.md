# Answer key: Find a scheduled task that appeared

## What happened
A new scheduled task was created on win-srv. In this practice version you create
a benign stand-in yourself: a task that writes the current date to a file under
`C:\ProgramData\lab\` on a daily trigger. You then work the lesson from the other
side, reading it back out of the logs as if you had just discovered it. The skill
is reading a task's trigger and action to reach a verdict, and that skill is the
same whether the task is benign or hostile.

## The evidence
- **Windows Security event 4698, "a scheduled task was created"**, records the
  task name and the time, and carries the task definition (its trigger and
  action) in the event detail.
- When the task fires, its action runs as a process, so a **Sysmon event 1
  process-create** (and the built-in **4688**) shows the exact program and
  command line it executed.
- On-box you can confirm read-only with `schtasks /Query /TN <name> /V /FO LIST`
  or `Get-ScheduledTask`.

## Answers to the mission
1. The task name and creation time come straight from the 4698 event.
2. The trigger for the stand-in is a daily schedule. (In a real case it is often
   "at logon" or "at startup", which is what gives persistence.)
3. The action is the exact program and arguments: for the stand-in, a command
   that writes the date into `C:\ProgramData\lab\<name>.log`. Read it from the
   4698 detail or the process-start event.
4. Verdict for the stand-in: **benign**, because the action only writes a
   timestamp to a lab folder and runs a normal command. The fact that decides it
   is the action, not the mere existence of the task.

## MITRE ATT&CK
**T1053.005 Scheduled Task/Job: Scheduled Task.** Creating a Windows scheduled
task is a standard persistence and execution technique: the task re-runs the
attacker's program on a trigger, surviving reboots and logoffs. You detect it at
the moment of creation (4698) and again each time it runs (Sysmon 1 / 4688).

## Common mistakes
- Stopping at "a task exists" without reading its action. The action is the whole
  point.
- Ignoring the trigger. "At logon" or "at startup" is what turns a task into
  persistence.
- Assuming a familiar-looking task name means safe. Attackers pick names that
  blend in, so judge the action and path, not the label.

## Interview talking point
"Scheduled tasks are a favourite persistence trick because they re-run on a
trigger and survive reboots. I treat a new task as something to read, not just
note: I pull the creation event 4698 for the trigger and creator, and the
process-start event for the exact action, then decide benign or not from what it
runs and where that program lives, ATT&CK T1053.005."

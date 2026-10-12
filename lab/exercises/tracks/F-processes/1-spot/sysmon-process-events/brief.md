# F1 Spot: See process-start events from Sysmon on win-srv

> Needs the detection add-ons from unit 4 (Sysmon on win-srv / process auditing on linux-srv). Read it any time; do it once they're installed.

## The concept
Windows' default Security log is good at telling you *who logged in*. It is much
weaker at telling you *what they did next*: which programs started, who started
them, and with what command line. For a defender that second question is where
most of the interesting activity lives, because an attacker who is already logged
in spends their time running programs.

Two log sources fill that gap, and you should know both:
- **Sysmon** (System Monitor) is a free Microsoft tool you install. Its
  **event id 1** is "process create", and it is rich: it records the program,
  the full command line, the parent program that launched it, the user, and a
  hash. This is the one you lean on.
- **Windows Security event 4688** ("a new process has been created") is built in,
  but only if the "Audit Process Creation" setting is turned on (the lab's audit
  policy turns it on, and also adds the command line to 4688).

Both describe the same real event, a program starting, from two angles. Knowing
they overlap stops you double-counting and helps you cross-check.

## Your mission
On **win-srv**, confirm you can see process-start telemetry in Wazuh:
1. Find process-start events for win-srv and identify which **Sysmon event id**
   carries them.
2. Pick one event and read off the **program**, the **command line**, and the
   **parent program** that started it.
3. Note whether the same start also shows up as a **Windows Security event**, and
   which event id that is.

## The analyst workflow
1. Start broad in Wazuh (Threat Hunting > Events) with the win-srv filter, then
   narrow to Sysmon by its data source or event id.
2. Generate a little activity yourself so you have something to find: run a couple
   of harmless commands on win-srv (for example `whoami`, then `ipconfig /all`).
3. Open one event and read the fields. Note the event id, the program path, the
   command line, and the parent program.
4. Search again for the built-in process-creation event and confirm the same
   action appears there too.

## Predict before you run
Before you look: once Sysmon is installed, will win-srv raise *more alerts*, or
just produce *more logs*? Those are not the same thing. Which one is it, and why?

## What good looks like
Your case file names the Sysmon event id for process creation, shows one event
with its program, command line and parent program, and notes the matching
built-in Windows event id, so you can explain the two sources side by side.

## Hints
1. In Wazuh, filter to win-srv, then add the event id: Sysmon process creation is event id 1.
2. The fields you want are the image (program path), the command line, and the parent image (the program that launched it).
3. The built-in Windows equivalent is Security event 4688, "a new process has been created" (it carries the command line because the lab's audit policy turned that on).
4. More logs is not more alerts: Sysmon mostly adds raw visibility. Alerts only appear when a rule matches, which is what the later F lessons are about.

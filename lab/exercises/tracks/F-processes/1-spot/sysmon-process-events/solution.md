# Answer key: See process-start events from Sysmon on win-srv

## What happened
Nothing malicious. This lesson is about telemetry, not an incident: you install
Sysmon, generate a little harmless activity, and confirm the process-start events
arrive in Wazuh so later F lessons have something to detect on.

## The evidence
- **Sysmon event id 1 (process create)** is the main source. One event carries,
  for a single program start:
  - the **image**: the program's full path (for example
    `C:\Windows\System32\whoami.exe`),
  - the **command line**: exactly how it was invoked,
  - the **parent image**: the program that launched it (for example
    `powershell.exe` or `cmd.exe`),
  - plus the user and a file hash.
- **Windows Security event 4688 (a new process has been created)** records the
  same start. Because the lab's audit policy sets
  `ProcessCreationIncludeCmdLine_Enabled`, 4688 also includes the command line.

## Answers to the mission
1. Process-start events come from **Sysmon event id 1**.
2. For your chosen event you can read the program (image), the full command line,
   and the parent program (parent image) that started it. The parent is the field
   that later lets you spot an odd chain of programs launching each other.
3. The same start also appears as **Windows Security event 4688**. Sysmon event 1
   and 4688 describe the same action from two sources, so you cross-check rather
   than double-count.

## MITRE ATT&CK
No single technique: this is a **data source**, not an attack. Process creation
(Sysmon 1 / Windows 4688) is the telemetry that underpins detection of the
execution techniques you meet later, such as the T1059 Command and Scripting
Interpreter family. Good execution detections start with good process logging.

## Common mistakes
- Treating "more logs" as "more alerts". Sysmon adds visibility; an alert needs a
  rule to match (that is the F4 lessons).
- Reading only the program name and missing the command line and parent, which
  are usually the parts that tell the story.
- Forgetting 4688 exists and assuming Sysmon is the only source.

## Interview talking point
"Default Windows logging tells me who logged in; Sysmon tells me what they ran. I
installed Sysmon and confirmed its event id 1 process-create records flowing into
my SIEM, with the image, command line and parent process, and I know the built-in
event 4688 covers the same ground once process-creation auditing is on. That
process visibility is the foundation every execution detection builds on."

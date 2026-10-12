# Answer key: Trace what a user ran after logging in

## What happened
The staging created a temporary local user on linux-srv and, as that user, ran a
short series of harmless read-only commands: the classic "where am I and what can
I see" look-around that someone does right after getting onto a box. Nothing was
changed. The value of the lesson is reading the sequence, not the single
commands.

## The evidence
Your command monitoring (auditd `execve` events, or Wazuh command monitoring)
shows these events for one user, close together in time:
- `id` - who am I, and which groups am I in.
- `uname -a` - kernel and architecture of this host.
- `cat /etc/os-release` - the distribution and version.
- `ls /home` - which other user accounts exist on this box.

The account name for this run is under *This run's details*.

## Answers to the mission
1. The account is this run's user (see *This run's details*), a plain local
   account with a home directory.
2. In order: `id`, then `uname -a`, then `cat /etc/os-release`, then `ls /home`.
3. What each reveals: `id` = the user's own identity and privileges; `uname -a`
   and `cat /etc/os-release` = what operating system and version this is;
   `ls /home` = who else has an account here. Together: identity, system,
   neighbours.
4. This reads as **getting their bearings**, not routine work. Four discovery
   commands back to back, and nothing that does actual work, is the shape of
   someone orienting on a new machine.

## MITRE ATT&CK
**T1059.004 Command and Scripting Interpreter: Unix Shell** is the execution
technique: the commands ran through a shell, which is what your monitoring
recorded. The individual commands are **discovery**: `uname`/os-release map to
T1082 System Information Discovery, `id` to T1033 System Owner/User Discovery, and
`ls /home` to T1087 Account Discovery. Naming the shell plus the discovery it
carried is a complete answer.

## Common mistakes
- Judging commands one at a time and calling each "normal". The sequence is the
  signal.
- Recording the program but not the arguments, so you lose what `uname -a` or
  `cat /etc/os-release` was actually after.
- Getting the order wrong. Without real timestamps you cannot tell orientation
  from random activity.

## Interview talking point
"I reconstructed a user's first few minutes on a Linux host from command logs:
`id`, `uname -a`, `cat /etc/os-release`, `ls /home`, in that order. Any one is
harmless, but together they are a textbook discovery sequence, someone learning
their identity, the system, and what other accounts exist. The shell execution is
ATT&CK T1059.004, and I could map each command to its discovery technique."

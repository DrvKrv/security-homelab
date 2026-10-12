# Answer key: Spot an unusual program running on linux-srv

## What happened
The staging left one program running on linux-srv from a hidden directory under
`/tmp`, with a name chosen to look like a normal system daemon. The program
itself is harmless (it is a copy of `/bin/sleep` doing nothing but sleeping). The
point of the lesson is the two red flags, not the program's behaviour.

## The evidence
- The running program's **path** is `/tmp/.cache/<name>`, where `<name>` is this
  run's value (shown under *This run's details*). The names in the pool look like
  services, for example `kworkerx` or `netd-helper`.
- Your process monitoring (auditd execve events, or Wazuh command monitoring)
  shows the program running from that path. On-box, `ps aux` and
  `ls -la /tmp/.cache/` confirm it read-only.
- Nothing normal runs from `/tmp`. Compare its path to real services under
  `/usr/bin` and `/usr/sbin`.

## Answers to the mission
1. The program name and path are `/tmp/.cache/<name>` for this run (see *This
   run's details*).
2. It is unusual on two counts: it runs from `/tmp` inside a hidden `.`-directory
   (a place real daemons never live), and its name imitates a system service to
   make you scroll past it. The location is the hard giveaway.
3. You found it from process / command telemetry filtered to linux-srv, not from
   any login event, which is exactly what the unit 4 add-ons bought you.

## MITRE ATT&CK
**T1036.005 Masquerading: Match Legitimate Name or Location.** The stand-in uses
a service-like name to blend in. The twist here is location: by running from a
hidden `/tmp` directory it fails the "legitimate location" half of the technique,
and that mismatch is what you detect on.

## Common mistakes
- Judging only by the name. The name is meant to fool you; the path tells the
  truth.
- Killing the process before noting its name, path and parent. Spot first.
- Assuming "it is in the process list, so it must be fine". Standard tools can be
  copied anywhere and renamed.

## Interview talking point
"I flagged a program running out of a hidden `/tmp` directory with a daemon-style
name. Real services do not run from `/tmp`, so the location was the tell, not the
name. That is masquerading by location, ATT&CK T1036.005, and I caught it with
process monitoring rather than by logging in and guessing."

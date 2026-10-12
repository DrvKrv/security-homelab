# F4 Prevent: A rule for hidden (encoded) PowerShell, tested with Atomic Red Team

> Needs the detection add-ons from unit 4 (Sysmon on win-srv / process auditing on linux-srv). Read it any time; do it once they're installed.

## The concept
PowerShell can take a whole command packed into a single base64 blob, passed with
the **`-EncodedCommand`** switch (often shortened to `-enc`). There are honest
uses, but attackers love it because the readable command never appears on the
command line: a human skimming the logs sees a wall of base64 instead of
`Invoke-WebRequest ...`. Hiding a command this way is a defence-evasion move, and
catching the pattern is a classic detection-engineering win.

Here you cross from reading alerts to building them. You already know Sysmon
event 1 (process create) records every program start with its full command line.
So the rule is simple to state: when PowerShell starts **and** its command line
contains an encoded-command flag, raise an alert. You will write it as a custom
Wazuh rule (your ids are 100300 to 100399) that **chains** off the rule Wazuh
already fires for a Sysmon process-create event, then test it for real with a
published **Atomic Red Team** test, a small, vetted script that performs one
ATT&CK technique so you can see whether your detection fires.

## Your mission
1. Write a custom rule (id in 100300 to 100399) that fires when **powershell**
   starts with an **encoded-command** flag on its command line, at a level that
   stands out.
2. Validate the ruleset and test the rule **offline** with `wazuh-logtest`.
3. Test it **for real**: run the published Atomic Red Team test for **T1059.001**
   whose name mentions an encoded command, and confirm your rule fires in Wazuh.
4. Run the atomic's **cleanup** afterwards, and note one way an attacker could
   evade your rule.

## The analyst workflow
1. Find the base rule to chain from: run a Sysmon event-1 line for a PowerShell
   start through `wazuh-logtest` and note the rule id and the field names it
   decodes (especially the command-line field).
2. Write your rule with `<if_sid>` pointing at that base rule, plus a `<field>`
   match for the encoded-command flag, and a clear description and level.
3. `wazuh-analysisd -t` to validate, then `wazuh-logtest` to confirm it fires on
   an encoded-command line and does not fire on an ordinary PowerShell line.
4. On win-srv, list the atomics with `Invoke-AtomicTest T1059.001
   -ShowDetailsBrief`, pick the one whose name mentions an encoded command, run
   it, check Wazuh, then run `Invoke-AtomicTest T1059.001 -Cleanup`.

## Predict before you run
Before you write the rule: should it match the **raw command line text** for the
flag, or the **decoded program name** for PowerShell, or both? Which single
condition would create the most false positives on its own, and why?

## What good looks like
A new rule in `local_rules.xml`, a clean `wazuh-analysisd -t`, a `wazuh-logtest`
run showing your rule id fire on an encoded-command line (and stay quiet on a
normal one), and a screenshot of your rule firing on the real Atomic Red Team
test. Note the evasion you spotted.

## Hints
1. Do not match a Sysmon line from scratch. Find the rule id Wazuh fires for a Sysmon event-1 process-create via `wazuh-logtest`, and chain to it with `<if_sid>`.
2. Match two things: the image is powershell (powershell.exe or pwsh.exe) and the command line contains the flag. In Wazuh, `<field name="win.eventdata.commandLine">-[eE]nc</field>` catches both -enc and -EncodedCommand (confirm the exact field name in your logtest output).
3. Always `wazuh-analysisd -t` before restarting, then `wazuh-logtest` both ways: a line with -enc should fire your rule, a plain `powershell -Command Get-Date` should not.
4. Evasion to note: the switch can be abbreviated (-e, -ec), split, or cased oddly, so a too-literal match can be dodged. That is the T1027 obfuscation angle, and a good line for your write-up.

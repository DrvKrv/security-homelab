# Answer key: A rule for hidden (encoded) PowerShell, tested with Atomic Red Team

## The shape of the rule
You chain off the rule Wazuh already fires for a Sysmon event-1 process-create and
add two conditions: the program is PowerShell, and its command line carries an
encoded-command flag. Confirm the base rule id and the exact field names against
your own version with `wazuh-logtest` (run a Sysmon PowerShell-start line through
it and read the decoding phase), then fill them into the `<if_sid>` and `<field>`
below.

```xml
<group name="lab,sysmon,windows,">
  <!-- if_sid = the rule your Wazuh fires for a Sysmon event 1 (process create).
       Find it with wazuh-logtest; do not guess it. -->
  <rule id="100300" level="12">
    <if_sid>SYSMON_PROCESS_CREATE_RULE_ID</if_sid>
    <field name="win.eventdata.image">(?i)powershell\.exe|pwsh\.exe</field>
    <field name="win.eventdata.commandLine">-[eE]nc</field>
    <description>Lab: PowerShell launched with an encoded command (hidden command line).</description>
    <mitre>
      <id>T1059.001</id>
      <id>T1027.010</id>
    </mitre>
  </rule>
</group>
```

Key points:
- **id 100300**, inside your 100300 to 100399 range, so it never collides with
  Wazuh's own rules.
- **`if_sid`** chains to the Sysmon process-create rule, so you inherit its
  decoding and only add your two conditions. Find that id with logtest.
- **Two conditions, not one.** Matching only `-enc` anywhere would fire on any
  command line that happens to contain that text; also requiring the image to be
  PowerShell is what keeps it specific. That is the predict-before-you-run answer:
  the command-line match alone is the bigger false-positive risk.
- **level 12**, well above a normal process-start, so it stands out.

## Testing it (the proof)
1. Validate: `sudo /var/ossec/bin/wazuh-analysisd -t` must say the config is OK.
2. Offline: `sudo /var/ossec/bin/wazuh-logtest`. A Sysmon line for
   `powershell.exe -enc <base64>` should fire **100300** at level 12; a plain
   `powershell.exe -Command Get-Date` should **not**. Paste both into your case
   file: the positive and the negative test.
3. For real, on win-srv: `Invoke-AtomicTest T1059.001 -ShowDetailsBrief`, choose
   the test whose name mentions an **encoded command**, run it, and confirm
   100300 fires in Wazuh. Then always run `Invoke-AtomicTest T1059.001 -Cleanup`
   for that test.

## MITRE ATT&CK
**T1059.001 Command and Scripting Interpreter: PowerShell** is the execution.
**T1027.010 Obfuscated Files or Information: Command Obfuscation** is why it is
hidden: the encoded command keeps the real intent off the readable command line.
Your rule detects the obfuscation pattern rather than the payload.

## Common mistakes
- Matching only the command line and not the image, so unrelated events trip the
  rule.
- Guessing the `if_sid` or the field name instead of reading them from
  `wazuh-logtest`.
- Skipping the negative test, so you cannot show the rule is specific.
- Forgetting the atomic cleanup.

## Interview talking point
"I wrote a Wazuh rule that flags PowerShell started with an encoded command,
which hides the real command behind base64. I chained off the Sysmon
process-create rule, required both the PowerShell image and the encoded-command
flag, validated and tested it with logtest including a negative case, then proved
it against an Atomic Red Team test for T1059.001 and ran the cleanup. I also noted
it can be evaded by abbreviating the switch, the T1027.010 obfuscation angle,
which is the honest limit of a string-match rule."

# Answer key: A rule for password spraying: many accounts, one source

## What happened
A spray leaves one 4625 per account, all from the same address. Rule 60122 fires
on each, but nothing that counts per account ever reaches its threshold. Your
rule counts across accounts instead.

## The rule
Append to `/var/ossec/etc/rules/local_rules.xml` on wazuh:

```xml
<group name="lab,local,windows,">
  <!-- Possible password spraying: failed logons for several different
       accounts from one source address within 10 minutes. -->
  <rule id="100320" level="10" frequency="4" timeframe="600" ignore="300">
    <if_matched_sid>60122</if_matched_sid>
    <same_field>win.eventdata.ipAddress</same_field>
    <different_field>win.eventdata.targetUserName</different_field>
    <description>Lab: possible password spraying, failed logons for several accounts from $(win.eventdata.ipAddress)</description>
    <mitre><id>T1110.003</id></mitre>
    <group>authentication_failures,</group>
  </rule>
</group>
```

Then `sudo /var/ossec/bin/wazuh-analysisd -t && sudo systemctl restart wazuh-manager`.
`same_field` and `different_field` exist in current Wazuh 4.x releases. If the
test rejects them, read the rules syntax page for your version and use its
equivalent.

## Answers to the mission
1. A spray gives each account one failure, so any rule that counts failures per
   account never reaches its threshold.
2. The rule above: chained on **60122**, same source address, different account.
3. **Numbers:** 4 different accounts in 10 minutes. One real person fails on one
   account. A few colleagues sharing one machine might reach 2 or 3. Four distinct
   accounts from one address in 10 minutes is well past normal for a small office.
   A busier network needs a higher count; say how you would measure it.
4. **Positive:** the hand-made spray (4 or 5 accounts, one try each) fires
   **100320** on dc01's agent, with the source in the description.
5. **Negative:** wait 10 minutes, then fail 3 times on one account: 60122 three
   times, no 100320 (repeats of one account do not count). One typo: one 60122,
   nothing else. Both are needed to show the rule is specific.

**Predict answer:** a shared machine (a front-desk PC, a terminal server, a jump
host such as win-srv) or a gateway that hides many users behind one address. Tell
them apart by the failure reason (made-up names versus real ones), the time
pattern (a spray is fast and even), and whether successes follow from the same
people's usual machines.

## MITRE ATT&CK
T1110.003 Brute Force: Password Spraying. The rule detects its key shape.

## Common mistakes
- Using the wrong field names. Copy them from a real event's JSON, not from memory.
- Running the negative test straight after the positive one, inside the same
  window, so the earlier events still count.
- Only testing the positive case. A rule that fires on everything also passes it.
- Testing the spray with several tries per account and locking accounts.

## Interview talking point
"Password spraying is built to beat per-account rules and lockouts, so I wrote a
Wazuh correlation rule that flips the question: same source, different accounts,
four in ten minutes. I chained it on the single-failure rule, used same_field and
different_field on the decoded Windows fields, and proved it with a positive test
and two negative ones. I also documented where it could false-positive, like a
shared terminal, and how I would tell that apart."

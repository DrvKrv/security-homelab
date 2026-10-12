# Answer key — write your own rule

## The shape of the rule
Direct root SSH login is the target. You chain off the built-in "sshd:
authentication success" rule and add the condition that the user is root. A
working example (confirm the exact `if_sid` and field name against your version
via `wazuh-logtest`):

```xml
<group name="lab,ssh,local,">
  <!-- 5715 is the sshd authentication-success rule in the stock ruleset.
       Verify yours by running a normal success line through wazuh-logtest. -->
  <rule id="100300" level="12">
    <if_sid>5715</if_sid>
    <field name="dstuser">^root$</field>
    <description>Lab: successful SSH login as root (direct root login is not allowed)</description>
    <group>authentication_success,pci_dss_10.2.5,</group>
  </rule>
</group>
```

Key points:
- **id 100300** — in the custom 100000+ range, so it never collides with Wazuh's.
- **`if_sid`** chains to the success rule, so you inherit all its decoding and
  only add your extra condition. This is the idiomatic way, not re-matching the
  whole line.
- **Match the decoded field** (`dstuser`), not the raw string "root". Matching raw
  text is brittle — "root" could appear in a path or another user's name. The
  decoded field is unambiguous. (That's the predict-before-you-run answer.)
- **level 12** — well above the default success level, so it stands out.

## Testing it (the proof)
1. Validate: `sudo /var/ossec/bin/wazuh-analysisd -t` → must say the configuration
   is OK before you restart anything.
2. Test offline: `sudo /var/ossec/bin/wazuh-logtest`, then paste a root-success
   line, e.g.:
   ```
   Jan  1 12:00:00 linux-srv sshd[1234]: Accepted password for root from 10.0.1.10 port 54321 ssh2
   ```
   You should see **rule id 100300, level 12** fire. Paste that output into your
   case file.
3. A normal non-root success line should **not** trigger 100300 — test that too,
   so you've shown the rule is specific, not just firing on everything.

## Why it matters / interview answer
"I wrote a custom Wazuh rule to flag direct root SSH logins, which the stock
ruleset treats as ordinary successes. I chained off the built-in success rule
with `if_sid` and matched the decoded user field rather than raw text, validated
the ruleset with `wazuh-analysisd -t`, and proved it with `wazuh-logtest` —
including a negative test that a non-root login doesn't trip it." Being able to
*extend* the SIEM, safely and with tests, is a genuine detection-engineering
skill and rare in an entry-level candidate.

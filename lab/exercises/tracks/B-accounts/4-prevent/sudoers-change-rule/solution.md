# Answer key: Alert on changes to sudo rights, then test it

## The fix
Add to `/var/ossec/etc/rules/local_rules.xml` on the wazuh VM:

```xml
<group name="lab,privilege_change,">
  <rule id="100310" level="12">
    <if_sid>550,553,554</if_sid>
    <field name="file">^/etc/sudoers</field>
    <description>Lab: sudo rights file changed: $(file)</description>
    <mitre>
      <id>T1548.003</id>
    </mitre>
    <group>lab_privilege_change,</group>
  </rule>
</group>
```

```bash
sudo /var/ossec/bin/wazuh-analysisd -t && sudo systemctl restart wazuh-manager
```

This exact pattern (chained from 550/553/554, matched on `file`) was checked on
a live Wazuh 4.12 manager watching a folder: a new file raised the custom rule
at level 12 within seconds, with the path in the description.

## The evidence
After staging on linux-srv: your rule (100310 here) at level 12, description
naming `/etc/sudoers.d/<file>`, `syscheck.path` the same, and the diff of the
added line if `report_changes` is on (it is, in the lab's agent config).

## Answers to the mission
1. to 3. The rule above.
4. Your rule id in Wazuh right after staging.
5. Verify passes.
6. Gaps (any one is a good answer): adding an account to the `sudo` (or `admin`)
   group, which rule 100110 covers instead; a `/etc/sudoers.d` file whose name
   contains a dot is ignored by sudo, so it changes nothing yet still alerts
   (a false positive, not a gap); giving an account root's UID 0 in
   `/etc/passwd`; adding an SSH key to root's `authorized_keys`; a polkit rule
   or a setuid program. File integrity only sees files it watches.

**Predict:** only yours. When a child rule matches, Wazuh reports the most
specific match, not its parent as well. That's why chaining is a clean way to
raise the level without doubling the alerts.

## MITRE ATT&CK
T1548.003 Abuse Elevation Control Mechanism: Sudo and Sudo Caching.

## Common mistakes
- Matching only `/etc/sudoers` exactly, missing the `.d` folder.
- Chaining from 550 only, so new files (554) never raise it.
- Restarting without `-t` first.
- Writing the rule but never staging, so it's untested.

## Interview talking point
"I found that our admin-rights alert only covered group membership, so I wrote a
Wazuh rule that chains from file integrity monitoring and raises any change to
the sudoers files to high severity. I validated the ruleset, proved the rule by
re-running the change it was meant to catch, and wrote down what it still
wouldn't see."

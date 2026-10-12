# Answer key: Auto-block a brute-forcing source with Wazuh active response

## What happened
The staging script on wazuh tried SSH logins against linux-srv. The made-up
usernames raised **5712** (sshd brute force). Your active response matched that
rule, so the manager told the agent on linux-srv to run `firewall-drop` with the
alert's source, 10.0.1.10. linux-srv dropped everything from wazuh until the
timeout ran out, then the agent removed the rule by itself.

## The fix
Add this inside the `<ossec_config>` section of `/var/ossec/etc/ossec.conf` on
wazuh, next to the commented-out active-response example:

```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5712,5763</rules_id>
  <timeout>300</timeout>
</active-response>
```

- `firewall-drop` is already defined as a `<command>` in the stock file, with
  `timeout_allowed` set to yes.
- `location local` runs it on the agent that raised the alert. 5712 and 5763 are
  sshd rules, so only Linux machines running SSH can trigger it. For extra safety
  use `<location>defined-agent</location>` with `<agent_id>` set to linux-srv's id.
- **Never** list Windows rules such as 60122 or 60204 here; that would let a
  block land on win-srv.

Then: `sudo /var/ossec/bin/wazuh-analysisd -t && sudo systemctl restart wazuh-manager`.

## The evidence
- **Wazuh:** the 5712 alert, then an alert from linux-srv raised by the active
  response itself (its description mentions the firewall-drop response). Record its id.
- **linux-srv during the block:** `sudo iptables -S | grep 10.0.1.10` shows a DROP
  rule for 10.0.1.10. `sudo tail /var/ossec/logs/active-responses.log` shows an
  `add` entry for that address.
- **From wazuh during the block:** `nc -z -w 3 10.0.1.30 22 && echo open || echo blocked` prints `blocked`.
- **The staging log** probably says Round 2 was skipped with "no answer". That is
  the block working, not a key-only server.
- **After 300 seconds:** a `delete` entry in the log, no DROP rule, `open` again.

## Answers to the mission
1. The block above, with a 300 second timeout.
2. `rules_id` lists only sshd rules, and the location is the alerting agent.
3. and 4. The evidence list, with times.
5. The predict answer: all traffic from wazuh is dropped, so wazuh's SSH to
   linux-srv fails, and **linux-srv's agent may show as disconnected**, because the
   manager's replies are dropped too. Its events catch up after the block. In a
   real network you would list your own servers in `<white_list>` (in the
   `<global>` section) so a response can never block the SIEM. Here we leave
   wazuh off that list on purpose, because it is also the pretend attacker.

**Before the next lesson,** remove or comment out the block and restart the
manager, or every SSH brute-force lesson will now block wazuh for five minutes.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing. Active response cuts the guessing short.

## Common mistakes
- No timeout: the block is permanent until someone remembers to remove it.
- A trigger that is too broad, such as a whole rule group or Windows logon rules.
- Expecting 5763 to trigger it when linux-srv is key-only. 5712 is the reliable trigger here.
- Checking for the block from wazuh only. Look on linux-srv, where it lives.

## Interview talking point
"I set up Wazuh active response to drop an SSH brute-forcing source at the host
firewall, with a five-minute timeout so blocks clean themselves up. I limited the
trigger to the sshd brute-force rules and kept it off the Windows jump host. I
proved it with the firewall rule, the add and delete entries and the connection
test, and I learned that blocking your own SIEM's address blinds you, which is
why production setups allow-list their own infrastructure."

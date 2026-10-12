# Answer key: Tune the brute-force threshold: catch attacks, ignore typos

## What happened
The staging script plays an attacker from the wazuh VM: a round of made-up
usernames, then a round of wrong passwords for `labuser`. Each wrong password is
rule **5760** (sshd authentication failed). The stock burst rule **5763** counts
5760 from the same source. Your job was to add your own counting rule with a
threshold you can defend.

## The evidence
The stock rule, from the grep in hint 1, looks like this (check your version):
`<rule id="5763" level="10" frequency="..." timeframe="..." ...>` with
`<if_matched_sid>5760</if_matched_sid>` and `<same_source_ip />`. The lab's own
notes in `lab/wazuh/manager/local_rules.xml` describe it as 8 or more in 2
minutes. Record what your manager actually says.

## Answers to the mission
1. **Stock threshold:** the `frequency` and `timeframe` you read on 5763, counted
   per source IP.
2. **A defensible choice:** for example 5 wrong passwords from one address in 5
   minutes. A person who mistypes usually gets it right, or gives up, within 2 or
   3 tries. Five in five minutes with no success is past normal, and it catches a
   slower or smaller attacker than the stock rule does.
3. **The rule**, appended to `/var/ossec/etc/rules/local_rules.xml` on wazuh:
   ```xml
   <group name="lab,local,sshd,">
     <rule id="100310" level="10" frequency="5" timeframe="300" ignore="120">
       <if_matched_sid>5760</if_matched_sid>
       <same_source_ip />
       <description>Lab: SSH password guessing, repeated wrong passwords from $(srcip)</description>
       <mitre><id>T1110.001</id></mitre>
       <group>authentication_failures,</group>
     </rule>
   </group>
   ```
   `ignore="120"` stops it re-firing on every extra failure for two minutes.
   Then: `sudo /var/ossec/bin/wazuh-analysisd -t && sudo systemctl restart wazuh-manager`.
4. **Offline proof:** in `sudo /var/ossec/bin/wazuh-logtest`, paste the
   "Failed password" sample 3 times: only 5760 each time. Quit, reopen, paste it
   until your rule fires, and write down on which line it fired.
5. **Live proof** (from `lab/` on wazuh):
   - `bash linux/simulate-ssh-bruteforce.sh 10.0.1.30 3`: only 5710 and 5760, no burst alerts.
   - A count between your threshold and the stock one (for example 6): **100310**
     fires and 5763 does not. This is the proof your tuning adds value.
   - The full run (`./run.sh stage`): 100310 fires, and so does 5763 at its own
     threshold. Each log line produces one alert, so where both qualify you may see
     either one on that line.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing. The rule exists to catch it earlier.

## Common mistakes
- Editing files under `/var/ossec/ruleset/`. Upgrades overwrite them; use local_rules.xml.
- Testing with the made-up-username lines. They are 5710, not 5760, so your rule never counts them.
- Seeing no 5760 at all: linux-srv is key-only. Run `setup-linux-srv.sh` there first.
- Forgetting that logtest keeps counts within a session, which makes the first test look wrong.

## Interview talking point
"I tuned SSH brute-force detection rather than accepting the default. I read the
stock rule's threshold, chose five failures in five minutes per source as a line
that ignores normal typos but catches a slower guesser, and wrote it as a
correlation rule in local_rules.xml. I proved it offline with wazuh-logtest and
live with three runs: a typo-sized run stayed quiet, a mid-sized run fired only
my rule, and a full run fired both."

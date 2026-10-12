# A4 Prevent: Tune the brute-force threshold: catch attacks, ignore typos

> Runs on the current lab. You edit rules on the wazuh VM. linux-srv must accept
> password logins for the test account (`lab/linux/setup-linux-srv.sh` turns
> them on), because typos only exist where passwords do.

## The concept
Every alert rule is a trade-off. Make it too sensitive and it fires every time
someone fat-fingers their password, so analysts learn to ignore it (**alert
fatigue**). Make it too relaxed and a careful attacker stays underneath it. Picking
the line is called **tuning**, and it is one of the most common jobs on a real
detection team.

Wazuh catches bursts with a **correlation rule**: a rule that only fires when
another rule has matched several times. Three settings control it. `frequency`
is how many matches are needed, `timeframe` is the window in seconds, and
`if_matched_sid` names the rule being counted. Options such as
`<same_source_ip />` make it count per source rather than across everyone.

You will not edit Wazuh's own rule files (an upgrade would overwrite them).
Instead you write **your own** rule in `/var/ossec/etc/rules/local_rules.xml`
on the wazuh VM, with an id between 100300 and 100399, and test it two ways: offline
with `wazuh-logtest`, then live by re-staging.

## Your mission
1. Find the stock rule that alerts on a burst of wrong SSH passwords. Record its
   threshold: how many failures, in how many seconds, counted per what.
2. Choose your own threshold. It must stay **quiet for a few typos** and **fire on a
   real burst**, including a smaller burst than the stock rule catches. Write one
   sentence on why you chose those numbers.
3. Write the rule, validate the config and restart the manager.
4. Prove it offline: a typo-sized run stays quiet, a burst fires your rule.
5. Prove it live: re-stage a small run and a full run and compare the alerts.

## The analyst workflow
1. Stage once and look at what the per-attempt and burst alerts look like for
   wrong passwords. Note the per-attempt rule's id.
2. Find the stock burst rule's definition on the wazuh VM and read its settings.
3. Copy the shape of an existing correlation rule in the lab's own rules file
   (the port-scan rule is one) and point it at the per-attempt rule.
4. Validate before restarting, so a typo cannot take the manager down.
5. Test offline, then live with a small attempt count and with the default.

## Predict before you run
If you set the threshold to 3 failures in 10 minutes, what happens on a busy
Monday morning? If you set it to 50 in 1 minute, what slips through?

## What good looks like
A case file (`../../../../case-file-template.md`) with: the stock threshold, your
rule's XML, your reason for the numbers, and four test results (logtest typos,
logtest burst, live small run, live full run) showing which rule fired each time.

## Hints
1. On wazuh: `sudo grep -rn 'id="5763"' /var/ossec/ruleset/rules/` shows the stock burst rule and its `frequency` and `timeframe`.
2. Count single wrong passwords: `<if_matched_sid>5760</if_matched_sid>` plus `<same_source_ip />` and your own frequency and timeframe.
3. Paste sample 3 from `lab/wazuh/manager/logtest-samples.txt` into `wazuh-logtest`; quit and reopen between tests because it remembers counts.
4. Run `wazuh-analysisd -t` before restarting; then from lab/ try `bash linux/simulate-ssh-bruteforce.sh 10.0.1.30 3` and the full run.

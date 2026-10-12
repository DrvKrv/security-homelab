# A4 Prevent: A rule for password spraying: many accounts, one source

> Needs dc01 (unit 7). Read it any time; stage it once dc01 is built. You write
> the rule on the wazuh VM and generate test activity against dc01.

## The concept
Most login rules count **failures per account**: "this account failed N times".
That catches classic brute force, and it is exactly what password spraying is
designed to dodge, because a spray tries each account only once. (If you have not
done the A2 spraying lesson, read its concept section first.)

To catch spraying you flip the question: "how many **different accounts** failed
from the **same source** in a short window?" A person who mistypes fails on their
own account. One address failing on five different accounts in a few minutes is
not a typo.

Wazuh correlation rules can express this. Besides `frequency` and `timeframe`,
a rule can require that a decoded field stays **the same** across the events it
counts (here, the source address) or is **different** each time (here, the account
name). Windows events in Wazuh carry their fields under `win.eventdata`, so your
rule refers to them by those names.

## Your mission
1. In one sentence, explain why a per-account rule misses spraying.
2. Write a rule in `/var/ossec/etc/rules/local_rules.xml` on wazuh (id 100300 to
   100399) that fires when one source fails to log on to several **different**
   accounts within a window. Map it to the right ATT&CK technique.
3. Choose the number of accounts and the window, and justify them.
4. **Positive test:** a hand-made spray fires your rule.
5. **Negative tests:** a few failures on **one** account from one source do not
   fire it, and a single typo does not either.

## The analyst workflow
1. Look at a real failed-logon event from dc01 and write down the exact field
   names for the target account and the source address.
2. Find the rule id Wazuh gives a single failed Windows logon. Your rule counts it.
3. Copy the shape of an existing correlation rule in the lab's rules file, then add
   the "same source, different account" conditions.
4. Validate the config before restarting the manager.
5. Run the positive test, check for your rule. Wait longer than your window, then
   run the negative tests and check it stayed quiet.

## Predict before you run
Your rule says "one source, many accounts". Think of a normal situation where many
different people's failed logons could come from one address. How would you tell
that apart from a spray?

## What good looks like
A case file (`../../../../case-file-template.md`) with: your rule's XML, the
reasoning for your numbers, the positive test with your alert, both negative
tests with "no alert", and your answer to the predict question.

## Hints
1. A single failed Windows logon (event 4625) is Wazuh rule 60122; chain on it with `<if_matched_sid>60122</if_matched_sid>`.
2. Count per source with `<same_field>win.eventdata.ipAddress</same_field>`.
3. Add `<different_field>win.eventdata.targetUserName</different_field>` so repeats on one account do not count.
4. Run `sudo /var/ossec/bin/wazuh-analysisd -t` before restarting; it rejects options your Wazuh version does not know.

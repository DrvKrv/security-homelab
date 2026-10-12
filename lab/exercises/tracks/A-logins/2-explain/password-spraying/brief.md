# A2 Explain: Password spraying: one password tried on many accounts

> Needs dc01 (unit 7). Read it any time; stage it once dc01 is built.

## The concept
A classic brute force hammers **one account** with many passwords. Most
companies defend against that with an **account lockout policy**: after a few
wrong passwords, the account is frozen for a while. **Password spraying** is
the attacker's answer. Instead of many passwords for one account, they try **one
common password** (think of a season and a year) against **many accounts**, once
each. No single account gets enough failures to lock, so the lockout never
triggers, and in a big company someone always has that weak password.

The logs never contain the password itself, so you cannot see "the same password"
directly. You recognise spraying by its **shape**: one source, many different
accounts, about one failure per account, all in a short window. A brute force has
the opposite shape: one account, many failures.

Defenders care because spraying is designed to slip under per-account alerts and
lockouts, and it is one of the most common ways attackers get their first foothold
in a domain.

## Your mission
Explain the failed logons on the domain and answer:
1. Is this **brute force or spraying**? Back it up with two numbers: distinct
   accounts per source, and failures per account.
2. **When** did it start and stop?
3. **From where?** The source address and workstation name.
4. **Which accounts** were tried? Were they real accounts or made-up names?
5. Did **any account sign in successfully** from that source afterwards?
6. Did the built-in "many failures" alert fire? Explain why or why not.

## The analyst workflow
1. From the neutral search, find the failed-logon events in the right window.
2. Add columns for the target account, the source address and the failure
   reason, then sort by time.
3. Count two ways: failures **per account**, and distinct accounts **per source**.
   The dashboard's field list can show the top values of any field.
4. Check the failure reason on each: wrong password and unknown user have
   different codes, which tells you whether the attacker knew real usernames.
5. Search the same source for a successful logon during or after the window.
6. Read the definition of the stock "multiple failures" rule on the manager to
   see what it counts, and compare that with the shape you found.

## Predict before you run
A lockout policy freezes an account after N wrong passwords. If an attacker
tries one password on 30 accounts, how many lockouts happen? What does that tell
you about relying on lockout alone?

## What good looks like
A case file (`../../../../case-file-template.md`) with a timeline, a small count
table (accounts per source, failures per account), the verdict "spraying" or
"brute force" with the numbers that prove it, a yes or no on success, and one
paragraph on why per-account defences miss this.

## Hints
1. Filter dc01 on event id 4625 (Wazuh rule 60122) and add `targetUserName` and `ipAddress` columns.
2. Click `data.win.eventdata.targetUserName` in the field list to see top values; then do the same for `ipAddress`.
3. `subStatus` 0xC000006A is a wrong password for a real account; 0xC0000064 means the account does not exist.
4. Look for 4624 with the same `ipAddress`, and run `sudo grep -rn 'id="60204"' /var/ossec/ruleset/rules/` on wazuh to read what 60204 counts.

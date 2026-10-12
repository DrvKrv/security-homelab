# A1 Spot: Failed logins on the employee portal

> Needs web-srv (unit 6). Read it any time; stage it once web-srv is built.

## The concept
Until now your login alerts came from the operating system: SSH on linux-srv,
Windows sign-ins on win-srv. A web application has its own login page, and the
operating system knows nothing about it. If the app does not write its own log,
a password-guessing attack against it is invisible to your SIEM.

The Acme employee portal on web-srv writes one line per login attempt to its own
**application log** (a log file the app itself writes, not the OS). The Wazuh
agent on web-srv ships that file to the manager, where a custom **decoder** pulls
out the fields (result, username, source address) and custom **rules** turn them
into alerts. One rule handles a single failure. A **correlation rule** fires only
when many failures arrive from one place in a short time.

A defender cares because web logins are often the front door that faces the most
people. One wrong password is normal. A pile of them is a signal.

## Your mission
After you make a few failed sign-ins on the portal, find them in Wazuh and record:
1. The **alert** for a single failed portal login: its description, rule id and level.
2. **Which account** each failure names, and **how many** failures there were.
3. The **source address** Wazuh recorded, and which lab machine that is.
4. Whether a **correlation alert** (many failures, one source) also fired. If it
   did not, say why not.

## The analyst workflow
1. Make the activity: from win-srv's browser, open the portal and sign in with a
   wrong password several times. Note the time you started.
2. In the Wazuh dashboard, open **Threat Hunting > Events**, set the time range to
   the last 15 minutes, and filter to the web-srv agent.
3. Look at the rule descriptions in the list. Find the ones about the portal, then
   expand one event and read its decoded fields.
4. Count the failures. Then look for a higher-level alert in the same window that
   talks about repeated failures.
5. Compare what you typed with what Wazuh recorded. They should match exactly.

## Predict before you run
The portal sits behind a web proxy (nginx) on web-srv. Will the source address in
the alert be your win-srv, or the proxy in front of the portal? What would the
proxy need to do for the app to see the real visitor?

## What good looks like
A case file (`../../../../case-file-template.md`) with: the single-failure rule id
and level, the account name, the failure count, the source address mapped to a
machine name, and a yes or no on the correlation alert with the reason. Add one
line comparing this to the SSH lesson: same idea, different log.

## Hints
1. Filter on the web-srv agent and look for rule descriptions that start with "Acme portal".
2. The per-attempt alert is rule 100401; expand it and read the `srcuser` and `srcip` fields.
3. Rule 100402 fires on 6 failures within 120 seconds from one address; count yours and check the gap between them.
4. The source should be win-srv (10.0.1.20) because nginx passes the visitor's address to the portal in a header.

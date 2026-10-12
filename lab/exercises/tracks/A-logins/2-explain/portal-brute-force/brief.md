# A2 Explain: Portal brute force: which accounts, which source

> Needs web-srv (unit 6). Read it any time; stage it once web-srv is built.

## The concept
At Level 1 you found an alert. At Level 2 you **explain** it: who did what, to
which accounts, from where, when, and whether it worked. An alert is one line;
an explanation is a **timeline** built from every related event, not just the
ones that fired a high-level alert.

A **brute-force** attack against a web login is a burst of password guesses. It
can aim at one account (guessing that person's password) or rotate through
several usernames. The difference matters: one account means a targeted guess,
many accounts means someone is fishing. Either way the question that matters
most is the last one: **did any guess succeed?**

Web apps give you two independent witnesses. The **application log** records
each login result. The **web server access log** records every HTTP request,
including the login form being submitted. When two sources agree, your story is
much stronger than when it rests on one.

## Your mission
Treat the burst as a reported incident and answer:
1. **When** did it start and stop? Give the first and last failed attempt.
2. **From where?** The source address, mapped to a lab machine.
3. **Which accounts** were tried, and how many failures each?
4. Did **any login succeed** from that source during or after the burst? Prove it.
5. Does the **web access log** tell the same story? Give one matching line.

## The analyst workflow
1. Start from the neutral search (the web-srv agent) and widen the time range
   until the activity is inside it.
2. Pull **all** portal login events, failures and successes together, so a
   success cannot hide among the failures.
3. Sort by time. Mark the first and last failure: that is the attack window.
4. Group the failures by username and by source. Count each group.
5. Inside the window and just after it, look for a success from the same source.
   If there is one, note which account and when.
6. Check the second witness. Ordinary web requests rarely become Wazuh alerts,
   so read the web access log itself on web-srv for the same minutes. Find the
   login form submissions and check that the count and source match.

## Predict before you run
If the burst ends with one success, what single change in the events would you
expect right after the last failure? Knowing what success looks like is what
lets you prove whether it happened.

## What good looks like
A case file (`../../../../case-file-template.md`) with a real timeline table, a
per-account count of failures, the source mapped to a machine, a clear yes or no
on success with the event that proves it, and one access-log line that matches.

## Hints
1. Portal events are decoded as `acme-portal`; search `agent.name: web-srv and rule.groups: portal` to get both results.
2. Failures are rule 100401, successes 100400, and 100402 is the correlation alert (6 failures in 120 s from one address).
3. Add `data.srcuser` and `data.srcip` as columns in the events table, then sort by time.
4. On web-srv run `sudo grep 'POST /portal/login' /var/log/acme-web/access.log`: a failure returns 200 (the form again), a success 302.

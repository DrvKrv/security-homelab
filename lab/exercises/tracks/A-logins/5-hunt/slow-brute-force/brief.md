# A5 Hunt: A slow brute force spread over hours of normal activity

> Needs the busy-office generator (unit 9). Read it any time; it is staged once
> the generator is built.

## The concept
Every lesson so far started with an alert. **Threat hunting** starts without one.
You begin with a **hypothesis** ("if someone were doing X, the logs would show
Y"), then go looking. Hunting matters because careful attackers study the
alerts and stay underneath them.

Correlation rules count events inside a time window. An attacker who spaces
guesses out, say one every few minutes, never puts enough failures in any one
window, so no burst alert ever fires. Over a working day that still adds up to
hundreds of guesses. Hidden among real staff who mistype their passwords, those
failures look like ordinary noise.

The method is always the same: first learn what **normal** looks like (a
**baseline**), then look for what does not fit it (an **outlier**). A real
typo has a shape: a failure or two, then a success a minute later from that
person's usual machine. Slow guessing has a different shape. Your job is to
find it.

There is **no starting search** for this lesson. No alert fired, so there is
nothing to filter on, and any agent or account filter would point you at the
answer. You start from every failed login in the lab.

## Your mission
1. **Baseline:** on this day, how many failed logins does a typical account have,
   and what usually follows them?
2. **Hypothesis:** write one sentence starting "If someone is guessing slowly, I
   expect to see...".
3. **Outlier:** find the source that does not fit. Which account or accounts, the
   first and last attempt, and the rhythm of the attempts.
4. Explain **why no alert fired**, using the windows of the rules you know.
5. Did it **succeed**? Prove it either way.
6. Propose a **detection** that would catch this next time, and what it would cost.

## The analyst workflow
1. Set the time range to the whole simulated working day. Search for failed
   logins of every kind (portal, SSH, Windows) on all agents.
2. Rank accounts and sources by failure count. Note what is normal.
3. For the top few, check what came next. A success within minutes from the same
   machine is a typo; set it aside.
4. Look for what is left: failures spread over hours, steady gaps, no success
   after, from a machine that is nobody's usual one.
5. Filter to that source and view it on a time histogram: clumps or an even comb?
6. Write the timeline, then search that source for any success.

## Predict before you run
A correlation rule needs 6 failures within 120 seconds from one address. How far
apart must guesses be to never trigger it, and how many fit in an 8-hour day?

## What good looks like
A case file (`../../../../case-file-template.md`) with: the baseline in two or
three numbers, your hypothesis, the outlier's timeline and rhythm, why no rule
fired, the success verdict, and a detection idea with its trade-off.

## Hints
1. Search `rule.id: (100401 or 5760 or 5710 or 60122)` over the whole day, with no agent filter.
2. Use the field list's top values on `data.srcip` and `data.win.eventdata.ipAddress` to rank sources.
3. Typo-prone staff fail once or twice and then succeed from their usual machine; the guesser never does.
4. Filter to the odd source; its failures are evenly spaced for hours, each gap longer than any burst rule's window.

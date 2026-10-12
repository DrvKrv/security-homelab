# A2 Explain: did the SSH attacker get in?

## The concept
Detecting an attack (L1 Spot) is the alarm going off. **Investigating** it is the
real job: reconstruct what happened, in order, and answer the question the
business actually cares about — *did they succeed, and what did they touch?*

The hardest and most valuable skill here is reaching a defensible conclusion,
including a **negative** one. "There was a brute-force attempt and it failed; no
session was established" is a complete, correct answer — and resisting the urge
to over-claim a breach that didn't happen is exactly what a good analyst does.

## Your mission
Treat the SSH brute-force as a reported incident. Produce a proper timeline and
answer:
1. **When** did it start and stop? (first and last failed attempt)
2. **Source and target** — which machines, which accounts.
3. Did the attacker **ever authenticate successfully**? Prove your answer.
4. If they *had* gotten in, **what would you look for next** to scope the damage?

## The analyst workflow (this is the point of the exercise)
1. Pull **all** auth events for linux-srv in the window — both failures *and*
   successes. You're not just looking for the alert now; you're building the full
   picture.
2. Sort by time. Mark the first and last attempt; that's the attack window.
3. The decisive step: inside that window and shortly after, search for a
   **successful** SSH login from the attacker's IP (rule group
   `authentication_success`). Finding none is your evidence the attempt failed.
4. Write the conclusion as cause → effect, citing the specific events. Then, as a
   "what if", list the next places you'd check if it *had* succeeded (new
   processes, sudo use, new files, outbound connections).

## Predict before you run
If a brute-force *had* worked, what single event, right after the last failure,
would you expect to see? Knowing what success looks like is what lets you prove
its absence.

## What good looks like
A filled `../../../../case-file-template.md` with a real timeline table, the explicit
"no successful authentication occurred" finding with the evidence for it, and a
short "if it had succeeded, I would next check…" section. That last part shows
investigative maturity.

## Hints
1. Don't filter to just the brute-force rule this time. Pull the whole auth story — failures and successes together — so a success can't hide.
2. The attack window is first-failure to last-failure. Note both timestamps precisely; that bracket is what you search inside for a success.
3. A successful SSH login has its own rule group (`authentication_success`) and names the user and source IP. Search for one from the attacker's IP. There isn't one — that's the finding.
4. For the "what if succeeded" section, think about the attacker's *next* moves: running commands, escalating with sudo, creating accounts (Track B practises that), or reaching out to the internet.

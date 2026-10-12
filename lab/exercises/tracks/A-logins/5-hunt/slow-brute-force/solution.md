# Answer key: A slow brute force spread over hours of normal activity

## What happened
The busy-office generator runs a normal working day: staff sign in and out on
their own schedules, and the ones with a typo-prone habit miss their password
now and then. Into that day it plants one slow guesser: a single source making
failed logins at a steady pace for hours, against one or a few accounts, never
fast enough to fill any correlation rule's window. Once the generator stages
this lesson, this run's source, accounts and times are shown under *This run's
details* at the end of `reveal`.

## The evidence
- **Per-attempt alerts only:** portal **100401**, SSH **5760** or **5710**, or
  Windows **60122**, depending on where the guessing happened. No **100402**,
  **5763** or **60204**, because no window ever filled.
- **The baseline:** most accounts have zero to a few failures, each followed
  within minutes by a success (**100400**, **5715** or **4624**) from the same
  machine the person always uses.
- **The outlier:** one source with far more failures than anyone else, spread
  evenly across hours. Its gaps are longer than the rule windows (120 seconds for
  the portal and SSH burst rules).
- **Red herrings:** the generator also plants harmless oddities, such as someone
  back from holiday failing a few times. They fail in a clump and then succeed.

## Answers to the mission
1. **Baseline:** a few failures per account at most, followed by a success.
2. **Hypothesis:** "If someone is guessing slowly, I expect one source with many
   failures spread evenly over hours, and no success after them."
3. **Outlier:** this run's source and accounts (see `reveal`), with first and
   last attempt and the gap between attempts.
4. **No alert:** with gaps longer than about 24 seconds, no 120-second window
   ever holds 6 failures. That allows roughly 1,200 guesses in 8 hours (the
   predict answer). Real slow guessers go far slower than that.
5. **Success:** search that source for a success. If there is none, it was an
   attempt. If one appears at the end, that account is compromised and becomes a
   respond case (A3).
6. **Detection:** a long-window rule, such as many failures from one source over
   several hours, or a daily "top failing sources" report. The cost: more memory
   for long windows, and false alarms from addresses that many people share.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing, done slowly to evade threshold rules.

## Common mistakes
- Waiting for an alert. There is none; that is the lesson.
- Starting from one agent or account and missing the cross-lab picture.
- Calling the typo-prone staff suspicious without checking for their success.
- Measuring the attack by its biggest burst instead of its total over the day.

## Interview talking point
"I hunted for a slow brute force that never tripped a rule. I built a baseline
first: most accounts had a couple of failures followed by a success from their
usual machine. Then I ranked sources across the whole day and found one with an
even trickle of failures for hours, spaced just wider than our rule windows, and
no success after. I proposed a long-window rule and a daily top-sources report to
catch it next time."

# Case file: <exercise id> — <short name>

Copy this file for each exercise you do. Fill it from the evidence you gather,
not from the answer key. A filled case file is a ready-made portfolio entry and
great interview material.

- **Analyst:** <your name>
- **Date / time (your timezone):**
- **Exercise:** <level/variant>

## 1. What I was told
One line: what kicked this off (an alert, a routine review, a reported problem).

## 2. Timeline of events
Reconstruct what happened, in order, from the logs. Use real timestamps.

| Time (UTC) | Source (VM / log) | What happened | Evidence (rule id, event id, log line) |
|---|---|---|---|
|  |  |  |  |

## 3. Who / what / where
- **Account(s) involved:**
- **Source machine / IP:**
- **Target machine / IP:**
- **How I know (which log told me):**

## 4. What actually happened (root cause)
Two or three sentences in plain language. What did the attacker do, and how did
they do it?

## 5. Impact / risk
What could have gone wrong if this were real? Who or what was exposed?

## 6. Response
- **Did I contain or clean it up?** (what I did, and when)
- **Verification:** how I confirmed the system is clean / fixed (command output,
  a passing `./run.sh verify`, a re-scan).

## 7. How to detect this faster next time
A rule, a dashboard, an alert threshold — what would catch this sooner?

## 8. What I learned / questions
Anything that surprised you, or that you want to understand better.

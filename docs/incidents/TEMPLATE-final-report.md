# Final Incident Report: `TODO short title`

The capstone report (unit 10). It extends [TEMPLATE-incident-report.md](TEMPLATE-incident-report.md)
for an incident that crosses several machines or accounts. Copy it to
`IR-YYYY-NNN-short-name.md`. Every claim cites an evidence id (`E1`, `E2`...)
from your evidence log ([lab/stages/6-capstone/](../../lab/stages/6-capstone/)).
All times UTC.

| Field | Value |
|---|---|
| **Incident ID** | IR-`YYYY`-`NNN` |
| **Detected** | `YYYY-MM-DD HH:MM` UTC, by `TODO alert / person / hunt` |
| **First known activity** | `YYYY-MM-DD HH:MM` UTC |
| **Contained** | `YYYY-MM-DD HH:MM` UTC |
| **Closed** | `YYYY-MM-DD HH:MM` UTC |
| **Severity** | Low / Medium / High / Critical (justified in section 5) |
| **Hosts in scope** | `TODO` |
| **Accounts in scope** | `TODO` |
| **Analyst** | KT |
| **Simulated?** | Yes: authorized exercise in an isolated lab |

## 1. Executive summary

One paragraph for someone who won't read the rest: what happened, how far it
got, whether data was at risk, what was done, and the one change that matters most.

## 2. Scope

| Host | Role | Involvement | First seen | Last seen | Evidence |
|---|---|---|---|---|---|
| | | entry point / reached / attempted only / not affected | | | E |

| Account | Type | What it did | Evidence |
|---|---|---|---|
| | | | E |

What was **checked and found clean** belongs here too, with evidence: it's what
lets a reader trust the scope.

## 3. Timeline

| Time (UTC) | Host | Event | Result | ATT&CK | Evidence |
|---|---|---|---|---|---|
| | | | attempted / succeeded / blocked | | E |

Mark gaps explicitly: "no logs between X and Y because Z".

## 4. Analysis

Tell the story in order, step by step: what the actor did, how you know, and how
confident you are (confirmed / likely / possible). Separate fact from inference.

## 5. Impact and severity

What the actor could do at the worst point, which assets and data were at risk
(asset inventory criticality), and why that gives the severity above.

## 6. Response

### Containment
What you did first to stop it spreading, when, and how you verified it.

### Eradication
Everything the actor left, where, how you removed it, and the proof.

### Recovery
How you brought things back to normal and decided it was safe.

## 7. Detection review

| Step | Should have been detected by | Did it fire? | Time to detect | Fix |
|---|---|---|---|---|
| | rule / log source | yes / no / not collected | | |

## 8. Root cause

The weakness that made the first step possible, and any that let it go further.

## 9. Recommendations

| # | Recommendation | Addresses | Effort | Priority | Ticket |
|---|---|---|---|---|---|
| 1 | | root cause / detection gap / response | | | [REM-YYYY-NNN](../tickets/) |

## 10. Lessons learned

What went well in the investigation, what slowed you down, and what you'd do
differently.

## Appendix A: Evidence index

The evidence log's rows (id, source, description, SHA-256), without raw data.

## Appendix B: Searches used

```
TODO the Wazuh searches and commands that found each key piece (no secrets)
```

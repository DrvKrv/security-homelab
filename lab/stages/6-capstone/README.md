# Stage 6 / unit 10: the capstone investigation kit

The capstone is where everything comes together: one larger incident across the
company, worked from first alert to final report. The report is the centrepiece
of the case study, the thing you'd walk an interviewer through.

This folder is the **investigation side**: how to scope it, what evidence to
collect and how to keep it trustworthy, and how to write it up. It doesn't stage
anything. (An automated multi-step breach isn't built; see "What to investigate"
below.)

## The kit

| File | Use it for |
|---|---|
| [scoping-questions.md](scoping-questions.md) | The questions to answer at each phase, so nothing is skipped |
| [evidence-checklist.md](evidence-checklist.md) | What to collect from each source, and how to keep it intact |
| [evidence-log-template.md](evidence-log-template.md) | A running record of every piece of evidence: what, where, when, hash |
| [`docs/incidents/TEMPLATE-final-report.md`](../../../docs/incidents/TEMPLATE-final-report.md) | The final report |

## How a capstone runs: the incident response lifecycle

Real teams follow a lifecycle (NIST SP 800-61 is the usual reference). Each phase
has its own section in the scoping questions:

1. **Preparation:** before anything happens. Are the logs you'll need being
   collected? Is the clock right on every machine? Do you know how to reach each
   VM? Your asset inventory and network diagram are part of this.
2. **Detection and analysis:** something looks wrong. Confirm it's real, then
   **scope** it: which machines, which accounts, since when. Build the timeline.
3. **Containment, eradication and recovery:** stop it spreading, remove what the
   attacker left, bring things back to normal, and prove each step.
4. **Post-incident:** root cause, what worked, what didn't, and what changes.
   This is where the report earns its value.

Work in that order, but expect to loop: new evidence in phase 3 often sends you
back to scoping.

## What to investigate

Any incident big enough to cross more than one machine or account works. Ways to
get one in this lab, using what already exists:

- **Stage several lessons in surprise mode** across a day, without looking at
  which (`./run.sh start <box>` picks one at random; `./run.sh stage <id> --surprise`
  fires it at a random time). Treat whatever appears as one incident until you
  can prove it isn't, which is a realistic scoping problem in itself.
- **Ask someone you trust to set it up**: they stage a few lessons on different
  VMs at different times and tell you only "something happened this week".
- **Revisit your own incidents** (IR-2026-001 onwards) as one story: what if
  they were the same actor?

## Rules that still apply

- Everything stays inside the lab. Publish only redacted evidence
  ([publishing checklist](../../../docs/publishing-checklist.md)).
- Times in UTC throughout. Say so in the report.
- Every claim in the report points at a piece of evidence in your evidence log.

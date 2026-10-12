# Stage 6 / unit 10: the capstone investigation kit

The capstone is where everything comes together: one larger incident across the
company, worked from first alert to final report. The report is the centrepiece
of the case study, the thing you'd walk an interviewer through.

This folder has two sides:

- the **investigation side**: how to scope the incident, what evidence to
  collect and how to keep it trustworthy, and how to write it up;
- the **staging side**: a conductor that stages one coherent multi-step breach
  across the lab, quietly, so you have something real to work.

## The kit

| File | Use it for |
|---|---|
| [run-breach.sh](run-breach.sh) | Stage the breach (plan it, arm or fire it, reveal the answer key). Runs on wazuh and linux-srv |
| [Invoke-BreachStep.ps1](Invoke-BreachStep.ps1) | The breach's Windows steps, on win-srv (reuses `lab/windows/Simulate-*.ps1`) |
| [breach-plan.py](breach-plan.py) | The brain behind the conductor: turns a seed into the same ordered plan every time |
| [scoping-questions.md](scoping-questions.md) | The questions to answer at each phase, so nothing is skipped |
| [evidence-checklist.md](evidence-checklist.md) | What to collect from each source, and how to keep it intact |
| [evidence-log-template.md](evidence-log-template.md) | A running record of every piece of evidence: what, where, when, hash |
| [`docs/incidents/TEMPLATE-final-report.md`](../../../docs/incidents/TEMPLATE-final-report.md) | The final report |

## Staging the breach

The conductor does not contain any attack code. It decides which of the lab's
**existing** simulation scripts run, in what order and with what timing, so the
separate incidents you already know become one story: recon, password guessing,
a valid account getting in, a hidden admin account planted for persistence, then
probing to move across. Every step reuses a script in `lab/linux/` or
`lab/windows/`, or a built-in OWASP Juice Shop challenge you solve by hand.

The breach spans more than one VM, so you run the conductor on each, tied
together by a shared **seed** (the same seed always produces the same plan):

```bash
# 1. On any Linux VM, roll a plan once. --envs says which stages you've built.
bash run-breach.sh plan --envs core            # or core,web,ad --within 2d
#    It prints "done" and the seed, and seals the answer key in spoilers/.

# 2. Arm each VM with that seed so the steps fire at their planned times:
bash run-breach.sh arm --seed <SEED>           # on wazuh, and on linux-srv
#    On win-srv, run the Windows steps the plan names, e.g.:
#      .\Invoke-BreachStep.ps1 -Step Logon
#      .\Invoke-BreachStep.ps1 -Step Persistence -Account <name> -DelayMinutes <n>
```

`arm` schedules each VM's steps for later (use `--within 90m` / `6h` / `2d` on
`plan` to spread them out, the closest thing to real on-call work). To run a
controlled demo instead, use `fire`, which runs this VM's steps now, in order.

It is **quiet by design**: `plan`, `arm` and `fire` print only `done`. The plan,
the accounts it chose and every step's raw output live in the git-ignored
`spoilers/` folder. When you want to check your work:

```bash
bash run-breach.sh hint        # one incident-response nudge at a time
bash run-breach.sh reveal      # the sealed plan: the full timeline and answers
bash run-breach.sh status      # what is pending or fired here (no spoilers)
```

**Who sets it up.** The best capstone is one you did not plan yourself. Ask
someone you trust to run `plan` and `arm` (the answer key is for them, not you),
tell you only "something happened this week", and let you investigate cold. If
you set it up yourself, resist opening the plan file until you have written your
own timeline.

**Cleaning up afterwards.** The persistence step leaves a real account behind, on
purpose, so you can practise removing it. Undo it with your own remediation, or
with `bash run-breach.sh cleanup` on the VM that created it (and
`.\Invoke-BreachStep.ps1 -Step Cleanup -Account <name>` on win-srv).

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

The conductor above is the main event: one breach, several machines, worked from
first alert to final report. Run it inside the busy-office noise (unit 9,
`lab/stages/5-office/`) for the full effect, so the attack is hidden in normal
activity and you have to hunt for it.

Other ways to get a capstone-sized incident from what already exists:

- **Stage several lessons in surprise mode** across a day, without looking at
  which (`./run.sh start <box>` picks one at random; `./run.sh stage <id> --surprise`
  fires it at a random time). Treat whatever appears as one incident until you
  can prove it isn't, which is a realistic scoping problem in itself.
- **Revisit your own incidents** (IR-2026-001 onwards) as one story: what if
  they were the same actor?

## Rules that still apply

- Everything stays inside the lab. Publish only redacted evidence
  ([publishing checklist](../../../docs/publishing-checklist.md)).
- Times in UTC throughout. Say so in the report.
- Every claim in the report points at a piece of evidence in your evidence log.

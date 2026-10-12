# Attack scenarios (placeholder)

**Not built yet - this is a documented placeholder.**

Scripted attack scenarios for web-srv are intentionally not written here yet. For
now you don't need them: the training target (OWASP Juice Shop) ships with its own
built-in challenges across the OWASP Top 10, so you already have a well-documented
set of things to attempt, detect in Wazuh, and investigate.

## How to use the target in the meantime

1. Browse the training app from win-srv at `http://<web-srv-ip>:3000/`.
2. Work through its built-in challenges (it has a score board).
3. After each attempt, look in Wazuh at the web access log for web-srv. Ask:
   - Did anything stand out in the HTTP requests?
   - Could I write a rule that would have flagged it? (That's Phase 2, step 1.)
4. Write up one as a short detection note in `docs/incidents/`, redacted.

## When scenarios do get built

They will follow the same rules as the rest of the lab:

- **Quiet by design.** A scenario script prints only a neutral line like `done`.
  It never says which technique it ran, which account it targeted, or when - that
  would spoil the investigation.
- **Answers on request only**, through a `hint` / `reveal` command and a
  git-ignored spoilers file that records the run's random seed.
- **Randomised**, so the same scenario doesn't play out identically twice.
- **Lab-only targets.** Scenarios run VM-to-VM inside `10.0.1.0/24`, never against
  anything outside the lab.

These will likely plug into the exercise runner in `lab/exercises/` rather than
living as standalone scripts. That integration is tracked with the exercises work,
not here.

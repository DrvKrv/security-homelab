# F4 Prevent: Map your detections to MITRE ATT&CK and publish a coverage map

> Needs the detection add-ons (unit 4). Nothing to stage. `./run.sh start`
> assigns one technique to test for real, and it changes each time.

## The concept
**MITRE ATT&CK** is a public catalogue of how attackers behave, organised as
**tactics** (the goal: get in, stay in, move around, steal) and **techniques**
(the method), each with an id like `T1110` and sub-techniques like `T1110.001`.
Security teams use it as a shared language: "we detect T1110.001" means the same
thing everywhere.

A **coverage map** is a table of techniques with an honest answer for each: do
we detect it, with what, and how do we know? The "how do we know" part matters
most. A technique only counts as covered if a test proved the detection fires.
Everything else is a hope, and the map should say so.

Gaps aren't failures. A map that shows "not covered yet" with a reason is far
more useful, and more believable in an interview, than one that claims
everything.

## Your mission
1. List every detection the lab has: the lab's own Wazuh rules, the rules you
   wrote in lessons, and the built-in rules the lessons rely on.
2. Tag each with its ATT&CK technique (and tactic). Use the ATT&CK website to
   check each id, not just the tag already in a rule.
3. For each, record how you know it works: a test in `lab/wazuh/tests/`, a
   lesson you staged, or "not proven yet".
4. Run your assigned Atomic Red Team test on win-srv (one test, then its
   cleanup). Did anything fire? Add the result to the map, covered or not.
5. Pick one gap and write down what you'd need to close it: a log source, a
   rule, or both.
6. Publish the map in the repo as `docs/detections/coverage-map.md`.

## The analyst workflow
1. Collect the rules: the lab's `local_rules.xml` files, your own rules, and the
   rule ids named in the lesson answer keys you've done.
2. For each, find the matching technique on attack.mitre.org.
3. Mark the evidence: test file, lesson, or none.
4. Run the assigned atomic as runbook 06, step 4 describes. Search Wazuh by time
   and by `agent.name: win-srv`.
5. Write the table, then a short "gaps and next steps" section.

## Predict before you run
For your assigned technique, will Wazuh alert on it with what the lab has today?
Write yes or no, and which rule or log source you expect, before running it.

## What good looks like
`docs/detections/coverage-map.md` with a table (technique id, name, tactic,
detection, evidence, status), the atomic test's result, and a gaps section,
written as you'd show it to a hiring manager. Redact per
`../../../../../../docs/publishing-checklist.md`.

## Hints
1. The lab's rules are in `lab/wazuh/manager/local_rules.xml` and `lab/stages/*/wazuh/local_rules.xml`; many already have a `<mitre>` tag.
2. Status values that stay honest: "tested" (a test or staged lesson proved it), "untested", "not covered".
3. On win-srv: `Invoke-AtomicTest <id> -ShowDetailsBrief`, then `-TestNumbers <n>`, then the same with `-Cleanup`.
4. The ATT&CK Navigator (mitre-attack.github.io/attack-navigator) can colour a matrix from your table for a screenshot.

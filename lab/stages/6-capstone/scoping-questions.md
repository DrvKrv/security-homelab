# Capstone scoping questions

Answer each with evidence, or write "unknown" and what would tell you. "Unknown"
is a fine answer early on; leaving the question out isn't.

## 1. Preparation (before, or as soon as you start)
- Which log sources are reaching Wazuh from each VM right now? Any agent
  disconnected or quiet?
- Are the clocks right? Compare each VM's time with the wazuh VM's.
- What does normal look like here: usual logins, usual admin activity, usual
  network connections? (Your baselines from earlier lessons.)
- Where will you keep your notes and evidence, and how will you keep them intact?

## 2. Detection and analysis

**Is it real?**
- What was the first sign? Alert, odd log line, or something a person noticed?
- Could it be explained by normal activity, an admin task, or your own testing?
  What evidence rules that in or out?

**Scope: what's touched?**
- Which machines show related activity? For each: first and last time.
- Which accounts are involved? Real, new, or made-up? Any with admin rights?
- Which network paths were used: which machine talked to which, on which port?
- Did anything change on disk: new accounts, new files, changed settings,
  scheduled tasks, services, firewall rules?
- Is it still going on?

**Timeline**
- What's the earliest event you can tie to it? Is there anything before that
  you haven't looked for yet?
- For each step, what was the result: attempted, succeeded, or blocked?
- Where are the gaps, and which log would fill each one?

**Severity**
- What could the actor do with what they had at the worst point?
- Which business functions or data were at risk? (Use the asset inventory's
  criticality.)

## 3. Containment, eradication and recovery
- What stops it spreading right now, with the least disruption? (Block a
  source, disable an account, isolate a machine.)
- What could containment break? Who needs to know first?
- What did the actor leave behind, everywhere you found them? How do you know
  you found it all?
- How do you prove each fix: a check, a verify script, a re-scan, a re-run test?
- When is it safe to call it recovered?

## 4. Post-incident
- Root cause: which weakness made the first step possible?
- Which detections fired, which should have and didn't, and why?
- How long from first event to detection? Detection to containment?
- What three changes would most reduce the chance or impact next time?
- What would you do differently in the investigation itself?

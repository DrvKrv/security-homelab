# D1 Spot: Read Wazuh's vulnerability findings for one VM

> Runs on the current lab. Nothing to stage. `./run.sh start` gives you the VM
> and the severity to begin with, and they change each time, so you can repeat
> this lesson on a different VM.

## The concept
A **vulnerability** is a known flaw in a piece of software that an attacker could
use. When one is made public it gets a **CVE** id (for example `CVE-2024-6387`)
so everyone can talk about the same flaw. Each CVE gets a **CVSS** score from 0
to 10, and a severity word: Low, Medium, High or Critical.

You don't have to look up every program by hand. The Wazuh agent on each VM sends
the manager a list of the installed software and versions (the **inventory**).
The manager compares that list with public vulnerability data and reports every
match. That's **vulnerability detection**.

Reading the results well is a skill of its own. A finding is a **claim**: "this
package, at this version, matches this CVE". Before you act on it you check three
things: the package really is installed at that version, the inventory is
recent, and you understand what the finding says.

## Your mission
For the VM in your assignment:
1. How many findings are there at each severity?
2. Which **three packages** have the most findings?
3. Pick **three findings**, starting at your assigned severity. For each, record:
   the CVE id, the package and installed version, the severity and score Wazuh
   shows, and when it was detected.
4. Check one of them on the VM itself: is that package really installed at that
   version?
5. When did this VM last send its software inventory? Could the findings be stale?

## The analyst workflow
1. Open the vulnerability detection page in the Wazuh dashboard (runbook 05, step
   2, says where). Choose your VM at the top.
2. Read the dashboard tab first for the counts, then the inventory tab for the
   rows.
3. Filter the inventory by severity. Sort or group by package name.
4. Open a finding and read every field, not just the id.
5. On the VM, ask the package manager for the installed version of one package.
6. Find the inventory scan time for the VM, or force a fresh one (runbook 05,
   step 1) and compare.

## Predict before you run
Which of the three VMs do you expect to have the most findings, and why? Think
about what each one runs and how it was installed.

## What good looks like
A short case file (`../../../../case-file-template.md`) or a few rows in
`../../../../../../docs/cve-research-worksheet.md` with: the severity counts, the
top three packages, three findings with their fields, your on-the-VM check, and
the inventory's age. A screenshot of the dashboard counts for the write-up.

## Hints
1. Dashboard menu: Threat intelligence > Vulnerability Detection; pick the agent at the top of the page.
2. In the Inventory tab, filter with `vulnerability.severity:High` (or Critical) and look at `package.name` and `package.version`.
3. Linux: `dpkg-query -W <package>`. Windows: Settings > Apps, or `Get-HotFix` for updates. The versions should match the finding.
4. The agent groups re-send the inventory hourly and at agent start; restart the agent to force one, then wait 10 to 15 minutes.

# D2 Explain: Rank a list of findings by real risk, not just score

> Runs on the current lab. Nothing to stage. `./run.sh start` gives you the mix
> of findings to use and a twist, which changes each time.

## The concept
No team patches everything at once. There's always a queue, and the order
matters: the flaw you fix first should be the one most likely to hurt you.

The CVSS score is a starting point, not the answer. It describes the flaw in
general, not your network. Real risk also depends on:
- **Exploitation:** is it being used in real attacks (CISA KEV)? How likely is
  that soon (EPSS)?
- **Exposure:** is the vulnerable part running? Who can reach it: the internet,
  the internal network, or only someone already logged in?
- **Asset value:** what breaks or leaks if this machine is taken over? In this
  lab, losing the SIEM blinds you, and win-srv is your only way in.
- **The fix:** is one available? Does applying it need a reboot or downtime?

A good ranking has a **reason per row** that someone else could check. "It's a
9.8" is not a reason. "It's a 9.8 in a library that nothing running uses" is.

## Your mission
1. Pick six findings as your assignment says (D1 shows you where).
2. For each, gather: CVE, VM, package, CVSS, KEV yes or no, EPSS, exposure, the
   VM's importance, and whether a fix exists.
3. Write down your ranking **rules** first, in two to four lines, before you
   rank.
4. Rank the six from "fix first" to "fix last", one sentence of reasoning each.
5. Name one finding where your rank and its CVSS order disagree, and explain why.
6. Apply the twist. What moves, and why?

## The analyst workflow
1. Export or copy the six findings from the Wazuh vulnerability inventory.
2. Fill the gaps per finding: KEV, EPSS, the vendor's fixed version.
3. Check exposure on each VM: what's listening, and what the Azure firewall (NSG)
   lets in (`lab/azure/README.md`).
4. Write your rules, then sort.
5. Re-read the twist and re-rank. Only move what the twist really changes.

## Predict before you run
Of your six, which do you expect to land first before you've researched any of
them? Write it down and compare at the end.

## What good looks like
The prioritisation table from runbook 05, step 4 (`../../../../../runbooks/05-vulnerability-remediation.md`),
filled for six findings, your ranking rules above it, the CVSS-versus-rank
example, and the twist re-ranking. This becomes the core of a remediation
ticket (`../../../../../../docs/tickets/TEMPLATE-remediation-ticket.md`).

## Hints
1. Runbook 05, step 4, has a simple order to start from: KEV first, then exposed High/Critical, then unexposed, then the rest.
2. Exposure is per VM: only win-srv has a public IP, and only for RDP from your own address; everything else is lab-only.
3. Ties are broken by asset value and by how easy the fix is; write that rule down too.
4. For the twist, change one input (exposure, asset value, downtime, or KEV) and re-sort only by that.

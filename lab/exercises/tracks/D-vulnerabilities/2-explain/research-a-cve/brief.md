# D2 Explain: Research one CVE: CVSS, NVD record, does it really apply here?

> Runs on the current lab. Nothing to stage. `./run.sh start` assigns a VM and
> a way of choosing the finding, and they change each time.

## The concept
D1 was about reading what the scanner says. This lesson is about **checking** it.
A finding is a claim that a package at a certain version matches a CVE. To turn
it into a decision you need the full story:

- **The record.** The **NVD** (National Vulnerability Database, nvd.nist.gov) has
  each CVE's description, its **CVSS** score and the **vector**: a short code that
  says *how* the flaw can be used. `AV:N` means over the network, `AV:L` only by
  someone already on the machine. `PR:N` means no login needed. `UI:N` means no
  one has to click anything.
- **The vendor's view.** Ubuntu and Microsoft publish their own page per CVE.
  Linux distributions often fix a flaw **without changing the main version
  number** (called **backporting**). So a version that *looks* old can already be
  fixed, and a scanner that compares version numbers can be wrong. The vendor
  page says which exact package version contains the fix.
- **The real world.** Is anyone actually using this flaw in attacks? CISA's
  **Known Exploited Vulnerabilities (KEV)** catalog lists the ones that are.
  **EPSS** estimates how likely exploitation is in the next 30 days.
- **Your lab.** Is the vulnerable part even running, and can anyone reach it?

The answer to "does it really apply here?" is one of: **yes**, **no** (already
fixed, or the vulnerable part isn't present), or **yes, but** (present, but not
reachable or not usable the way the vector needs).

## Your mission
For the finding your assignment picks:
1. What is the flaw, in one plain sentence?
2. The CVSS score, its version (3.1 or 4.0) and the vector. What does the vector
   say an attacker needs?
3. What does the vendor say? Which package version (or update) fixes it, and is
   your VM on that version or later?
4. Is it in CISA KEV? What is its EPSS score?
5. In this lab, is the vulnerable part running, and who can reach it?
6. Your verdict: applies, doesn't apply, or applies-but. Then a priority, with a
   one-sentence reason.

## The analyst workflow
1. Copy the finding's CVE id, package and installed version from Wazuh.
2. Read the NVD page. Write the description in your own words, and decode the
   vector piece by piece.
3. Open the vendor page for the same CVE. Find your OS version's row and the fixed
   version. Compare it with what's installed on the VM.
4. Search the KEV catalog and look up EPSS.
5. On the VM, check whether the component is in use: is a process running it,
   is a port open for it?
6. Fill a row of `../../../../../../docs/cve-research-worksheet.md`.

## Predict before you run
If NVD gives a CVE 9.8 and your VM shows a version number below the "fixed in"
version on NVD, is the VM definitely vulnerable? What would you check first?

## What good looks like
A completed row in the CVE research worksheet, plus a short paragraph: the flaw,
the vector decoded, the vendor's fixed version against yours, KEV and EPSS, the
exposure in the lab, and your verdict and priority. Every claim has a link.

## Hints
1. NVD: `https://nvd.nist.gov/vuln/detail/<CVE-ID>`. Ubuntu: `https://ubuntu.com/security/<CVE-ID>`. Microsoft: `msrc.microsoft.com/update-guide`.
2. On Ubuntu, compare versions with `dpkg --compare-versions <installed> ge <fixed> && echo fixed`.
3. KEV: search the CVE at `cisa.gov/known-exploited-vulnerabilities-catalog`. EPSS: `first.org/epss`.
4. Exposure: `sudo ss -tlnp` (Linux) or `Get-NetTCPConnection -State Listen` (Windows), plus the NSG rules in `lab/azure/README.md`.

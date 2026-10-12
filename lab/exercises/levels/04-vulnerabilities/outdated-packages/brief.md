# Level 4 — Vulnerabilities: find, prioritise and fix

> Run this **on linux-srv** so `verify` can measure your patching directly.

## The concept
Your lab deliberately leaves automatic patching **off**, so the server drifts out
of date — just like a neglected real machine. Vulnerability management is the
loop that deals with that:

**inventory → identify → prioritise → remediate → verify.**

The vocabulary matters and is core Security+:
- **CVE** (Common Vulnerabilities and Exposures): the public ID for a specific
  flaw, e.g. `CVE-2024-6387`.
- **CVSS** (Common Vulnerability Scoring System): a 0–10 severity score. Higher =
  worse, but score isn't the whole story (see below).
- **NVD** (National Vulnerability Database, nvd.nist.gov): the US government
  catalogue where you look up a CVE's details and CVSS.

The judgment you're building: you can't patch everything at once, so you
**prioritise**. Severity (CVSS) matters, but so does **exposure** (is the
service reachable?), **exploitability** (is there a known exploit in the wild?),
and **business impact**. A medium-severity bug on an internet-facing service can
outrank a critical one on something nothing can reach.

## Your mission
1. **Inventory** the installed software and versions on linux-srv, and see what's
   upgradable.
2. **Identify** vulnerabilities: use Wazuh's vulnerability detector and/or look
   up notable package versions on the NVD.
3. **Prioritise** 2–3 to fix first, and write down *why* (severity + exposure +
   exploitability), not just the top CVSS number.
4. **Remediate** them (patch/upgrade).
5. **Verify** the fix, and run `./run.sh verify 4/outdated-packages`.

## The analyst workflow
1. Capture a version baseline. `./run.sh stage 4/outdated-packages` does this
   and saves it as `~/lab-evidence/packages-before-*.txt`. After patching, run
   `bash linux/capture-package-versions.sh after` from the `lab/` folder so you
   have a before/after pair.
2. Refresh package data (`sudo apt update`) and see what's upgradable.
3. Pick a couple of real CVEs tied to what's installed; record CVE id, CVSS, and
   your reasoning in `../../../docs/cve-research-worksheet.md`.
4. Patch the ones you chose, re-check versions, and let the verifier confirm the
   upgradable count dropped.

## Predict before you run
If two vulnerabilities have CVSS 9.8 and 6.5, is the 9.8 always the one to fix
first? Name one situation where you'd fix the 6.5 first.

## What good looks like
A filled CVE worksheet (CVE, CVSS, affected service, your priority + reasoning),
a remediation ticket (`../../../docs/tickets/`), and a passing verifier showing
the upgradable count fell. The *reasoning* is the portfolio gold, more than the
patch itself.

## Hints
1. `sudo apt update` then `apt list --upgradable` is your fastest "what's outdated" list. The staging script also saves a fuller version inventory.
2. Wazuh has a vulnerability detector that maps installed packages to CVEs — check its dashboard; it does a lot of the CVE-matching for you.
3. On the NVD, search the package + version. Record the CVE id and the CVSS base score, and read the "attack vector" — network-exploitable is worse than local-only.
4. To verify, re-check `apt list --upgradable` after patching. The automated verifier records a baseline on its first run, so run it once *before* patching and again *after*.

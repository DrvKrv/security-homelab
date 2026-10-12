# Answer key — find, prioritise and fix outdated software

There's no single "right" set of CVEs here — it depends on what's installed on
your linux-srv and when you run it. What matters is that you ran the **loop**
correctly and can defend your **prioritisation**.

## The loop, done well
1. **Inventory:** `sudo apt update` then `apt list --upgradable`; the staging
   script also saved a fuller version snapshot.
2. **Identify:** Wazuh's vulnerability detector maps your installed packages to
   CVEs. Cross-check notable ones on the NVD (nvd.nist.gov) for the CVSS base
   score and the attack vector.
3. **Prioritise:** rank by **severity × exposure × exploitability**, not CVSS
   alone. Record each as: CVE id, CVSS, service, is-it-reachable, is-there-a-known
   -exploit, your rank, your reason.
4. **Remediate:** `sudo apt install --only-upgrade <pkg>` for targeted fixes, or
   `sudo apt upgrade` to patch broadly.
5. **Verify:** re-check `apt list --upgradable`; the verifier confirms the count
   dropped.

## The prioritisation question (the real lesson)
CVSS 9.8 is **not** automatically first. You'd fix a CVSS 6.5 first when, for
example:
- the 6.5 is on an **internet-facing / reachable** service and the 9.8 is on
  something nothing can reach (exposure wins);
- the 6.5 has a **known exploit in the wild** and the 9.8 is only theoretical
  (exploitability wins);
- the 9.8 requires local access an attacker doesn't have, while the 6.5 is
  remotely triggerable (attack vector wins).

Severity tells you how bad it *could* be; exposure and exploitability tell you how
*likely* it is. Risk = both.

## Why it matters / interview answer
"I ran the full vulnerability-management loop on the server: inventoried versions,
used Wazuh's detector plus the NVD to identify CVEs, then prioritised by severity
*and* exposure *and* exploitability rather than CVSS alone — I can explain why I
fixed a medium before a critical in one case. I patched the top items and verified
the upgradable count dropped, and I logged it all in a CVE worksheet and a
remediation ticket." That demonstrates judgment, not just running `apt upgrade`.

## Portfolio artefacts
- `docs/cve-research-worksheet.md` — your CVE/CVSS table with reasoning.
- `docs/tickets/` — a remediation ticket per fix (what, why, before/after,
  verification).

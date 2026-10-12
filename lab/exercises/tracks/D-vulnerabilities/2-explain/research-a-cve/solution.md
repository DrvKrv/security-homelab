# Answer key: Research one CVE: CVSS, NVD record, does it really apply here?

Your finding is your own, so this key gives the method and a **worked example**.
The example is a well-known OpenSSH flaw, chosen to show the method. It is not a
claim about your VMs: check your own.

## A complete answer has
1. One plain sentence on the flaw.
2. Score, CVSS version, vector, and each vector part decoded.
3. Vendor's fixed version against the installed version, compared properly
   (`dpkg --compare-versions` on Ubuntu, the KB number on Windows).
4. KEV yes or no, and the EPSS score with the date you looked.
5. Whether the part is running and who can reach it (lab subnet only, or the
   internet).
6. Verdict and priority with a reason, using the ordering in runbook 05, step 4.

## Worked example: CVE-2024-6387 ("regreSSHion")
- **Flaw:** a timing bug (a race condition) in OpenSSH's server, during login,
  that could let someone run code as root without logging in.
- **NVD:** CVSS 3.1 base score 8.1 (High), vector
  `AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:H`. Over the network (`AV:N`), no login
  (`PR:N`), no user action (`UI:N`), but **`AC:H`**: hard to pull off. Total
  damage if it works (`C:H/I:H/A:H`). Note how `AC:H` keeps it below 9.
- **Vendor:** Ubuntu 24.04 ships OpenSSH 9.6p1. NVD lists 9.6p1 inside the
  affected range, so a check that only reads "9.6p1" says "vulnerable". But
  Ubuntu **backported** the fix into a newer `1:9.6p1-3ubuntu13.x` package
  revision. The Ubuntu CVE page names the exact fixed version for noble. A VM
  with that package or later is fixed, even though it still says 9.6p1.
- **KEV / EPSS:** look them up yourself on the day; both change over time.
- **Exposure in this lab:** sshd runs on linux-srv and wazuh, reachable only from
  the lab subnet (no public IP). An attacker would first need a foothold inside.
- **Verdict:** if the installed package is older than Ubuntu's fixed version:
  applies, but only reachable from inside the lab. Priority High: network,
  no-login, root impact, on a service that is running. Patch in this cycle. If
  it's at or above the fixed version: **does not apply**, and the finding is a
  false positive or a stale inventory.

**Predict:** no. A version below NVD's "fixed in" can still be fixed by the
vendor's backport. Check the vendor's page and compare the full package version
first.

## Common mistakes
- Copying the score without the vector, so nobody knows why it's high.
- Comparing only the upstream version (9.6p1) and missing the backported fix.
- Treating KEV absence as "safe": it means "not known to be exploited yet".
- Skipping exposure: a 9.8 in a library no running program uses ranks lower than
  a 7.5 in a service listening on the network.

## Interview talking point
"I researched a scanner finding end to end: decoded the CVSS vector to see what
an attacker would need, checked the vendor's advisory because distributions
backport fixes without changing the main version, looked at KEV and EPSS for
real-world exploitation, and checked whether the component was running and
reachable. That let me say whether the finding really applied, instead of
patching by score alone."

# Remediation Ticket: `TODO short title, e.g. "Upgrade OpenSSL on linux-srv"`

Copy this file to `REM-YYYY-NNN-short-name.md` for each fix.

| Field | Value |
|---|---|
| **Ticket ID** | REM-`YYYY`-`NNN` |
| **Opened** | `YYYY-MM-DD` |
| **Priority** | P1 / P2 / P3 / P4 (see scale below) |
| **Status** | Open / In progress / Fixed, pending verification / Verified / Risk accepted |
| **Asset(s)** | `TODO` (from [asset inventory](../asset-inventory.md)) |
| **Source** | Wazuh vulnerability detection / incident [IR-YYYY-NNN](../incidents/) / manual review |
| **Related CVE(s)** | [CVE-YYYY-NNNNN](https://nvd.nist.gov/vuln/detail/CVE-YYYY-NNNNN) |
| **CVSS** | `TODO score` (v3.1 or v4.0, state which) · vector `TODO` |
| **Assigned to** | KT |
| **Due** | `YYYY-MM-DD` |

## Problem

What is wrong, where, and why it matters. Include the affected version.

## Evidence

- Screenshot or command output showing the vulnerable state
  (e.g. `dpkg -l | grep <package>`, Wazuh vulnerability dashboard).
- Link: `../evidence/REM-YYYY-NNN-before.png`

## Risk if not fixed

What an attacker could do, and how exposed the asset is (internet-facing?
reachable only inside the lab? requires local access?).

## Remediation plan

1. Take a VM snapshot (rollback point).
2. `TODO` exact steps (e.g. `sudo apt update && sudo apt install --only-upgrade <package>`).
3. `TODO` restart service / reboot if required.

**Rollback:** revert to the snapshot taken in step 1.

## Verification

How the fix was proven, with evidence:

- [ ] New version confirmed: `TODO command and output`
- [ ] Wazuh vulnerability scan no longer reports the CVE
- [ ] Service still works (e.g. SSH login succeeds)
- Link: `../evidence/REM-YYYY-NNN-after.png`

## Closure notes

Date verified, anything left over, or reason for risk acceptance.

---

### Priority scale

| Priority | When to use | Target time to fix |
|---|---|---|
| P1 | CVSS 9.0+ **or** listed in CISA KEV, and reachable | 48 hours |
| P2 | CVSS 7.0 to 8.9, or reachable from other hosts | 7 days |
| P3 | CVSS 4.0 to 6.9 | 30 days |
| P4 | CVSS below 4.0, or requires local access with low impact | Next maintenance window |

Target times are lab policy, modeled on common industry practice; see
[security policy](../security-policy.md).

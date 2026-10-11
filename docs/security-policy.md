# Information Security Policy (Lab Organization)

**Organization:** fictional company modeled by this homelab
**Owner:** KT · **Version:** 0.1 (draft) · **Effective:** `TODO YYYY-MM-DD` · **Review:** annually or after a major incident

## 1. Purpose and scope

This policy sets minimum security requirements for every system on the lab
network listed in the [asset inventory](asset-inventory.md): servers,
workstations and the SIEM. It applies to anyone with an account on those systems.

## 2. Acceptable use

- Lab systems are used only for authorized work and security exercises.
- Security testing (scanning, password attacks, exploitation) is permitted
  **only** against lab assets, **only** by authorized staff, and only within a
  scheduled exercise. Testing any system outside the lab is prohibited.

## 3. Accounts and access control

- Each person uses their own named account; shared accounts are not allowed.
- Administrative rights are granted only to separate admin accounts, never to
  the day-to-day user account (least privilege).
- Accounts are removed or disabled the same day access is no longer needed.
- Creation of accounts and changes to privileged groups are logged and reviewed.

## 4. Authentication

- Passwords are at least 14 characters and are not reused across systems.
- Accounts lock after `TODO 5` failed attempts within `TODO 15` minutes
  (Windows account lockout policy).
- SSH access to Linux servers uses key-based authentication; password login
  and direct `root` login over SSH are disabled.
- Credentials are stored in a password manager, never in documents, scripts or
  source code repositories.

## 5. Logging and monitoring

- All servers and workstations run the Wazuh agent and send security events to
  the SIEM.
- At minimum, the following are collected: logon success/failure, account and
  group changes, privilege use, firewall blocks, and SSH authentication.
- Alerts of level `TODO 10` or higher are reviewed the same day; all alerts are
  reviewed weekly.
- Logs are retained for `TODO 90` days in the lab (real organizations often
  require a year or more).

## 6. Vulnerability and patch management

- Systems are scanned for vulnerabilities continuously by Wazuh and reviewed weekly.
- Findings are prioritized by CVSS score, known exploitation (CISA KEV) and
  exposure, and fixed within these targets:

| Priority | Criteria | Fix within |
|---|---|---|
| P1 | Critical (CVSS 9.0+) or actively exploited, and reachable | 48 hours |
| P2 | High (7.0 to 8.9) | 7 days |
| P3 | Medium (4.0 to 6.9) | 30 days |
| P4 | Low (below 4.0) | Next maintenance window |

- A snapshot or backup is taken before any change, and every fix is verified.
- Exceptions require a documented risk acceptance in the remediation ticket.

## 7. Network security

- Lab systems run in a dedicated Azure virtual network. Only the jump host has
  a public IP address; all other systems are reachable only from inside the VNet.
- Inbound access from the internet is limited to Remote Desktop on the jump
  host, from approved source IP addresses only, enforced by Network Security Groups.
- Host firewalls are enabled on all systems; only required ports are open
  (see [network diagram](network-diagram.md)).
- Cloud spending is monitored with budget alerts, and idle systems are
  deallocated or shut down automatically.

## 8. Incident response

- Suspected incidents are recorded using the
  [incident report template](incidents/TEMPLATE-incident-report.md).
- The analyst identifies affected accounts and hosts, contains the issue,
  documents the timeline, and opens remediation tickets for root causes.

## 9. Compliance

Deviations from this policy must be documented. This policy is reviewed after
each incident and updated with lessons learned.

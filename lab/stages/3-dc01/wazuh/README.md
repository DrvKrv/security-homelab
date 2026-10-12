# Wazuh setup for dc01

The domain controller is where identity events live. Once dc01 is logging to
Wazuh, you can see logons, account creation, group changes and Kerberos activity
for the whole domain in one place.

## 1. Install the agent on dc01

Same as win-srv. On the Wazuh dashboard: **Agents > Deploy new agent**, Windows,
server `10.0.1.10`, group `windows` (the existing group already collects the
Security event log - see `lab/wazuh/agent-groups/windows/agent.conf`). Run the
command it gives you in an elevated PowerShell on dc01, then:

```powershell
Start-Service WazuhSvc
```

Because dc01 joins the existing `windows` group, it inherits that group's config,
so the Security channel is already collected. No new group is required.

## 2. Turn on the right auditing

A domain controller needs a few audit subcategories on so the interesting events
are actually written. In an elevated PowerShell on dc01:

```powershell
auditpol /set /subcategory:"Logon"                  /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Authentication Service"     /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations"  /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management"             /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management"           /success:enable /failure:enable
```

(The existing `lab/windows/Enable-AuditPolicy.ps1` covers Logon and account
management for a member server; the Kerberos lines above are the DC additions.)

## 3. Events worth knowing

| Event ID | Meaning | Why you care |
|---|---|---|
| 4624 / 4625 | Logon success / failure | Password spraying shows as many 4625s across accounts |
| 4720 | User account created | A new account appearing out of hours is a classic sign |
| 4728 / 4732 | Member added to a (global/local) group | Someone being added to an admin group |
| 4768 | Kerberos TGT requested | Baseline of who authenticates |
| 4769 | Kerberos service ticket requested | Unusual patterns can indicate Kerberoasting |

Wazuh already tags many of these with their MITRE ATT&CK technique. Your Phase 2
job is to build and tune rules on top of them, and to map each to ATT&CK in your
write-ups.

> **Predict first:** password spraying tries one password against many accounts.
> Which event ID piles up, and on how many different accounts? Would a rule that
> fires on "N failures for one account" catch it? What about "N accounts each with
> one failure from the same source"?

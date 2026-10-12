# Answer key: Disable a compromised domain account and find everywhere it logged in

## What happened
The demo domain account (`demo.user`) had two failed sign-ins and then a
successful one from win-srv to a file share on dc01, and that File Explorer
window kept a session open. You contain it, scope it and close it.

## The evidence
| Where | Id | What it shows |
|---|---|---|
| dc01 | 4625 (Wazuh 60122) | The two failed attempts before the sign-in |
| dc01 | 4624 | The successful logon: logon type 3 (network), `ipAddress` 10.0.1.20 |
| dc01 | 4776 | The DC's NTLM check (by-IP connections use NTLM), if credential-validation auditing is on |
| dc01 | 4768 | Kerberos ticket granted, with the source in `ipAddress` (by-name sign-ins) |
| dc01 | 4725 | **Your** action: account disabled |
| dc01 | 4724 | **Your** action: password reset |
| dc01 | 4625 after the fix | The failed attempt that proves the disable |

## Answers to the mission
1. **Disable and reset** (elevated PowerShell on dc01):
   ```powershell
   Disable-ADAccount -Identity demo.user
   Set-ADAccountPassword -Identity demo.user -Reset -NewPassword (Read-Host -AsSecureString "New password")
   Get-ADUser demo.user -Properties Enabled, PasswordLastSet | Format-List Name, Enabled, PasswordLastSet
   ```
   `Enabled : False` and a fresh `PasswordLastSet` confirm both.
2. **Every logon:** with no agent filter, 4624 for `demo.user` shows only
   **dc01**, logon type 3, from **10.0.1.20** (win-srv). If you joined win-srv to
   the domain and signed in there too, it appears as a second machine. Kerberos
   events may show the address as `::ffff:10.0.1.20`; that is the same machine.
3. **Open sessions:**
   ```powershell
   Get-SmbSession | Where-Object ClientUserName -like '*demo.user*'
   Get-SmbSession | Where-Object ClientUserName -like '*demo.user*' | Close-SmbSession -Force
   ```
   On any machine with a desktop session, `quser` lists sessions and `logoff <id>` ends one.
4. **Proof:** sign in again from win-srv with the **new** password. It fails, and
   dc01 logs a 4625 whose `subStatus` is **0xC0000072** (account disabled), which
   proves the disable rather than a typo. Wazuh shows alerts for 4725 and 4724;
   record their rule ids in your case file.

The predict answer: disable first, because every minute of scoping is a minute
the attacker can still act. You lose nothing, since disabling keeps the account
and its history. Deleting it would destroy evidence.

## MITRE ATT&CK
T1078.002 Valid Accounts: Domain Accounts. The attacker signs in with a real
domain account; containment removes that access.

## Common mistakes
- Deleting the account instead of disabling it, which destroys evidence.
- Scoping with the dc01 agent filter still on and missing other machines.
- Disabling but not resetting: re-enabling later gives the stolen password back
  its power.
- Forgetting open sessions. Already-issued tickets and sessions are not recalled
  the instant you disable.

## Interview talking point
"For a compromised domain account I disable first, then scope. Disabling keeps
the evidence and stops new logons. I then pulled every 4624 for the account
across all agents, plus the DC's ticket and NTLM events, to list each machine and
source. I closed the open sessions, reset the password, and proved it with a
failed sign-in whose status code says 'account disabled', next to the 4725 and
4724 that record my own actions."

# Answer key: Windows failed logons

## What happened
On **win-srv**, `Simulate-FailedLogons.ps1` generated a run of failed sign-ins
against a test account, imitating someone guessing a Windows password. Each
failure is a Windows Security **event 4625**. If the run exceeds the account
lockout threshold, Windows also logs a **4740** (account locked out).

## The events you should have found
| Windows Event ID | Meaning |
|---|---|
| 4625 | **An account failed to log on** (one per attempt) |
| 4740 | **A user account was locked out** (if the threshold was crossed) |

Key fields inside a 4625:
- **`TargetUserName`** — the account being attacked.
- **`LogonType`** — how the logon was attempted (2 = interactive, 3 = network,
  10 = RemoteInteractive/RDP).
- **Failure Status / Sub Status** — the reason code (e.g. wrong password vs.
  unknown user; `0xC000006A` = bad password, `0xC0000064` = no such user).

Wazuh maps these into its Windows ruleset (the `win_authentication_failed`
family), so you'll see them as alerts, not just raw events.

## Why it matters / interview answer
"A brute-force looks the same on Windows as on Linux — a burst of failed logins
against one account — but Windows logs it as event 4625 with rich fields:
the target account, the logon type, and a status code for *why* it failed. The
run tripped the account-lockout policy (4740), which is the host defending
itself. The lesson is that detection depends on auditing being enabled first."

## Detect it faster next time
- A rule alerting on N × 4625 for one account in a short window (the Windows
  equivalent of the SSH correlation rule).
- Watching **4740** directly: a lockout is always worth a look.
- Tracking 4625 **by LogonType 10 (RDP)** specifically, since internet-facing
  RDP is a favourite target.

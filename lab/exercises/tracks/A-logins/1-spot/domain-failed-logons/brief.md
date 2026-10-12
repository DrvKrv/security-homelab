# A1 Spot: Failed domain logons

> Needs dc01 (unit 7). Read it any time; stage it once dc01 is built.

## The concept
In a **domain**, accounts do not live on each computer. They live in one central
directory, **Active Directory**, held by a **domain controller** (DC). In this lab
the DC is dc01 and the domain is `acme.lab`. When someone signs in to any
domain-joined machine with a domain account, that machine asks the DC to check
the password.

That makes the DC the best single place to watch for bad passwords: it is asked
about logons from every machine in the domain. Windows can check a password two
ways. **Kerberos** is the modern default and uses tickets. **NTLM** is older and
is still used when, for example, you connect by IP address instead of by name.
Each leaves its own kind of record on the DC, alongside the usual "logon failed"
event on the machine being signed in to.

A defender cares because a domain account opens many doors at once. A few
failures can be a typo; a run of them is the first sign someone is guessing.

## Your mission
After a few failed sign-ins with a domain account, find them on dc01 and record:
1. The **Windows event** and the **Wazuh alert** for a failed logon.
2. **Which account** was tried, in which domain, and **how many** times.
3. The **logon type** and the **failure reason** Windows gives.
4. The **source**: the workstation name or network address the attempt came from.
5. Whether the DC also logged a **Kerberos or NTLM** check for the same attempts.

## The analyst workflow
1. Make the activity using the staging note: at most 3 wrong passwords, so the
   account does not lock.
2. In **Threat Hunting > Events**, filter to the dc01 agent, last 15 minutes.
3. Find the logon-failure events and expand one. Windows puts the detail under
   `data.win.eventdata`: read the target account, logon type, status codes,
   workstation name and source network address.
4. Look at the other events from the same seconds. Some are about the password
   check itself rather than the logon. Note their event ids.
5. Line the events up by time and count them per account.

## Predict before you run
You connect from win-srv to dc01 by IP address. Which of the two password-check
methods do you expect the DC to use, and why does connecting by IP matter?

## What good looks like
A case file (`../../../../case-file-template.md`) with a small table of the
failed attempts (time, account, logon type, reason, source), the Windows event
id and Wazuh rule id for each kind of event you saw, and one sentence on why the
DC is the place to watch domain logons.

## Hints
1. Filter dc01's events on Windows event id 4625, "an account failed to log on".
2. Wazuh labels a single 4625 as rule 60122; repeated failures can roll up into 60204.
3. Read `targetUserName`, `targetDomainName`, `logonType` (3 = network, 10 = remote desktop), `status`/`subStatus` and `ipAddress`.
4. Search the same seconds for 4776 (NTLM check) or 4771 (Kerberos pre-auth failed): they are the DC verifying the password.

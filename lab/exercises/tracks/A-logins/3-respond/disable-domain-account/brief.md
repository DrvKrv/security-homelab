# A3 Respond: Disable a compromised domain account and find everywhere it logged in

> Needs dc01 (unit 7). Read it any time; stage it once dc01 is built. You run the
> fix in an elevated PowerShell on dc01.

## The concept
A domain account works on every machine in the domain, so a stolen domain
password is a bigger problem than a stolen local one. Response has three parts,
and the order matters:
1. **Contain:** stop the account working anywhere, right now. **Disabling** an
   account blocks new sign-ins without deleting it, so its history and group
   memberships stay intact as evidence.
2. **Scope:** find **every** place the account signed in, so you know which
   machines to check next. A domain logon leaves traces both on the machine that
   was used and on the domain controller that approved it.
3. **Close the loop:** disabling stops new sign-ins, but sessions that are
   already open can keep working for a while. End them, and reset the password so
   re-enabling the account later does not hand the attacker their way back in.

Every one of these actions is itself logged. Your own response becomes part of
the timeline, which is how an auditor checks what you did and when.

## Your mission
Treat the demo account as compromised, then:
1. **Disable** it, and **reset** its password to one only you know.
2. **List every logon** by the account: which machines, from which source
   addresses, and the first and last time.
3. **End any open session** the account still has.
4. **Prove** it: the account shows as disabled, a sign-in attempt now fails with
   a reason that says so, and your own actions appear in Wazuh.

## The analyst workflow
1. Contain first: disable the account before you start scoping. Note the time.
2. In Wazuh, search for successful logons by the account. Remove the agent filter
   so you see **all** machines, not only dc01.
3. On dc01, also look at the domain controller's ticket events for the account:
   they show the source address of each sign-in the DC approved.
4. Build a small table: machine, source address, logon type, first and last time.
5. On each machine in your table, look for sessions the account still holds and
   close them.
6. Reset the password, then try to sign in once more from win-srv to prove the
   account is shut.

## Predict before you run
Disabling is one click. Why disable first and scope second, instead of
investigating quietly and disabling at the end? What could you lose either way?

## What good looks like
A case file (`../../../../case-file-template.md`) with: the time you disabled the
account, a table of every logon (machine, source, type, times), the sessions you
closed, the failed sign-in that proves the disable, and the Wazuh events for your
own disable and reset.

## Hints
1. In an elevated PowerShell on dc01: `Disable-ADAccount -Identity demo.user`, then `Get-ADUser demo.user -Properties Enabled`.
2. In Wazuh, drop the agent filter and search `data.win.eventdata.targetUserName: demo.user and data.win.system.eventID: 4624`.
3. On dc01, event 4768 (Kerberos ticket granted) and 4776 (NTLM check) list the account with the source address.
4. `Get-SmbSession` on dc01 shows open file-share sessions; `Close-SmbSession` ends one, and events 4725 and 4724 record your fix.

# B1 Spot: a new Windows admin account

## The concept
The Windows version of the "new admin account" persistence tactic. On Windows,
administrative power comes from membership in the **Administrators** group (and,
on a domain, groups like Domain Admins). Creating a user and adding it to
Administrators is a textbook way to keep access.

Each step is its own Windows Security event: account **created**, account
**enabled**, **password set**, and **added to a security-enabled group**.
Reading these in order reconstructs exactly what the attacker did — Windows
account-management auditing is quite detailed once it's turned on.

## Your mission
A new account appeared on **win-srv**. From Wazuh, determine:
1. **What account** was created, and **when**.
2. That it was **added to Administrators** (local admin rights).
3. The supporting steps (enabled, password set).
4. **Who** made the change (the `SubjectUserName` in the events).

## The analyst workflow
1. **Threat Hunting > Events**, last 15 minutes, win-srv agent.
2. Find the account-management events. They come as a little sequence — line them
   up by timestamp to tell the story.
3. For the group-change event, confirm the **target group is Administrators**,
   not some harmless group.
4. Note the **`SubjectUserName`** — the account that *performed* the change. In a
   real incident that tells you which existing account was already compromised.

## Predict before you run
Which is more suspicious on its own: "a new user was created", or "an existing
user was added to Administrators"? Why might the second matter more?

## What good looks like
A case file with the new account name, the ordered sequence of events with IDs
and timestamps, confirmation it reached Administrators, and the acting account.
The account stays until you clean it up in B3/windows-backdoor-user.

## Hints
1. This is a family of event IDs, not one. Start from the Wazuh search this exercise gave you and sort by time.
2. 4720 = account created, 4722 = enabled, 4724 = password reset. Read them as steps in one action.
3. The important one is the group change: 4732 (added to a *local* security group) or 4728/4756 (domain groups). Confirm the group name is **Administrators**.
4. Every event has a `SubjectUserName` (who did it) and a `TargetUserName` (who it was done to). Don't confuse them — the subject is your lead on the compromised account.

# B2 Explain: Unexpected sudo rights: who granted them, when

> Runs on the current lab. Staging runs on linux-srv; the investigation is in
> Wazuh and on linux-srv.

## The concept
On Linux, **sudo** lets an ordinary account run commands as root, the all-powerful
administrator. Who may use sudo, and for which commands, is a **privilege**:
handing it out is the same as making someone an admin, even if only for "one
command". Many single programs can be turned into a full root shell by someone
who knows how, so a defender treats any sudo right as an admin right.

There is more than one way to grant sudo: membership of an admin group, or a
rule in sudo's own configuration files. Each way leaves different evidence, and
your alerts may cover some ways better than others. Part of the job is finding
out which way was used and whether your alerts noticed.

In an **Explain** lesson, you build the full story from the evidence: **what**
right was granted, to **whom**, **how**, **who** made the change, and **when**.
Every answer should point to a log line or a file.

## Your mission
1. Which account on linux-srv gained sudo rights, and **exactly what** may it run?
   Does it need its own password to do so?
2. **How** was the right granted? Name the file and the line.
3. **Who** made the change, and from which session? **When**, to the second?
4. Which of the lab's alerts recorded the change, and which stayed quiet? Explain
   why, and how loud the evidence was.
5. Would you remove the right straight away, or confirm with someone first? Say
   what you would check.

## The analyst workflow
1. Start from what the account can do now: sudo can list any account's rights.
2. Find where that right comes from: check every place sudo reads its rules
   from, and compare with what a fresh Azure Ubuntu VM normally has.
3. In Wazuh, look at linux-srv's file-integrity events around that time. Read the
   path and the change it shows.
4. Then look for the **command** that made the change: sudo writes a log line
   for every command it runs, naming the account that ran it and the command.
5. Tie the session to a login: which account was logged in at that time, and from
   which machine?
6. Put it all on one timeline, in order.

## Predict before you run
If someone gave an account admin rights on linux-srv, which alerts would you
expect to see, and at what level? Write the list down, then compare it with what
you actually find.

## What good looks like
A case file (`../../../../case-file-template.md`) with a timeline from login to
grant, exactly how the right was granted, the account that made the change and
from where, which alerts fired and which didn't (and why), and a sentence on how
you'd detect this better.

## Hints
1. On linux-srv, `sudo -l -U <account>` lists an account's sudo rights; try the lab test account first.
2. `ls -l /etc/sudoers.d/` and compare with a fresh VM: the cloud-init file and `README` are normal, anything else needs a reason.
3. In Wazuh, search linux-srv for `rule.groups: syscheck` and a `syscheck.path` under `/etc/sudoers.d`; the diff shows the line.
4. Search linux-srv for `rule.id: 5402` near that time; `data.srcuser` and `data.command` show who ran what. Then find that account's SSH login (5715).

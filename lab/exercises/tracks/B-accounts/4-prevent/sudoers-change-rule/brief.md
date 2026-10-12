# B4 Prevent: Alert on changes to sudo rights, then test it

> Runs on the current lab. Staging runs on linux-srv; you write the rule and run
> `./run.sh verify` on the wazuh VM. Do B2 first if you haven't: this lesson
> fixes what it showed you.

## The concept
A detection rule is a promise: "if this happens, someone will know". In B2 you
saw that the lab's loud admin-rights alert only covers one way of handing out
sudo. Here you close that gap by writing your own rule, and you **prove** it
works, because an untested rule is only a hope.

Wazuh already watches the files that control sudo (file integrity monitoring,
set up in the lab's linux agent config). When one of them is added, changed or
deleted, Wazuh raises a low-level built-in alert. Your rule builds on top of
those: when the file is a sudo file, raise the level so it can't be missed.
Building on an existing rule is called **chaining**.

Two good habits come with every rule you write:
- **Use your own id range** (the lab uses 100300-100399 for yours) and a clear
  description, so anyone reading an alert knows what it means.
- **Test it for real**, and keep the proof.

## Your mission
1. Write a rule on the wazuh VM that raises any added, changed or deleted file
   under `/etc/sudoers` or `/etc/sudoers.d/` to level 10 or more.
2. Give it an id from 100300-100399, a description that names the file, and an
   ATT&CK tag.
3. Check the ruleset loads before restarting the manager.
4. Stage the lesson on linux-srv and show your rule firing in Wazuh.
5. Run `./run.sh verify B4/sudoers-change-rule` on the wazuh VM.
6. Name one way someone could still grant admin rights on linux-srv that your
   rule would miss.

## The analyst workflow
1. Find the built-in file-integrity rules that fire when a file is added,
   changed or deleted. Note their ids.
2. Write your rule to chain from those, and to match only paths that start with
   the sudo files.
3. Validate the ruleset, then restart the manager.
4. Stage, wait a minute, and search for your rule id.
5. Add the rule and what it fired on to your case file.

## Predict before you run
Your rule chains from the built-in "file added" alert. When it fires, will
Wazuh show **both** alerts for that one change, or only yours? Why?

## What good looks like
A case file (`../../../../case-file-template.md`) with: your rule's XML, the
`-t` output, the alert it raised (with time, level and path), a passing verify,
and the gap you named in step 6.

## Hints
1. The built-in file-integrity rules are 550 (changed), 553 (deleted) and 554 (added); chain with `<if_sid>550,553,554</if_sid>`.
2. Match the path with `<field name="file">^/etc/sudoers</field>`: it covers the file and the folder.
3. Put it inside a `<group name="lab,">` block in `/var/ossec/etc/rules/local_rules.xml`, then `sudo /var/ossec/bin/wazuh-analysisd -t`.
4. After staging, search `rule.id: <your id>` in Wazuh; the alert's `syscheck.path` shows which file.

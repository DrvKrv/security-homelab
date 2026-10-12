# A3 Respond: Block the attacking source and prove it's blocked

> Runs on the current lab. Staging runs on the wazuh VM; you make the fix on
> linux-srv, and `./run.sh verify` runs there too. Keep your SSH session from
> win-srv to linux-srv open the whole time.

## The concept
Finding an attack is only half the job. Once you know **where it comes from**,
the quickest way to stop it is to **contain** it: tell the target's firewall to
drop that one source. Containment buys you time to investigate properly. It is
not the final fix (the final fix is usually making the attack pointless, which
the other lesson in this box covers).

linux-srv's firewall is **UFW** (Uncomplicated Firewall). UFW reads its rules
**top to bottom and stops at the first rule that matches**. So *where* you put
a rule matters as much as what it says. A "deny" placed below an "allow" that
already matches the same traffic does nothing at all.

A block must also be **narrow**. Block too much and you cut off your own access:
you reach linux-srv from win-srv, so a rule that drops every SSH connection
would lock you out too.

Last, a defender doesn't stop at "I added a rule". You **prove** it works: the
traffic is now refused, and the logs show the refusals.

## Your mission
1. Stage the incident, then find the SSH attack in Wazuh and identify its source.
2. On linux-srv, add a UFW rule that blocks **only that source**, and only what
   it needs to block.
3. Make sure your rule is in a position where UFW actually uses it.
4. Prove it: stage the attack again and show that it can't even reach SSH now.
   Then show what Wazuh records instead.
5. Run `./run.sh verify A3/block-ssh-source` on linux-srv.
6. Write down when you would remove this block, and why it shouldn't stay forever.

## The analyst workflow
1. In Wazuh, open the SSH alerts and read the source address field. Confirm
   every attempt comes from the same place, and work out which lab VM that is
   (`../../../../../../docs/asset-inventory.md`).
2. On linux-srv, list the current rules **with their numbers**, so you can see
   their order.
3. Add your rule so it sits above any rule that would otherwise let the source
   in, and so it leaves evidence in the logs each time it drops something. Read
   the rule list again to check the order.
4. From the source machine, test port 22 with a quick connection check, before
   and after your rule.
5. Stage again. Staging will report that it failed this time; read the reason it
   gives. Then look in Wazuh for what the firewall logged.

## Predict before you run
After your rule is in place, will Wazuh show **more** SSH login failures, the
**same**, or **none**? And what kind of alert will you see instead?

## What good looks like
A case file (`../../../../case-file-template.md`) with: the source you blocked and
how you identified it, your exact UFW command, the numbered rule list showing the
order, the before-and-after connection test, the new alerts after the block, a
passing verify, and one sentence on when the block should come off.

## Hints
1. In Wazuh, the source of each SSH alert is in `data.srcip`. Check it's the same on every alert, then look it up in the asset inventory.
2. On linux-srv, `sudo ufw status numbered` shows the rules in the order UFW reads them. Note where the lab-subnet SSH rule sits.
3. A plain `ufw deny` goes at the bottom, below the subnet allow, and logs nothing. Use `sudo ufw insert 1 deny log from <source> to any port 22 proto tcp`.
4. From the source VM, `nc -z -w 3 10.0.1.30 22 && echo open || echo blocked` is your proof. After staging again, search `rule.id: 100100` for linux-srv.

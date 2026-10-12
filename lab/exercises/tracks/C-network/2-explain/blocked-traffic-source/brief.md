# C2 Explain: Where did the blocked traffic come from, and did anything get through?

> Runs on the current lab. You investigate in Wazuh, and on the lab VMs from
> win-srv.

## The concept
In C1 you found firewall blocks and listed the ports. An analyst's next two
questions are harder:

**Where did it really come from?** An address is not an answer. You turn it into
a machine, and then you ask what was happening **on** that machine at that time.
When the source is inside your own network, that matters a lot: either it's a
legitimate tool, or one of your own machines is already compromised and is now
looking around. Following the trail from the target back to the source is called
**pivoting**.

**Did anything get through?** A firewall log only lists what the firewall
**refused**. Connections it **allowed** aren't in that log at all. So "the
firewall log shows only blocks" does not mean "nothing got in". To answer the
question you need other evidence: the logs of the services that were allowed, and
what the target machine says about its connections.

## Your mission
1. Which machine sent the blocked traffic? Prove the address belongs to it.
2. On that machine, what was going on at that time? Which account was logged in,
   and from where?
3. Did that source make **any** connection that the firewall allowed? To which
   service, and what happened next?
4. Is there any sign of a successful login from that source, before, during or
   after?
5. Your verdict: harmless, suspicious, or an incident? Say what would change your
   mind.

## The analyst workflow
1. Collect the firewall-block alerts for linux-srv in the window. Note the
   source, the ports and the first and last time.
2. Map the address to a VM with the asset inventory
   (`../../../../../../docs/asset-inventory.md`).
3. Pivot: in Wazuh, switch to that VM's own events for the same window. Look for
   logins and admin commands.
4. Back on linux-srv, check which ports its firewall allows. Then look for any
   events from the same source on those services, not just blocks.
5. Widen the window a little on both sides, so you don't miss something that
   happened just before or just after.
6. Write the timeline, then the verdict.

## Predict before you run
If a connection from the same source reached an **allowed** port, would it appear
among the firewall-block alerts? Where else would it leave a trace?

## What good looks like
A case file (`../../../../case-file-template.md`) with: the source address and
the evidence that ties it to a VM, the pivot to that VM (who was logged in, from
where), a list of what the firewall allows and whether the source used it, the
login verdict with evidence, and your overall verdict.

## Hints
1. Search linux-srv for `rule.id: (100100 or 100101)`; `data.srcip` is the source and `data.dstport` the port.
2. The asset inventory maps the address to a VM. In Wazuh, change the agent filter to that VM (the manager's own agent is named after it).
3. On that VM, look for `rule.groups: authentication_success` in the window: who was logged in, and from which address?
4. linux-srv allows SSH from the lab. Search linux-srv for `rule.groups: sshd` with that source address in the same window, then look for an authentication success.

# C1 Spot: firewall-blocked connections

## The concept
A **host firewall** (UFW on Ubuntu) decides which incoming connections a machine
accepts. linux-srv only needs a couple of services, so everything else is
**denied by default** and each denied attempt is logged as a `[UFW BLOCK]` line.

Blocked connections are interesting because they show someone (or something)
*probing* for services that aren't offered — databases, remote desktop, file
sharing. A few blocks might be harmless; a pattern of them to many different
ports is the early shape of reconnaissance. Learning to read "deny by default,
and log the denials" is core to both Network+ and Sec+.

## Your mission
Several connections to **linux-srv** were just refused by its firewall. From
Wazuh, determine:
1. **Which ports/services** were attempted.
2. **Which machine** made the attempts.
3. Whether this looks like a few stray probes or a deliberate sweep.

## The analyst workflow
1. **Threat Hunting > Events**, last 15 minutes. Search the lab's UFW-block rule.
2. For each hit, read `data.dstport` (the service they wanted) and `data.srcip`
   (who was asking). Build a little table of port → service.
3. Think about volume and spread: how many *different* ports, from *one* source,
   in *how long*? That shape is what separates a probe from a scan (C2 and
   the port-scan exercise go deeper on this).

## Predict before you run
The firewall blocks by refusing to answer. From the attacker's side, what does a
blocked port *look* like compared to an open one? (Hint: you tested this idea
earlier with `nc`.)

## What good looks like
A case file listing each blocked port and its service, the single source IP, and
your read on intent. Note this stays *below* the port-scan correlation threshold
on purpose — recognising "suspicious but under the alarm line" is a real skill.

## Hints
1. The lab ships a custom rule specifically for UFW blocks because the built-in decoder misses Ubuntu 24.04's journald format. Search that one rule id.
2. Each alert names one destination port. Map the ports to services (e.g. 3306 = MySQL, 3389 = RDP, 445 = SMB).
3. All the attempts share one source IP — your "attacker" VM. Confirm it's the same source across every block.
4. Count the distinct ports. This exercise deliberately stays under the port-scan threshold, so you'll see individual blocks but *not* a "port scan" correlation alert. That contrast is the lesson.

# C1 Spot: a port scan

## The concept
A **port scan** is how an attacker (or a security tool) maps a target: it knocks
on many TCP ports quickly to learn which services are listening. `nmap` is the
standard tool. A scan is usually the *first* active step of an attack — figure
out the attack surface, then pick a target.

The signature is volume: *lots* of connection attempts to *many* ports from
*one* source in a *short* time. A single blocked port is noise; dozens in a few
seconds is a scan, and that's what a correlation rule is built to catch. This is
the exercise where you see the threshold from the blocked-connections exercise
actually trip.

## Your mission
linux-srv was just scanned. From Wazuh, determine:
1. That a **port scan** occurred (the correlation alert, not just the blocks).
2. **Which machine** ran the scan.
3. **What the scan found** — which ports on linux-srv are actually open, and what
   services/versions are behind them.

## The analyst workflow
1. **Threat Hunting > Events**, last 15 minutes. Expect a flood of individual
   firewall-block alerts, and look for the single correlation alert that fires
   once the volume crosses a threshold. Note both rule IDs yourself.
2. Confirm the source IP and that it's a single host.
3. The scan also did **version detection**. Service names and versions are gold:
   they're what you look up against CVEs in D2 and D3. Note any software versions
   the scan reported.

## Predict before you run
The blocked-connections exercise fired six blocks and *no* scan alert. This one
fires a scan alert. What changed? (Think about what crosses the threshold.)

## What good looks like
A case file with: the scan's source IP, the fact that the correlation rule
fired (and roughly how many blocks it took), the list of open ports/services on
linux-srv, and any software versions seen. Those versions feed directly into the
vulnerability exercise.

## Hints
1. Two rule ids matter: the per-port block (100100) and the correlation alert that fires once many blocks arrive quickly (100102). Find the second — it's the actual "scan detected".
2. The source is one of your lab VMs running nmap. Confirm one source IP across the whole burst.
3. The scan output is also saved on the wazuh VM under `~/lab-evidence/nmap-*`. Open the `-versions.txt` file to read service versions — don't just rely on the dashboard.
4. "What's open" and "what's blocked" are different questions. Most ports were blocked; a small number answered. The ones that answered are linux-srv's real attack surface.

# C2 Explain: triage the port scan

## The concept
A port scan on its own is just reconnaissance — nobody got in. But it answers the
attacker's first question: *what can I reach?* Your investigation answers the
same question from the defender's side, and turns it into a risk statement: which
services are exposed, are any of them things that **shouldn't** be reachable, and
what should change.

This is where detection meets **attack-surface management**. You're not just
noting "a scan happened"; you're using what the scan found to make the box safer.

## Your mission
A scan hit **linux-srv**. Determine:
1. The scan's **source, timing, and shape** (how many ports, how fast).
2. **What answered** — the open ports and the service/version behind each.
3. For each open service: **should it be reachable at all**, and from where?
4. A short **risk read** and one or two concrete hardening recommendations.

## The analyst workflow
1. Confirm the scan in Wazuh (blocks + the correlation alert) and its source.
2. Pull the **version-detection output** from `~/lab-evidence/nmap-*-versions.txt`
   on the wazuh VM. This is your inventory of exposed services.
3. For each open port, ask the exposure question: SSH from the whole subnet may
   be fine; a database or an admin panel reachable from other hosts usually isn't.
4. Turn it into recommendations: close what isn't needed, restrict what is (host
   firewall / NSG), and note any versions to research for CVEs (D2 and D3).

## Predict before you run
Of the services you expect to be open on a fresh Ubuntu server, which *one* is
almost always legitimate, and which would make you suspicious if you saw it
listening?

## What good looks like
A case file with the scan details, an inventory table (port → service → version →
should-it-be-open?), a risk read, and 1–2 hardening actions. Flag any version
strings for the vulnerability exercise.

## Hints
1. The dashboard proves the scan; the saved nmap `-versions.txt` file is where the real detail lives. Use both.
2. Build a table: for every open port, record the service name and version nmap reported.
3. The exposure question is per-service: "who legitimately needs to reach this, and does the current firewall match that?" SSH yes; a database listening to the whole subnet, probably not.
4. You don't fix anything here — but note the version strings. They're the raw material for the CVE research in D2.

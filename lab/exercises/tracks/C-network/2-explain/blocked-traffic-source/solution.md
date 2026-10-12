# Answer key: Where did the blocked traffic come from, and did anything get through?

## What happened
The staging script on the wazuh VM tried six services on linux-srv that its
firewall doesn't allow (telnet 23, SMB 445, MS SQL 1433, MySQL 3306, RDP 3389 and
a web admin port 8080), a few seconds apart. On some runs the same VM also opened
one ordinary SSH connection to linux-srv, before or after the blocked attempts.
SSH is allowed from the lab subnet, so that connection reached sshd, but it
offered no key and no password, so it never logged in. Whether it happened this
run is under *This run's details* at the end of `reveal`.

## The evidence
- **Firewall blocks:** 100100 (or 100101) on linux-srv, one per port, all with
  `data.srcip` = 10.0.1.10. Six blocks stays below the port-scan rule (100102).
- **Source:** 10.0.1.10 is `wazuh` in the asset inventory and in Azure.
- **The pivot:** on the wazuh VM's own events (agent `wazuh`, the manager's local
  agent), an SSH authentication success (5715) for your admin account from
  10.0.1.20 (win-srv) shortly before the blocks. That's you, logging in to run
  the staging. In a real case, this is where you'd learn which person or process
  was behind the traffic.
- **Allowed traffic:** linux-srv's UFW allows only SSH (port 22) from the lab
  subnet (`sudo ufw status`). The firewall log can't show allowed connections.
  - If the SSH connection happened this run, linux-srv's sshd recorded it: a
    low-level sshd event from 10.0.1.10 (on this lab's key-only linux-srv a real
    user rejected this way shows up as 5762, "connection reset", level 4). Note
    the rule id you see. There's **no** authentication success (5715) from
    10.0.1.10.
  - If it didn't, there are no sshd events from 10.0.1.10 in the window at all.

## Answers to the mission
1. 10.0.1.10, the wazuh VM.
2. Your admin account was logged in over SSH from win-srv (10.0.1.20).
3. Depends on the run: either nothing got through, or one SSH connection reached
   sshd and was turned away without logging in.
4. No authentication success from 10.0.1.10 at any point.
5. In the lab: explained, it's the staging run by an admin. As a real event:
   **suspicious** and worth a ticket. One internal server trying databases,
   SMB and RDP on another is a classic sign of a compromised host looking around.
   It would become an incident if you found a login success from it, a
   login to the source VM you couldn't account for, or the same pattern against
   other machines.

## MITRE ATT&CK
T1046 Network Service Discovery: trying several services to see which answer.

## Common mistakes
- Treating "only blocks in the firewall log" as proof nothing got through.
- Stopping at the IP address instead of pivoting to the machine behind it.
- Searching the source only during the blocks, and missing a connection just
  before or after.
- Calling the low-level sshd event a login. It's a connection, not a session.

## Interview talking point
"I traced firewall blocks on one server to another internal machine, then pivoted
to that machine's own logs to see who was logged in at the time. Because a
firewall log only records refusals, I checked the allowed service's logs
separately and found whether the same source had reached SSH, and that it never
authenticated. My verdict separated 'what the firewall stopped' from 'what got
through', with evidence for each."

# Answer key: Prove the split network works: web-srv can't reach dc01

## What a complete answer shows
1. **The design, as a table:**

   | From | To | Port | Rule | Why |
   |---|---|---|---|---|
   | internal (10.0.1.0/24) | DMZ | 80, 3000 | allow | staff use the website and training app |
   | win-srv (10.0.1.20) | DMZ | 22 | allow | admin access from the jump host only |
   | DMZ | wazuh (10.0.1.10) | 1514-1515 | allow | the Wazuh agent reports in |
   | DMZ | internal | anything else | deny | stop lateral movement |
   | other VNet traffic | DMZ | anything | deny | nothing else needs in |

2. **From web-srv:** `check-segmentation.sh` passes. Only wazuh 1514 and 1515
   connect. dc01 (88, 389, 445, 3389, 5985), win-srv (3389, 445), linux-srv (22)
   and wazuh's SSH and dashboard (22, 443) are blocked.
3. **From win-srv:** `Test-NetConnection` to the same dc01 ports says `True`, so
   the services are up and the firewall is what blocks web-srv.
4. **Business still works:** `http://10.0.2.40/` and port 3000 load in win-srv's
   browser, and web-srv's agent shows Active in Wazuh.
5. **Effective security rules** on web-srv's network card list the DMZ subnet
   rules (100, 110, 4000 in; 100, 4000 out) above Azure's defaults.
6. **Break one layer (predict answer):** with the DMZ's `Deny-dmz-to-internal`
   gone, web-srv's outbound traffic leaves the DMZ, but the internal subnet's
   `Deny-from-dmz` (priority 4000) refuses it on arrival. So the checker still
   passes. Delete the internal rule instead, and the DMZ rule still blocks it.
   Both layers must fail before web-srv reaches dc01. That's **defence in
   depth**.

## MITRE ATT&CK
T1021 Remote Services, the usual way of moving from one machine to the next
(SMB, RDP, WinRM). Segmentation is the matching mitigation, M1030 Network
Segmentation.

## Common mistakes
- Trusting "blocked" without proving the target was on.
- Testing from win-srv only. The attacker's view is from web-srv.
- A Deny with a priority number above 65000, or none at all: Azure's built-in
  allow-inside-the-VNet rule then wins.
- Denying the agent ports too, so web-srv silently stops reporting to Wazuh.
  Losing visibility of the riskiest machine is worse than the risk you closed.

## Interview talking point
"I segmented my Azure lab into a DMZ and an internal zone with NSGs written in
Terraform, two layers deep. I proved it from the web server's side with a
connection test, proved the blocked services were up from the internal side,
and checked Azure's effective rules. Removing either layer on its own didn't
open a path, which showed the defence in depth was real."

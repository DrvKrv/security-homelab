# Answer key — firewall-blocked connections

## What happened
The **wazuh VM** tried to connect to six services on **linux-srv** that its UFW
firewall does not allow. Each was dropped and logged as `[UFW BLOCK]`:

| Port | Service |
|---|---|
| 23 | telnet |
| 445 | SMB (Windows file sharing) |
| 1433 | Microsoft SQL Server |
| 3306 | MySQL |
| 3389 | RDP (remote desktop) |
| 8080 | web admin |

- **Source:** wazuh VM, 10.0.1.10.
- **Target:** linux-srv, 10.0.1.30.
- **Alert:** lab rule **100100** ("Lab: UFW firewall blocked a connection"), once
  per port — six alerts.

## The key teaching point
Six ports is **below** the port-scan correlation threshold, so you see six
individual block alerts but **no** "possible port scan" alert (100102). That's
intentional. Real environments are full of activity that is suspicious but not
yet alarm-worthy; an analyst has to notice the pattern before a rule does.

## Why it matters / interview answer
"linux-srv denies everything by default and logs the denials. I saw blocked
attempts to telnet, SMB, both SQL databases, RDP and a web-admin port, all from
a single internal host. None of those services should be contacted on that box,
so the pattern reads as service discovery — someone looking for a way in. It
stayed under the port-scan threshold, so I flagged it manually." Shows you
understand default-deny and the gap between a single event and a correlated
alert.

## Detect it faster next time
- A dashboard of blocks-by-source-IP surfaces a probing host quickly.
- Lowering the correlation threshold catches slower, stealthier sweeps — at the
  cost of more noise. Tuning that trade-off is the analyst's call.

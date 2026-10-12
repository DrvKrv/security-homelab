# Answer key — a port scan

## What happened
The **wazuh VM** ran an `nmap` SYN scan of the top 1000 TCP ports against
**linux-srv (10.0.1.30)**, then version-detected whatever answered. The scan
generated a rapid burst of UFW blocks, which tripped the lab's port-scan
correlation rule.

## The alerts you should have found
| Rule | Meaning |
|---|---|
| 100100 | Lab: UFW blocked a connection (fires many times, fast) |
| 100102 | **Lab: possible port scan** (correlation — fires once the burst crosses the threshold) |

- **Source (scanner):** wazuh VM, 10.0.1.10.
- **Target:** linux-srv, 10.0.1.30.
- **The threshold:** unlike the blocked-connections exercise (6 ports, no scan
  alert), a top-1000 scan produces far more blocks far faster, so 100102 fires.

## What the scan found
The open ports are whatever linux-srv actually runs (SSH on 22 at minimum, plus
anything `setup-linux-srv.sh` installed). Read the exact list and versions from
the saved `~/lab-evidence/nmap-<target>-*-versions.txt` file on the wazuh VM.
Record each `service / version` pair — you'll research those in Level 4.

## Why it matters / interview answer
"I detected a port scan: a single internal host generated a rapid burst of
firewall blocks across many ports, which tripped the correlation rule. I
confirmed the source, then pivoted to what the scan actually discovered — the
open ports and service versions on the target — because that tells me the real
attack surface and gives me the version strings to check for known
vulnerabilities." That connects detection to the next step, which is what
separates an analyst from an alert-reader.

## Detect it faster next time
- The correlation rule already does the heavy lifting; tuning its threshold
  trades sensitivity against noise.
- Blocking the source after a scan is detected (active response) stops the
  attacker from acting on what they learned.

# Answer key: triage the port scan

## The findings
- **Source:** wazuh VM (10.0.1.10). **Target:** linux-srv (10.0.1.30).
- **Shape:** a top-1000 TCP SYN scan — a rapid burst of attempts that tripped the
  lab's block rule (100100) many times and the port-scan correlation rule
  (100102) once.
- **No compromise:** a scan only enumerates; it doesn't log in. Nothing here is a
  breach.

## Exposure inventory
Fill from your own `-versions.txt`; the shape looks like:

| Port | Service | Version | Should it be open? |
|---|---|---|---|
| 22 | OpenSSH | (version string) | Yes — but restrict source to admin hosts |
| (others `setup-linux-srv.sh` installed) | ... | ... | Case-by-case |

The honest inventory is "whatever answered". On a minimal server that's often
just SSH; anything beyond that you justify or close.

## Risk read + recommendations
- **SSH (22):** legitimate, but it shouldn't be reachable from *every* host.
  Restrict the source to the admin machine(s) via UFW / NSG.
- **Any database or admin port:** usually should **not** be reachable across the
  subnet. Bind it to localhost or firewall it to only the hosts that need it.
- **Version strings:** record them — outdated versions are the CVE work in D2 and D3.

## Why it matters / interview answer
"I treated the scan as an attack-surface review. The scan itself wasn't a breach,
but it told me exactly what an attacker on the network can reach. I inventoried
the open services and versions, asked for each whether it should be reachable and
from where, and recommended tightening SSH to admin hosts and closing/limiting
anything else. The version strings also became my CVE research list." That turns
a passive alert into concrete risk reduction — which is the job.

## The broader lesson
Every open port is a promise you have to keep secure. The cheapest security win
is usually *not running* or *not exposing* a service in the first place
(reducing attack surface), which is why "should this even be open?" is the first
question, before "is this version patched?".

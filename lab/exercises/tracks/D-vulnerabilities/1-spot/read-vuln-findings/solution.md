# Answer key: Read Wazuh's vulnerability findings for one VM

There's no single right answer: the findings depend on your VM and the day you
look. This key shows what a complete answer contains and how to check it.

## What a good answer looks like
1. **Counts:** four numbers (Critical, High, Medium, Low) from the dashboard tab
   for the right agent, with the date you read them. Screenshot it.
2. **Top packages:** from the inventory, grouped by `package.name`. On Ubuntu
   VMs this is usually the kernel (`linux-*` packages) and big shared libraries.
   On win-srv, findings are tied to the Windows version and missing updates, so
   one "package" (the OS) can carry many CVEs.
3. **Three findings,** each with: `vulnerability.id` (the CVE), `package.name`,
   `package.version`, `vulnerability.severity`, `vulnerability.score.base`, and
   `vulnerability.detected_at`. If a field is empty, say so; don't fill it in.
4. **On-the-VM check:** for Linux, `dpkg-query -W <package>` prints the same
   version as the finding. For Windows, the build number and the installed
   updates (`Get-HotFix`, or Settings > Windows Update > Update history).
   If they don't match, the inventory is out of date or the finding is wrong.
5. **Freshness:** the agent's last inventory scan time. The lab's agent groups
   send it every hour and when the agent starts. After patching, findings stay
   until the next inventory, which is why runbook 05 restarts the agent.

**Predict:** the Ubuntu VMs often show more findings than you'd expect because
every installed package is checked, used or not. The wazuh VM runs the most
software. Fresh Azure images are usually a few weeks behind, and automatic
patching is off in this lab on purpose.

## Common mistakes
- Reading the counts for the wrong agent (the page remembers the last one picked).
- Treating the CVE count as "how hacked we are". It's a list of claims to check.
- Copying the severity without the score or the version, so nobody can check it later.
- Ignoring the inventory's age.

## Interview talking point
"I used Wazuh's vulnerability detection to review one server: I read the severity
counts, identified the packages carrying most of the risk, and checked a finding
against the installed version on the machine itself before trusting it. I also
checked how fresh the software inventory was, because a stale inventory shows
fixed vulnerabilities as still open."

## Next
D2 takes one of these findings and researches it properly.

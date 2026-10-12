# Capstone evidence checklist

Evidence is only useful if someone else can trust it. For every item: collect
it, write down where it came from and when, keep an untouched copy, and record
its hash in your [evidence log](evidence-log-template.md).

## Ground rules
- **UTC everywhere.** Note any source that logs local time and convert it.
- **Collect before you change.** Export logs before containment steps that could
  rotate or delete them (restarting services, deleting accounts, reimaging).
- **Copies, not originals.** Work on a copy; keep the first copy read-only.
- **Hash it.** Linux: `sha256sum <file>`. Windows: `Get-FileHash <file>`. A hash
  proves later that the file hasn't changed since you collected it.
- **Minimum necessary.** Export the time window and hosts in scope, not everything.

## By source

### Wazuh (on the wazuh VM or the dashboard)
- [ ] Alerts for the window, every agent in scope: dashboard export to CSV, or
      `sudo zcat -f /var/ossec/logs/alerts/*/*/ossec-alerts-*.json*` filtered to
      the dates, plus today's `/var/ossec/logs/alerts/alerts.json`.
- [ ] Screenshots of the key alerts, with the search used visible.
- [ ] Agent status at the time (`sudo /var/ossec/bin/agent_control -l`): any
      agent disconnected during the window is a visibility gap.

### linux-srv (and web-srv)
- [ ] SSH and sudo: `sudo journalctl -u ssh --since "<start>" --until "<end>" -o short-iso`
      and `sudo journalctl _COMM=sudo --since ... -o short-iso`.
- [ ] Firewall: `sudo journalctl -k --since ... | grep 'UFW'` and `sudo ufw status numbered`.
- [ ] Accounts and rights: `getent passwd`, `getent group sudo`, `sudo ls -l /etc/sudoers.d/`.
- [ ] What's running and listening: `ps -eo user,pid,ppid,lstart,cmd`, `sudo ss -tlnp`.
- [ ] Persistence spots: `sudo systemctl list-units --type=service --state=running`,
      `sudo ls -la /etc/cron.* /var/spool/cron/crontabs`, `~/.ssh/authorized_keys` for each user.
- [ ] Suricata (if installed): `/var/log/suricata/eve.json` for the window.
- [ ] web-srv only: `/var/log/acme-web/access.log`, `/var/log/acme-web/error.log`,
      `/var/log/acme-portal/auth.log`.

### win-srv (and dc01)
- [ ] Security log events for the window: `.\Get-LabEvidence.ps1 -Minutes <n> -Csv`
      from `lab\windows` (saves to `C:\LabEvidence`).
- [ ] Sysmon (if installed): `Get-WinEvent -LogName Microsoft-Windows-Sysmon/Operational`
      filtered by time, exported with `Export-Csv`.
- [ ] Accounts and groups: `Get-LocalUser`, `Get-LocalGroupMember -SID S-1-5-32-544`
      (on dc01: `Get-ADGroupMember 'Domain Admins'`).
- [ ] Persistence spots: `Get-ScheduledTask | Where-Object State -ne Disabled`,
      `Get-Service | Where-Object Status -eq Running`, the Run keys under
      `HKLM:\Software\Microsoft\Windows\CurrentVersion\Run` and the same under HKCU.

### Azure
- [ ] Activity log for the window (portal: the resource group > Activity log >
      Download as CSV): who changed what in the cloud setup.
- [ ] NSG rules as they were (portal, or `terraform show` if the lab is in code).

## Before publishing anything
Run the [publishing checklist](../../../docs/publishing-checklist.md). Raw logs
stay out of the repo; redacted excerpts and screenshots go in `docs/evidence/`.

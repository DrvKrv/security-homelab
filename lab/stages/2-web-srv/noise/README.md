# Busy-office noise generator (placeholder)

**Not built yet - this is a documented placeholder.**

Later stages add a generator that makes the fake Acme staff *act* like people:
log into the portal, browse the site, occasionally mistype a password, come and
go on their own schedules. The point is to bury real attacks in realistic normal
activity, so finding them is a genuine skill (threat hunting), not just reading a
quiet log.

## Design (for when it's built)

- Each employee already has a **persona** in the generated roster (`early_bird`,
  `night_owl`, `typo_prone`, `heavy_file_user`, `rare_login`, ...). The generator
  will drive behaviour from that, with random timing jitter so no two days match.
- It uses the git-ignored `generated/lab-credentials.json` to log in as the fake
  staff (lab-only throwaway passwords, created at install).
- **Quiet by design**: it logs nothing that reveals a hidden attack, and it runs
  as a background service (a systemd timer) during "work hours" you set.
- It will include harmless-but-suspicious **red herrings** (a legit admin running a
  scan, someone back from holiday failing login a few times) so you practise
  telling benign from malicious.

Until then, you can create normal activity by hand: log into the portal as
`demo.user`, click around, and watch the events arrive in Wazuh.

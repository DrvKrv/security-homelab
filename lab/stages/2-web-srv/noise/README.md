# Busy-office noise generator (moved)

This used to be a placeholder. The generator is now **built**, as its own stage:

> **[`lab/stages/5-office/`](../../5-office/)** (unit 9)

It makes the fake Acme staff act like people, logging into this web-srv portal
and browsing the site on their own schedules, so real attacks have to be found
inside normal noise. It reuses the roster and throwaway passwords this stage's
installer created (`../generated/`), runs as a systemd timer during work hours,
and is quiet by design (red herrings go to a git-ignored spoilers folder).

Install it on web-srv after this stage is up:

```bash
cd ../../5-office
sudo bash office.sh install
```

See [`5-office/README.md`](../../5-office/README.md) for the full write-up.

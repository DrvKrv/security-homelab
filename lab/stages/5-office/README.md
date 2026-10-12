# Stage 5 / unit 9: the busy-office noise generator

A quiet lab is an easy lab. When the only thing in the SIEM is the attack you
staged, finding it is just reading. Real analysts work the opposite way: a
normal day is thousands of ordinary logins and page views, and the attack is a
handful of events hiding in the middle of them. Telling the two apart is a skill
called **threat hunting**, and you only practise it if there is noise to hunt in.

This stage makes the fake Acme staff **act like people**: they log into the
employee portal, browse the company site, sometimes fumble a password, and come
and go on schedules that fit their personality. It runs on its own in the
background, so once it is on, the company "lives" whenever the VMs are on.

It does **not** attack anything. Every request it makes is an ordinary portal
login or page view, exactly what a real employee's browser would send. It reuses
the accounts and throwaway passwords the web-srv installer already created
(`lab/stages/2-web-srv/generated/`); it writes no new attack code and needs no
new credentials.

> Needs web-srv (unit 6 / stage 2). Install and verify that stage first: the
> generator drives the portal it stands up, and reads the roster it generated.

## Install and run (on web-srv)

```bash
cd security-homelab/lab/stages/5-office
sudo bash office.sh install      # writes config.json, installs a systemd timer, starts it
bash  office.sh status           # is it installed and running?
bash  verify.sh                  # PASS/FAIL checks (makes no portal requests)
```

That is it. A systemd timer now fires one short "slice" of office activity every
~10 minutes. The generator decides for itself who is at work right now, so
nights and weekends stay quiet on their own.

Day-to-day:

```bash
sudo bash office.sh stop         # pause the office (go quiet before staging an incident)
sudo bash office.sh start        # resume it
bash  office.sh tick             # run one slice now, by hand (prints only "done")
```

## How it decides who does what

Each employee already has a **persona** in the generated roster. The generator
drives behaviour from it, with random timing so no two days match:

| Persona | Behaves like |
|---|---|
| `early_bird` | in early, gone by mid-afternoon |
| `night_owl` | starts late, active into the evening |
| `nine_to_five` | steady during standard hours |
| `typo_prone` | often mistypes the password once or twice before getting in |
| `heavy_file_user` | busier than most: many page views per visit |
| `rare_login` | barely logs in at all |
| `road_warrior` | irregular hours, the odd early or late sign-in |

In each tick the generator rolls which staff act, weighted by their persona and
the current hour, and has each do a small burst: a login (sometimes after a
mistyped password), a few page views, maybe a logout. All of it lands in the
portal's auth log and nginx's access log, the same sources Wazuh already reads.

## Red herrings: the actual lesson

Scattered into the noise are a few things that look suspicious but are not. Your
job as a hunter is to decide which is which, and being wrong about one is the
point, not a failure. The generator stages these occasionally:

| Red herring | What you see | Why it is benign |
|---|---|---|
| `returning_from_leave` | a rarely-seen account fails a few logins, then succeeds | someone back from holiday who forgot their password |
| `after_hours_admin` | an IT account signs in outside working hours | on-call work, which IT legitimately does |
| `service_account_burst` | one account views many pages very fast | a heavy user or a tab left refreshing |

Each of these resembles the start of a real attack (brute force, off-hours
access, automated activity). That is deliberate.

## Quiet by design

Staging never spoils the investigation, so:

- A tick prints only `done` (or an error if it could not start). It never says
  who acted, what they did, or which red herring fired.
- Red herrings are recorded only in the **git-ignored `spoilers/` folder**.
- Answers come when you ask for them:

```bash
bash office.sh hint      # one threat-hunting nudge at a time
bash office.sh reveal    # today's red herrings, so you can check your answer
```

## Randomised, so you can't memorise "normal"

`office.sh install` rolls a random **seed** (saved in `spoilers/office-seed.txt`,
never printed) so this lab's normal is its own. Timing is jittered every tick, so
rebuilding the lab, or just waiting a day, gives a different pattern. Real
analysts do learn their own company's normal (that is **baselining**, a skill you
are practising here); the randomness only stops you memorising one fixed day.

## How to practise with it

1. Let the office run for a few hours (or a day) with no attack staged, and build
   a picture of normal: logins per hour, which accounts are busy, which source
   addresses appear. The web-srv rules (`100400` portal success, `100401`
   failure, `100402` portal brute force) are your starting filters.
2. Now stage something real from another stage, for example a lesson from
   `lab/exercises/` or the capstone breach in `lab/stages/6-capstone/`, ideally
   while the office keeps running.
3. Hunt for it inside the noise. Write up what you found, and what you dismissed,
   in a case file.
4. Check yourself with `office.sh reveal` (for the red herrings) and the other
   stage's own `reveal` (for the real attack).

## Config

`office.sh install` copies [`config.example`](config.example) to `config.json`
(git-ignored). Edit it to change working hours, how busy the office is, how often
red herrings fire, or to point the generator at a portal on another host. See the
comments in that file.

## Rules this stage follows

- **No real secrets in the repo.** It uses only the throwaway, lab-only passwords
  the web-srv installer generated on the VM. `config.json`, `spoilers/` and the
  roster are all git-ignored.
- **Lab-only.** It talks to the Acme portal and site and nothing else. web-srv has
  no public IP, so the whole thing stays inside `10.0.1.0/24`.
- **No new attack code.** It performs ordinary logins and page views. The one
  thing that looks like an attack, a few failed logins before a success, is a
  real employee fumbling a password, recorded as a red herring.

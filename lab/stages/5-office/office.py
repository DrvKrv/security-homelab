#!/usr/bin/env python3
"""Busy-office noise generator for the Acme lab (unit 9).

This makes the fake Acme staff *act* like people: they log into the employee
portal, browse the company site, occasionally mistype a password, and come and
go on schedules that match their persona. The point is to bury real attacks in
realistic normal activity, so finding them is a genuine skill (threat hunting),
not just reading a quiet log.

It does NOT attack anything. Every request it makes is an ordinary portal login
or page view, the same thing a real employee's browser would do. It reuses the
accounts and throwaway passwords the web-srv installer already created; it writes
no new attack code and needs no new credentials.

How it runs
-----------
`office.sh install` drops a systemd timer that fires `office.py tick` every few
minutes. Each tick is one short "slice" of the working day: it rolls which staff
are active right now (weighted by persona and the time of day), has each do a
small, jittered burst of portal activity, and now and then stages a harmless but
suspicious red herring (someone back from leave fumbling their password, an IT
admin signing in after hours). Over a day this adds up to a believable pattern
that is different every day.

Quiet by design
---------------
A tick prints only `done` (or an error if it could not start). It never says who
acted, what they did, or which red herring fired: that would spoil the hunt.
Red herrings are recorded in the git-ignored `spoilers/` folder so you can check
your answer afterwards with `office.sh reveal`.

Usage (normally the timer calls this, not you):
    python3 office.py tick                # one slice of activity, prints "done"
    python3 office.py tick --dry-run      # compute a slice, make NO requests,
                                          # print a JSON summary (for verify/tests)
"""
import argparse
import json
import os
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from http.cookiejar import CookieJar
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPOILERS = HERE / "spoilers"

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
DEFAULTS = {
    # Where the portal and company site live. Defaults assume the generator runs
    # on web-srv itself and talks to the stack over the loopback. Point these at
    # a VM IP (e.g. http://10.0.1.40/portal) to drive the portal from elsewhere.
    "portal_url": "http://localhost/portal",
    "site_url": "http://localhost/",
    # The web-srv installer wrote the roster and throwaway passwords here.
    "generated_dir": str((HERE.parent / "2-web-srv" / "generated").resolve()),
    # Working hours, in the generator host's local time (24h clock).
    "work_start_hour": 8,
    "work_end_hour": 18,
    # Fraction of staff who might act in a single tick during peak hours.
    "peak_active_fraction": 0.35,
    # Base chance per active tick that one red herring fires.
    "red_herring_rate": 0.06,
    # A fixed seed makes "normal" reproducible for a demo; 0 means roll per day.
    "seed": 0,
    # Safety cap: never make more than this many requests in one tick.
    "max_actions_per_tick": 60,
}


def load_config():
    cfg = dict(DEFAULTS)
    cfg_path = Path(os.environ.get("OFFICE_CONFIG", HERE / "config.json"))
    if cfg_path.exists():
        try:
            raw = json.loads(cfg_path.read_text())
        except (OSError, ValueError) as exc:
            die(f"config {cfg_path} is not valid JSON: {exc}")
        for key, value in raw.items():
            # Skip "_comment"-style documentation keys, and let a blank value
            # mean "use the default" (handy for generated_dir in config.example).
            if key.startswith("_") or value == "":
                continue
            cfg[key] = value
    # Environment overrides win, so a systemd unit or a test can set them.
    for key in DEFAULTS:
        env = os.environ.get("OFFICE_" + key.upper())
        if env is not None:
            cfg[key] = type(DEFAULTS[key])(env)
    return cfg


def die(msg):
    print(f"office: {msg}", file=sys.stderr)
    raise SystemExit(1)


# ---------------------------------------------------------------------------
# Personas: how each kind of employee behaves through the day.
#
# hours      : the local hours this persona is usually around.
# activity   : how busy they are when active (multiplier on actions per burst).
# typo_rate  : chance a login starts with one or more wrong passwords.
# ---------------------------------------------------------------------------
PERSONAS = {
    "early_bird":      {"hours": range(6, 16),  "activity": 1.0, "typo_rate": 0.10},
    "night_owl":       {"hours": range(12, 24), "activity": 1.0, "typo_rate": 0.10},
    "nine_to_five":    {"hours": range(9, 18),  "activity": 1.0, "typo_rate": 0.08},
    "typo_prone":      {"hours": range(8, 18),  "activity": 0.9, "typo_rate": 0.45},
    "heavy_file_user": {"hours": range(8, 19),  "activity": 1.8, "typo_rate": 0.08},
    "rare_login":      {"hours": range(8, 18),  "activity": 0.4, "typo_rate": 0.10},
    "road_warrior":    {"hours": range(5, 23),  "activity": 0.8, "typo_rate": 0.15},
}
DEFAULT_PERSONA = {"hours": range(8, 18), "activity": 1.0, "typo_rate": 0.10}


def persona_of(emp):
    return PERSONAS.get(emp.get("persona"), DEFAULT_PERSONA)


def hour_weight(persona, hour):
    """How likely this persona is to be active at `hour` (0..1-ish)."""
    hrs = list(persona["hours"])
    if hour in hrs:
        # Busiest in the middle of their window, quieter at the edges.
        mid = (hrs[0] + hrs[-1]) / 2
        span = max(1, (hrs[-1] - hrs[0]) / 2)
        return max(0.25, 1.0 - abs(hour - mid) / (span + 1))
    # A little life outside their usual hours (road warriors more so).
    return 0.08 if persona["activity"] >= 0.8 else 0.03


# ---------------------------------------------------------------------------
# Roster + credentials
# ---------------------------------------------------------------------------
def load_people(cfg):
    gen = Path(cfg["generated_dir"])
    company = gen / "company.json"
    creds = gen / "lab-credentials.json"
    if not company.exists() or not creds.exists():
        die(
            f"no generated roster in {gen}. Install the web-srv stage first "
            "(lab/stages/2-web-srv/install.sh), which writes company.json and "
            "lab-credentials.json."
        )
    try:
        employees = json.loads(company.read_text())["employees"]
        passwords = json.loads(creds.read_text())
    except (OSError, ValueError, KeyError) as exc:
        die(f"could not read the roster: {exc}")
    # Keep only staff we have a password for; skip the demo account (it is for
    # hands-on testing, not background noise).
    people = [
        e for e in employees
        if e["username"] in passwords and e["username"] != "demo.user"
    ]
    if not people:
        die("the roster has no usable accounts with passwords.")
    return people, passwords


# ---------------------------------------------------------------------------
# A browser for one employee (keeps a cookie jar, so a dashboard view after a
# login is a real session, exactly like a person's browser).
# ---------------------------------------------------------------------------
class Browser:
    def __init__(self, cfg, timeout=6):
        self.cfg = cfg
        self.timeout = timeout
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(CookieJar())
        )
        self.opener.addheaders = [("User-Agent", "Mozilla/5.0 (AcmeStaff; lab)")]

    def _get(self, url):
        try:
            with self.opener.open(url, timeout=self.timeout) as resp:
                resp.read(2048)
            return True
        except (urllib.error.URLError, OSError):
            return False

    def login(self, username, password):
        data = urllib.parse.urlencode(
            {"username": username, "password": password}
        ).encode()
        url = self.cfg["portal_url"].rstrip("/") + "/login"
        try:
            with self.opener.open(url, data=data, timeout=self.timeout) as resp:
                body = resp.read(4096).decode("utf-8", "replace")
                # The portal re-renders the login page with an error on failure,
                # and redirects to the dashboard on success.
                return "Invalid username or password" not in body
        except (urllib.error.URLError, OSError):
            return False

    def view_dashboard(self):
        return self._get(self.cfg["portal_url"].rstrip("/") + "/dashboard")

    def browse_site(self):
        return self._get(self.cfg["site_url"])

    def logout(self):
        return self._get(self.cfg["portal_url"].rstrip("/") + "/logout")


# ---------------------------------------------------------------------------
# One employee's burst of activity.
# ---------------------------------------------------------------------------
def wrong_password(rng, real):
    """A plausible typo: the real password with the last character changed or a
    stray key appended. Never the real password, so it always fails."""
    if real and rng.random() < 0.5 and len(real) > 1:
        return real[:-1] + rng.choice("xyz123")
    return real + rng.choice("!?.")


def do_employee(rng, cfg, emp, passwords, dry_run, plan):
    persona = persona_of(emp)
    user = emp["username"]
    real = passwords[user]
    actions = []

    # A login, sometimes preceded by a mistyped password or two.
    if rng.random() < persona["typo_rate"]:
        for _ in range(rng.randint(1, 2)):
            actions.append(("login_fail", user))
    actions.append(("login_success", user))

    # A few page views once in. Heavy file users do more.
    views = max(1, int(round(rng.randint(1, 3) * persona["activity"])))
    for _ in range(views):
        actions.append((rng.choice(["dashboard", "site"]), user))
    if rng.random() < 0.3:
        actions.append(("logout", user))

    plan.append({"user": user, "persona": emp.get("persona"), "actions": [a for a, _ in actions]})
    if dry_run:
        return len(actions)

    br = Browser(cfg)
    for kind, _ in actions:
        try:
            if kind == "login_fail":
                br.login(user, wrong_password(rng, real))
            elif kind == "login_success":
                br.login(user, real)
            elif kind == "dashboard":
                br.view_dashboard()
            elif kind == "site":
                br.browse_site()
            elif kind == "logout":
                br.logout()
        except Exception:  # noqa: BLE001 - a tick must never crash on one request
            pass
        time.sleep(rng.uniform(0.2, 1.5))  # spread events out a little
    return len(actions)


# ---------------------------------------------------------------------------
# Red herrings: harmless but suspicious. All ordinary portal activity.
# ---------------------------------------------------------------------------
def maybe_red_herring(rng, cfg, people, passwords, hour, in_hours, dry_run, plan):
    if rng.random() >= cfg["red_herring_rate"]:
        return None

    kinds = ["returning_from_leave", "service_account_burst"]
    if not in_hours:
        kinds.append("after_hours_admin")
    kind = rng.choice(kinds)

    if kind == "after_hours_admin":
        it = [e for e in people if e.get("department") == "IT"] or people
        emp = rng.choice(it)
    elif kind == "returning_from_leave":
        rare = [e for e in people if e.get("persona") == "rare_login"] or people
        emp = rng.choice(rare)
    else:
        emp = rng.choice(people)

    user = emp["username"]
    real = passwords[user]
    detail = {"type": kind, "user": user, "hour": hour}
    plan.append({"red_herring": detail})

    if dry_run:
        return detail

    br = Browser(cfg)
    try:
        if kind == "returning_from_leave":
            # A few fumbled passwords after time away, then they get in.
            for _ in range(rng.randint(2, 4)):
                br.login(user, wrong_password(rng, real))
                time.sleep(rng.uniform(0.3, 1.0))
            br.login(user, real)
            br.view_dashboard()
        elif kind == "after_hours_admin":
            # An IT person signs in outside work hours and clicks around.
            br.login(user, real)
            for _ in range(rng.randint(2, 4)):
                br.view_dashboard()
                time.sleep(rng.uniform(0.3, 1.0))
        else:  # service_account_burst: one account, lots of views, fast.
            br.login(user, real)
            for _ in range(rng.randint(6, 10)):
                br.view_dashboard()
                time.sleep(rng.uniform(0.1, 0.4))
    except Exception:  # noqa: BLE001
        pass
    return detail


def record_red_herring(detail):
    """Append a red herring to the git-ignored spoilers log for `reveal`."""
    try:
        SPOILERS.mkdir(exist_ok=True)
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        day = datetime.now(timezone.utc).strftime("%Y%m%d")
        line = f"{ts} type={detail['type']} user={detail['user']}\n"
        (SPOILERS / f"red-herrings-{day}.log").open("a").write(line)
    except OSError:
        pass  # never let logging break a quiet tick


# ---------------------------------------------------------------------------
# One tick = one slice of the working day.
# ---------------------------------------------------------------------------
def tick(cfg, dry_run=False):
    people, passwords = load_people(cfg)
    now = datetime.now()
    hour = now.hour
    in_hours = cfg["work_start_hour"] <= hour < cfg["work_end_hour"]

    # Reproducible within a tick, different across ticks/days. A non-zero config
    # seed pins the whole thing for a demo.
    base = cfg["seed"] or int(now.strftime("%Y%m%d"))
    bucket = now.hour * 6 + now.minute // 10  # a ~10-minute bucket of the day
    rng = random.Random(f"{base}:{bucket}")

    plan = []
    total_actions = 0

    # Decide who acts this tick.
    peak = cfg["peak_active_fraction"]
    for emp in people:
        if total_actions >= cfg["max_actions_per_tick"]:
            break
        p = peak * hour_weight(persona_of(emp), hour) * persona_of(emp)["activity"]
        if rng.random() < p:
            total_actions += do_employee(rng, cfg, emp, passwords, dry_run, plan)

    # Maybe one red herring.
    detail = maybe_red_herring(
        rng, cfg, people, passwords, hour, in_hours, dry_run, plan
    )
    if detail and not dry_run:
        record_red_herring(detail)

    return {
        "when_local": now.strftime("%Y-%m-%d %H:%M"),
        "hour": hour,
        "in_work_hours": in_hours,
        "people_total": len(people),
        "actors": len([x for x in plan if "user" in x]),
        "actions": total_actions,
        "red_herring": detail,
    }


def main():
    ap = argparse.ArgumentParser(description="Busy-office noise generator (one tick).")
    ap.add_argument("command", choices=["tick"], help="what to do")
    ap.add_argument("--dry-run", action="store_true",
                    help="compute a slice but make no requests; print a JSON summary")
    args = ap.parse_args()

    cfg = load_config()
    summary = tick(cfg, dry_run=args.dry_run)

    if args.dry_run:
        # Diagnostic path only (verify.sh and tests). Normal ticks stay quiet.
        print(json.dumps(summary, indent=2))
    else:
        print("done")


if __name__ == "__main__":
    main()

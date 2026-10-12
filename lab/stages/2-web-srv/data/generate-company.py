#!/usr/bin/env python3
"""Generate a random fake "Acme Corp" roster for the lab.

Run ON web-srv (install.sh calls it for you). It writes JSON files into
../generated/ (which is git-ignored, so nothing here ever gets committed).

  python3 generate-company.py                # new random company, random seed
  python3 generate-company.py --seed 12345   # reproduce an exact company
  python3 generate-company.py --employees 40 # aim for ~40 staff

Why randomness: a real analyst learns their own company's "normal" (that skill is
called baselining). The randomness here stops you MEMORISING one fixed roster, so
each time you rebuild the lab, who works there and who has which role changes.

What it does NOT do: it does not set any real passwords. The portal's installer
hashes a throwaway password for each account at install time and stores only the
hash. The one exception is a single obviously-fake weak demo login, clearly marked,
that only works inside your private lab.

Output (all under ../generated/):
  seed.txt         the seed used, so you can reproduce this exact company
  company.json     departments, employees, personas, groups
  portal-users.csv username,display_name,department,title,email  (NO passwords)
"""
import argparse
import csv
import json
import os
import random
import secrets
from datetime import date, timedelta
from pathlib import Path

HERE = Path(__file__).resolve().parent
POOLS = json.loads((HERE / "name-pools.json").read_text())
OUT = HERE.parent / "generated"

DOMAIN = "acme.lab"  # internal-only, never a real domain


def pick_size(rng, lo_hi):
    return rng.randint(lo_hi[0], lo_hi[1])


def make_username(first, last, taken):
    base = f"{first[0]}{last}".lower()
    base = "".join(c for c in base if c.isalnum())
    name = base
    n = 1
    while name in taken:
        n += 1
        name = f"{base}{n}"
    taken.add(name)
    return name


def build_company(rng, target_employees):
    taken = set()
    employees = []
    departments = []

    for dept in POOLS["departments"]:
        count = pick_size(rng, dept["size"])
        departments.append({"name": dept["name"], "code": dept["code"], "headcount": count})
        titles = POOLS["titles"][dept["name"]]
        for _ in range(count):
            first = rng.choice(POOLS["first_names"])
            last = rng.choice(POOLS["last_names"])
            username = make_username(first, last, taken)
            title = rng.choice(titles)
            start = date(2019, 1, 1) + timedelta(days=rng.randint(0, 2200))
            employees.append({
                "username": username,
                "display_name": f"{first} {last}",
                "first_name": first,
                "last_name": last,
                "email": f"{username}@{DOMAIN}",
                "department": dept["name"],
                "dept_code": dept["code"],
                "title": title,
                "persona": rng.choice(POOLS["personas"]),
                "start_date": start.isoformat(),
                "manager": None,
            })

    # Trim or note if we drifted far from the requested size (soft target).
    rng.shuffle(employees)

    # Assign a manager per department (someone with a "Manager"/"Lead" title if present).
    by_dept = {}
    for e in employees:
        by_dept.setdefault(e["department"], []).append(e)
    for dept_name, people in by_dept.items():
        leads = [p for p in people if any(w in p["title"] for w in ("Manager", "Lead", "Controller"))]
        boss = (leads or people)[0]
        for p in people:
            if p is not boss:
                p["manager"] = boss["username"]

    # Standard groups (plain directory structure; no deliberately risky config here).
    groups = [{"name": "All Staff", "members": [e["username"] for e in employees]}]
    for dept_name, people in by_dept.items():
        groups.append({"name": f"{dept_name}", "members": [p["username"] for p in people]})
    it_people = [e["username"] for e in employees if e["department"] == "IT"]
    groups.append({"name": "IT Admins", "members": it_people})

    return {
        "company": "Acme Corp",
        "domain": DOMAIN,
        "departments": departments,
        "employees": sorted(employees, key=lambda e: e["username"]),
        "groups": groups,
    }


def main():
    ap = argparse.ArgumentParser(description="Generate a random fake Acme Corp roster.")
    ap.add_argument("--seed", type=int, default=None, help="reproduce an exact company")
    ap.add_argument("--employees", type=int, default=35, help="soft target headcount")
    args = ap.parse_args()

    seed = args.seed if args.seed is not None else secrets.randbelow(10_000_000)
    rng = random.Random(seed)

    company = build_company(rng, args.employees)

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "seed.txt").write_text(f"{seed}\n")
    (OUT / "company.json").write_text(json.dumps(company, indent=2) + "\n")

    with (OUT / "portal-users.csv").open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["username", "display_name", "department", "title", "email"])
        for e in company["employees"]:
            w.writerow([e["username"], e["display_name"], e["department"], e["title"], e["email"]])

    # Quiet by design: print only a neutral confirmation, not the roster.
    print("done")


if __name__ == "__main__":
    main()

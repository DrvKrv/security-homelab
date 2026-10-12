#!/usr/bin/env python3
"""Build the portal's SQLite database from the generated roster.

Run at install time (install.sh calls it). Reads ../generated/portal-users.csv,
gives each account a RANDOM password, and stores only the password HASH in the DB.

The throwaway plaintext passwords are written to ../generated/lab-credentials.json
so later lab tooling can log in as these fake staff. That file is git-ignored and
lab-only: these are not real credentials and the accounts exist only inside your
private lab. Never reuse these passwords anywhere real.

A single demo account (demo.user / AcmeDemo1!) is added with a fixed, obviously-fake
password so you can test the login by hand and watch the auth events in Wazuh.
"""
import csv
import json
import os
import secrets
import sqlite3
import string
from pathlib import Path

from werkzeug.security import generate_password_hash

HERE = Path(__file__).resolve().parent
GEN = HERE.parent / "generated"
DB_PATH = os.environ.get("PORTAL_DB", str(GEN / "portal.db"))

DEMO_USER = "demo.user"
DEMO_PASS = "AcmeDemo1!"  # lab-only, intentionally fake; documented in README


def random_password(n=20):
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(n))


def main():
    users_csv = GEN / "portal-users.csv"
    if not users_csv.exists():
        raise SystemExit("portal-users.csv not found - run data/generate-company.py first.")

    Path(DB_PATH).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute("DROP TABLE IF EXISTS users")
    conn.execute(
        "CREATE TABLE users ("
        " username TEXT PRIMARY KEY, display_name TEXT, department TEXT,"
        " title TEXT, email TEXT, password_hash TEXT)"
    )

    credentials = {}
    with users_csv.open() as fh:
        for row in csv.DictReader(fh):
            pw = random_password()
            conn.execute(
                "INSERT OR REPLACE INTO users VALUES (?,?,?,?,?,?)",
                (row["username"], row["display_name"], row["department"],
                 row["title"], row["email"], generate_password_hash(pw)),
            )
            credentials[row["username"]] = pw

    # Demo account with a fixed, fake password for hands-on testing.
    conn.execute(
        "INSERT OR REPLACE INTO users VALUES (?,?,?,?,?,?)",
        (DEMO_USER, "Demo User", "IT", "Lab Demo Account",
         f"{DEMO_USER}@acme.lab", generate_password_hash(DEMO_PASS)),
    )
    credentials[DEMO_USER] = DEMO_PASS

    conn.commit()
    conn.close()

    (GEN / "lab-credentials.json").write_text(json.dumps(credentials, indent=2) + "\n")
    os.chmod(GEN / "lab-credentials.json", 0o600)
    print("done")


if __name__ == "__main__":
    main()

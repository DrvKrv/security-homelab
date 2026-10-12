#!/usr/bin/env python3
"""Acme Corp employee portal - a small, deliberately ORDINARY web app.

This is the lab's "normal" application: it is written to be reasonably secure
(hashed passwords, parameterised SQL, no template injection) so that the logs it
produces look like a real internal app's logs. The thing you practise attacking
and fixing is the separate training target app, not this.

It exists mainly to generate realistic authentication events for Wazuh:
every login attempt is written to /var/log/acme-portal/auth.log in a simple,
parseable format that the Wazuh agent ships.

Seeding: the database is built at install time from the generated roster
(../generated/). Passwords are random, stored only as hashes. One clearly-marked
demo account exists so you can test the login flow by hand; it is lab-only.
"""
import logging
import os
import sqlite3
from datetime import datetime, timezone
from logging.handlers import RotatingFileHandler
from pathlib import Path

from flask import Flask, redirect, render_template, request, session, url_for
from werkzeug.security import check_password_hash

DB_PATH = os.environ.get("PORTAL_DB", "/data/portal.db")
LOG_DIR = Path(os.environ.get("PORTAL_LOG_DIR", "/var/log/acme-portal"))
SECRET = os.environ.get("PORTAL_SECRET_KEY") or os.urandom(32)

app = Flask(__name__)
app.secret_key = SECRET

# --- auth event log (what Wazuh reads) ---------------------------------------
LOG_DIR.mkdir(parents=True, exist_ok=True)
auth_log = logging.getLogger("acme-portal.auth")
auth_log.setLevel(logging.INFO)
_handler = RotatingFileHandler(LOG_DIR / "auth.log", maxBytes=2_000_000, backupCount=3)
_handler.setFormatter(logging.Formatter("%(message)s"))
auth_log.addHandler(_handler)
auth_log.addHandler(logging.StreamHandler())  # also to container stdout


def log_auth(result, username, request):
    # Fixed field order so a Wazuh decoder can parse it reliably.
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    src = request.headers.get("X-Forwarded-For", request.remote_addr or "-").split(",")[0].strip()
    safe_user = (username or "-")[:64].replace(" ", "_")
    auth_log.info(f"{ts} acme-portal AUTH result={result} user={safe_user} src={src}")


def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


@app.route("/healthz")
def healthz():
    return "ok", 200


@app.route("/portal/")
@app.route("/")
def home():
    if session.get("user"):
        return redirect(url_for("dashboard"))
    return redirect(url_for("login"))


@app.route("/portal/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        username = request.form.get("username", "").strip().lower()
        password = request.form.get("password", "")
        # Parameterised query: the username is data, never concatenated into SQL.
        with db() as conn:
            row = conn.execute(
                "SELECT username, display_name, department, title, password_hash "
                "FROM users WHERE username = ?",
                (username,),
            ).fetchone()
        if row and check_password_hash(row["password_hash"], password):
            session["user"] = row["username"]
            session["display_name"] = row["display_name"]
            log_auth("success", username, request)
            return redirect(url_for("dashboard"))
        else:
            log_auth("failure", username, request)
            error = "Invalid username or password."
    return render_template("login.html", error=error)


@app.route("/portal/dashboard")
def dashboard():
    if not session.get("user"):
        return redirect(url_for("login"))
    with db() as conn:
        me = conn.execute(
            "SELECT username, display_name, department, title FROM users WHERE username = ?",
            (session["user"],),
        ).fetchone()
        colleagues = conn.execute(
            "SELECT display_name, title FROM users WHERE department = ? AND username != ? "
            "ORDER BY display_name LIMIT 12",
            (me["department"], me["username"]),
        ).fetchall()
    return render_template("dashboard.html", me=me, colleagues=colleagues)


@app.route("/portal/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


if __name__ == "__main__":
    # Dev server is fine for a lab; gunicorn is used in the container (see Dockerfile).
    app.run(host="0.0.0.0", port=8000)

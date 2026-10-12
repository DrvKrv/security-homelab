#!/usr/bin/env python3
"""Roll a deterministic multi-step breach plan for the capstone (unit 10).

This does NOT run anything. It is the brain behind run-breach.sh: given a seed,
it produces the same ordered plan every time, so the plan can be computed
independently on each lab VM (wazuh, linux-srv) and still line up, and so the
answer key can be regenerated from the seed alone.

Every step reuses a script that already exists in the repo (lab/linux/*.sh,
lab/windows/*.ps1) or a manual action against an established training app
(OWASP Juice Shop). Nothing here is new attack code; it only decides which of
the existing pieces run, in what order, with which randomised details and timing.

The breach, as a story:
  1. (web)  the attacker pokes the public-facing app (Juice Shop)   T1190
  2.        quiet recon of an internal host (authorized nmap)        T1046
  3.        password guessing against SSH                            T1110.001
  4. (ad)   a valid account finally logs in on Windows               T1078
  5.        the attacker plants a hidden admin account (persistence) T1136.001
  6.        and probes a second host for a way across                T1021 / T1046

Usage:
    python3 breach-plan.py --seed 12345 --envs core,web,ad --json
    python3 breach-plan.py --seed 12345 --host wazuh --json      # only this VM's steps
    python3 breach-plan.py --seed 12345 --answer-key             # the readable plan
"""
import argparse
import json
import random
import sys

# Service-style names a planted account might hide behind (same pool the lesson
# runner uses in lab/exercises/lib/staging.sh).
ACCOUNT_POOL = [
    "svc_backup", "svc_monitor", "sysmaint", "backup_svc",
    "ops_agent", "svc_update", "svc_patch", "it_tmp",
]

# A small set of Juice Shop built-in challenges to point the attacker at. The
# learner solves these by hand from win-srv's browser; we only name one.
JUICE_CHALLENGES = [
    "the login-admin SQL injection challenge",
    "the 'Score Board' discovery challenge",
    "a reflected-XSS search challenge",
    "the forgotten-developer-backup access challenge",
]


def build_plan(seed, envs):
    rng = random.Random(f"capstone:{seed}")
    have = set(envs)
    web = "web" in have
    ad = "ad" in have  # the win-srv steps need the AD/Windows stage (unit 7)

    acct_linux = rng.choice(ACCOUNT_POOL)
    acct_win = rng.choice([a for a in ACCOUNT_POOL if a != acct_linux])
    ssh_tries = rng.randint(8, 16)
    # Where persistence lands. If Windows is in play, flip a coin.
    persist_on_windows = ad and rng.random() < 0.5

    steps = []

    if web:
        steps.append({
            "key": "web_entry",
            "phase": "Initial access",
            "host": "win-srv",           # solved from win-srv's browser
            "runner": "manual",
            "narrative": "The attacker probes the public-facing app for a way in.",
            "action": f"From win-srv's browser, solve {rng.choice(JUICE_CHALLENGES)} "
                      "at http://10.0.1.40:3000/ (OWASP Juice Shop's own challenge).",
            "expected": ["web access-log entries for web-srv (nginx 100xxx web rules)"],
            "attack": "T1190 Exploit Public-Facing Application",
        })

    steps.append({
        "key": "recon_nmap",
        "phase": "Discovery",
        "host": "wazuh",
        "runner": "bash",
        "narrative": "Quiet recon: map what an internal host is running.",
        "command": "yes YES | bash linux/run-authorized-nmap-scan.sh $LINUX_IP",
        "expected": ["100100 UFW blocked a connection", "100102 possible port scan"],
        "attack": "T1046 Network Service Discovery",
    })

    steps.append({
        "key": "ssh_bruteforce",
        "phase": "Credential access",
        "host": "wazuh",
        "runner": "bash",
        "narrative": "Password guessing against SSH on the internal host.",
        "command": f"bash linux/simulate-ssh-bruteforce.sh $LINUX_IP {ssh_tries}",
        "expected": ["5710 invalid user", "5712 brute force (non-existent users)",
                     "5760/5763 if password auth is on"],
        "attack": "T1110.001 Brute Force: Password Guessing",
        "detail": {"attempts_per_round": ssh_tries},
    })

    if ad:
        steps.append({
            "key": "win_logon",
            "phase": "Valid accounts",
            "host": "win-srv",
            "runner": "powershell",
            "narrative": "A valid account finally signs in on Windows: failures, then one success.",
            "action": r".\Simulate-SuccessfulLogon.ps1 -Phase Scenario   (run from the repo's lab\windows folder)",
            "expected": ["4625 logon failure", "60204 multiple failures",
                         "4624 logon success"],
            "attack": "T1078 Valid Accounts",
        })

    if persist_on_windows:
        steps.append({
            "key": "win_backdoor",
            "phase": "Persistence",
            "host": "win-srv",
            "runner": "powershell",
            "narrative": f"A hidden local admin account ({acct_win}) is planted on Windows.",
            "action": rf".\Simulate-AccountChanges.ps1 -Phase Attack -UserName {acct_win}   (lab\windows)",
            "expected": ["4720 user created", "4732 added to Administrators (60154, level 12)",
                         "4724 password reset"],
            "attack": "T1136.001 Create Account / T1098 Account Manipulation",
            "detail": {"account": acct_win},
            "cleanup": rf".\Simulate-AccountChanges.ps1 -Phase Cleanup -UserName {acct_win}",
        })
    else:
        steps.append({
            "key": "linux_backdoor",
            "phase": "Persistence",
            "host": "linux-srv",
            "runner": "bash-sudo",
            "narrative": f"A hidden admin account ({acct_linux}) is planted on the Linux host.",
            "command": f"sudo bash linux/simulate-account-changes.sh attack {acct_linux}",
            "expected": ["5902 new user", "2961/100110 added to sudo (level 10)",
                         "5555 password changed", "550/554 file-integrity on /etc/passwd,group,shadow"],
            "attack": "T1136.001 Create Account / T1098 Account Manipulation",
            "detail": {"account": acct_linux},
            "cleanup": f"sudo bash linux/simulate-account-changes.sh cleanup {acct_linux}",
        })

    steps.append({
        "key": "lateral_probe",
        "phase": "Lateral movement",
        "host": "wazuh",
        "runner": "bash",
        "narrative": "The attacker probes a second host for services to move across.",
        "command": "bash linux/simulate-blocked-connections.sh $LINUX_IP",
        "expected": ["100100 UFW blocked a connection (RDP/SMB/MSSQL/... probes)"],
        "attack": "T1021 Remote Services / T1046 Network Service Discovery",
    })

    return steps


def with_offsets(steps, seed, within_minutes):
    """Assign each step a start offset (minutes from arming), preserving order."""
    rng = random.Random(f"capstone-time:{seed}")
    n = len(steps)
    if within_minutes <= 0:
        # A controlled run: small, ordered gaps so each step's alerts stay distinct.
        t = 0
        for s in steps:
            s["offset_min"] = t
            t += rng.randint(2, 5)
    else:
        # Spread across the window, keeping the story in order.
        points = sorted(rng.uniform(0, within_minutes) for _ in range(n))
        for s, p in zip(steps, points):
            s["offset_min"] = round(p, 1)
    return steps


def parse_within(text):
    text = (text or "0").strip().lower()
    if text in ("0", ""):
        return 0
    unit = text[-1]
    num = float(text[:-1]) if unit in "mhd" else float(text)
    return {"m": num, "h": num * 60, "d": num * 60 * 24}.get(unit, num)


def main():
    ap = argparse.ArgumentParser(description="Roll a deterministic capstone breach plan.")
    ap.add_argument("--seed", type=int, required=True)
    ap.add_argument("--envs", default="core", help="comma list: core,web,ad,...")
    ap.add_argument("--within", default="0", help="spread the steps over this window, e.g. 0, 90m, 6h, 2d")
    ap.add_argument("--host", default="", help="only steps that run on this VM")
    ap.add_argument("--json", action="store_true", help="emit the plan as JSON")
    ap.add_argument("--answer-key", action="store_true", help="emit the readable answer key")
    args = ap.parse_args()

    envs = [e.strip() for e in args.envs.split(",") if e.strip()]
    steps = build_plan(args.seed, envs)
    steps = with_offsets(steps, args.seed, parse_within(args.within))
    for i, s in enumerate(steps, 1):
        s["order"] = i

    host_steps = [s for s in steps if not args.host or s["host"] == args.host]

    if args.json:
        print(json.dumps(host_steps, indent=2))
        return

    # Readable answer key (the whole plan, for the sealed spoilers file).
    out = [f"# Capstone breach plan (seed {args.seed}, envs: {','.join(envs)})", ""]
    out.append("Times are offsets in minutes from when each VM is armed.\n")
    for s in steps:
        out.append(f"## Step {s['order']} - {s['phase']}  (+{s['offset_min']} min, on {s['host']})")
        out.append(f"{s['narrative']}")
        out.append(f"- MITRE ATT&CK: {s['attack']}")
        if "command" in s:
            out.append(f"- Runs (from the repo's lab/ folder): `{s['command']}`")
        if "action" in s:
            out.append(f"- Do: {s['action']}")
        out.append(f"- Expect in Wazuh: {', '.join(s['expected'])}")
        if s.get("cleanup"):
            out.append(f"- Clean up afterwards: `{s['cleanup']}`")
        out.append("")
    print("\n".join(out))


if __name__ == "__main__":
    main()

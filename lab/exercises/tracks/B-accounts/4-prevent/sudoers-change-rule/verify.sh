#!/usr/bin/env bash
# verify.sh - checks the B4 rule on the wazuh VM. Run as part of:
#   ./run.sh verify B4/sudoers-change-rule        (on wazuh)
#
# PASS when: the manager's ruleset loads, local_rules.xml has a rule of yours
# (id 100300-100399) about sudoers, and that rule raised an alert of level 10
# or more for a file under /etc/sudoers or /etc/sudoers.d, in today's alerts.
# Read-only.

set -uo pipefail
OSSEC=/var/ossec
fail=0
check() { # check "<description>" <0-if-good>
  if [[ "$2" -eq 0 ]]; then printf '  [ OK ] %s\n' "$1"; else printf '  [FAIL] %s\n' "$1" >&2; fail=1; fi
}
check_if() { local d="$1"; shift; if "$@"; then check "$d" 0; else check "$d" 1; fi; }

[[ -x "$OSSEC/bin/wazuh-analysisd" ]] || { echo "Run this on the wazuh VM." >&2; exit 1; }

loads() { sudo "$OSSEC/bin/wazuh-analysisd" -t >/dev/null 2>&1; }
has_rule() { sudo grep -qE '<rule id="1003[0-9]{2}"' "$OSSEC/etc/rules/local_rules.xml" && sudo grep -q 'sudoers' "$OSSEC/etc/rules/local_rules.xml"; }
fired() {
  sudo python3 - "$OSSEC/logs/alerts/alerts.json" <<'PY'
import json, sys
for line in open(sys.argv[1], errors="replace"):
    try:
        a = json.loads(line)
    except ValueError:
        continue
    r, path = a.get("rule", {}), a.get("syscheck", {}).get("path", "")
    if 100300 <= int(r.get("id", 0)) <= 100399 and int(r.get("level", 0)) >= 10 \
            and path.startswith("/etc/sudoers"):
        sys.exit(0)
sys.exit(1)
PY
}

check_if "the manager's ruleset loads (wazuh-analysisd -t)" loads
check_if "local_rules.xml has a rule of yours (100300-100399) about sudoers" has_rule
check_if "your rule fired at level 10+ for a change under /etc/sudoers* today" fired

echo
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed. Add a line to your case file: what fired, when, and at what level."
  exit 0
fi
echo "Not yet. If the rule exists but hasn't fired: stage the lesson on linux-srv again and give it a minute." >&2
exit 1

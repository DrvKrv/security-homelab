#!/usr/bin/env bash
# verify.sh - checks C4's Suricata rule on linux-srv. Run as part of:
#   ./run.sh verify C4/suricata-scan-alert        (on linux-srv)
#
# PASS when: Suricata is running with a valid config, local.rules has a rule of
# yours (sid 9000000-9099999), and that rule raised an alert in eve.json for
# traffic from the wazuh VM (the lab's scanner) in the last 24 hours. Read-only.

set -uo pipefail
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
WAZUH_IP="10.0.1.10"
# shellcheck source=/dev/null
[[ -f "$LAB_DIR/lab.env" ]] && source "$LAB_DIR/lab.env"
LOCAL_RULES=/etc/suricata/rules/local.rules
EVE=/var/log/suricata/eve.json
fail=0
check() { if [[ "$2" -eq 0 ]]; then printf '  [ OK ] %s\n' "$1"; else printf '  [FAIL] %s\n' "$1" >&2; fail=1; fi; }
check_if() { local d="$1"; shift; if "$@"; then check "$d" 0; else check "$d" 1; fi; }

running() { sudo systemctl is-active --quiet suricata; }
valid() { sudo suricata -T -c /etc/suricata/suricata.yaml >/dev/null 2>&1; }
has_rule() { sudo grep -qE '^[^#]*\bsid:\s*90[0-9]{5}\s*;' "$LOCAL_RULES" 2>/dev/null; }
fired() {
  sudo python3 - "$EVE" "$WAZUH_IP" <<'PY'
import json, sys, datetime
since = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=24)
for line in open(sys.argv[1], errors="replace"):
    if '"event_type":"alert"' not in line:
        continue
    try:
        e = json.loads(line)
    except ValueError:
        continue
    sid = e.get("alert", {}).get("signature_id", 0)
    ts = datetime.datetime.strptime(e["timestamp"][:19], "%Y-%m-%dT%H:%M:%S").replace(tzinfo=datetime.timezone.utc)
    if 9000000 <= sid <= 9099999 and e.get("src_ip") == sys.argv[2] and ts >= since:
        sys.exit(0)
sys.exit(1)
PY
}

check_if "Suricata is running" running
check_if "Suricata's config and rules load (suricata -T)" valid
check_if "local.rules has a rule of yours (sid 9000000-9099999)" has_rule
check_if "your rule alerted on traffic from the scanner in the last 24 hours" fired

echo
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed. Now check the alert in Wazuh, at the level you chose (see the brief)."
  exit 0
fi
echo "Not yet. After changing local.rules: suricata -T, restart Suricata, then stage the scan again." >&2
exit 1

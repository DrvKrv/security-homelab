#!/usr/bin/env bash
# verify.sh - checks that the port staged by C3 is closed on linux-srv.
# Run as part of:  ./run.sh verify C3/close-open-port      (on linux-srv)
#
# The port is random each time; the runner passes it in LAB_ANSWER_PORT
# (PORT=<n> overrides it). PASS when: nothing listens on the port, UFW has no
# rule allowing it, and none of the units the lesson can start is running.
# Read-only. It never names the port, so it can't give the answer away.

set -uo pipefail
PORT="${PORT:-${LAB_ANSWER_PORT:-}}"
UNITS="report-viewer devtools-preview file-share-tmp status-page"
if [[ -z "$PORT" ]]; then
  echo "No staged port is recorded on this VM. Stage the lesson here first," >&2
  echo "or name the port yourself: PORT=<n> ./run.sh verify C3/close-open-port" >&2
  exit 1
fi
fail=0
check() { # check "<description>" <0-if-good>
  if [[ "$2" -eq 0 ]]; then printf '  [ OK ] %s\n' "$1"; else printf '  [FAIL] %s\n' "$1" >&2; fail=1; fi
}
check_if() { # check_if "<description>" <test command...>: OK if the command succeeds
  local d="$1"; shift
  if "$@"; then check "$d" 0; else check "$d" 1; fi
}

rules="$(sudo ufw status 2>/dev/null)"
allowed() { grep -qE "^$PORT(/tcp)?( \(v6\))? +(ALLOW|LIMIT)" <<< "$rules"; }
any_unit_running() { local u; for u in $UNITS; do sudo systemctl is-active --quiet "$u" && return 0; done; return 1; }

check_if "nothing is listening on the staged port" [ -z "$(ss -Htln "sport = :$PORT")" ]
if allowed; then check "the firewall no longer allows the staged port" 1; else check "the firewall no longer allows the staged port" 0; fi
if any_unit_running; then check "the service that opened it is stopped" 1; else check "the service that opened it is stopped" 0; fi
check_if "UFW itself is still on" grep -q '^Status: active' <<< "$rules"

echo
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed. Now prove it from another lab VM (see the brief)."
  exit 0
fi
echo "One or more checks failed. A port is only closed when both halves are done." >&2
exit 1

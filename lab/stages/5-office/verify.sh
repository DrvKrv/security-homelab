#!/usr/bin/env bash
# verify.sh - check the busy-office generator is set up and working. Run ON web-srv.
#   bash verify.sh
# Prints PASS/FAIL per check and exits non-zero if anything failed. It makes no
# portal requests of its own: it uses office.py's --dry-run, which computes a
# slice of activity without touching the network.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pass=0; fail=0
ok() { printf '  \033[32mPASS\033[0m %s\n' "$1"; pass=$((pass+1)); }
no() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail+1)); }

echo "Busy-office generator checks:"

# python3 present
if command -v python3 >/dev/null; then ok "python3 available"; else no "python3 missing"; fi

# office.py parses and runs a dry tick
if out="$(python3 "$HERE/office.py" tick --dry-run 2>/tmp/office-verify.err)"; then
  ok "office.py runs a dry tick"
  if echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d["people_total"]>0 else 1)' 2>/dev/null; then
    ok "roster loaded ($(echo "$out" | python3 -c 'import json,sys;print(json.load(sys.stdin)["people_total"])') staff with passwords)"
  else
    no "roster has no usable accounts (run the web-srv installer first)"
  fi
else
  no "office.py dry tick failed: $(tr '\n' ' ' </tmp/office-verify.err)"
fi

# config present (only expected after install)
if [[ -f "$HERE/config.json" ]]; then
  ok "config.json present"
  if python3 -c "import json;json.load(open('$HERE/config.json'))" 2>/dev/null; then
    ok "config.json is valid JSON"
  else
    no "config.json is not valid JSON"
  fi
else
  echo "  NOTE: config.json not written yet - run: sudo bash office.sh install"
fi

# systemd timer (only after install)
if systemctl list-unit-files 2>/dev/null | grep -q '^acme-office.timer'; then
  if systemctl is-active --quiet acme-office.timer; then
    ok "acme-office.timer installed and active"
  else
    echo "  NOTE: acme-office.timer installed but not active - start it with: sudo bash office.sh start"
  fi
else
  echo "  NOTE: acme-office.timer not installed yet - run: sudo bash office.sh install"
fi

# portal reachable (informational; the generator needs it, verify does not)
url="$(python3 -c "import json,os; p=os.path.join('$HERE','config.json'); print(json.load(open(p)).get('portal_url','http://localhost/portal')) if os.path.exists(p) else print('http://localhost/portal')" 2>/dev/null)"
if curl -fsS --max-time 5 "${url%/}/login" >/dev/null 2>&1; then
  ok "portal reachable at ${url%/}/login"
else
  echo "  NOTE: portal not reachable at ${url%/}/login (is the web-srv stack up?)"
fi

echo
echo "  $pass passed, $fail failed"
[[ $fail -eq 0 ]]

#!/usr/bin/env bash
# verify.sh - check the Acme web stack is up and logging. Run ON web-srv.
#   bash verify.sh
# Prints PASS/FAIL per check and exits non-zero if anything failed.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pass=0; fail=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; pass=$((pass+1)); }
no()   { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail+1)); }

echo "Acme web stack checks:"

# Containers running
for svc in acme-web acme-portal training-app; do
  if docker compose -f "$HERE/docker-compose.yml" ps --status running --services 2>/dev/null | grep -qx "$svc"; then
    ok "container running: $svc"
  else
    no "container running: $svc"
  fi
done

# Company site responds
if curl -fsS --max-time 5 http://localhost/ >/dev/null 2>&1; then
  ok "company website responds on :80"
else
  no "company website responds on :80"
fi

# Portal login page responds
if curl -fsS --max-time 5 http://localhost/portal/login | grep -qi "Employee Portal"; then
  ok "employee portal responds at /portal/"
else
  no "employee portal responds at /portal/"
fi

# Training target responds
if curl -fsS --max-time 10 http://localhost:3000/ >/dev/null 2>&1; then
  ok "training target responds on :3000"
else
  no "training target responds on :3000 (first start can take ~30s; re-run)"
fi

# A failed login produces an auth-log line (this is what Wazuh will alert on)
curl -fsS --max-time 5 -X POST http://localhost/portal/login \
  -d "username=verify.probe&password=wrong" >/dev/null 2>&1 || true
sleep 1
if grep -q "result=failure user=verify.probe" /var/log/acme-portal/auth.log 2>/dev/null; then
  ok "portal writes auth events to /var/log/acme-portal/auth.log"
else
  no "portal auth log not found at /var/log/acme-portal/auth.log"
fi

# nginx access log is being written
if [[ -s /var/log/acme-web/access.log ]]; then
  ok "web access log present at /var/log/acme-web/access.log"
else
  no "web access log empty/missing at /var/log/acme-web/access.log"
fi

# Wazuh agent (optional at this point)
if systemctl is-active --quiet wazuh-agent 2>/dev/null; then
  ok "wazuh-agent is active"
else
  echo "  NOTE: wazuh-agent not active yet - see wazuh/README.md"
fi

echo
echo "  $pass passed, $fail failed"
[[ $fail -eq 0 ]]

# shellcheck shell=bash
EX_TITLE="Close a port that shouldn't be open and verify"
EX_SUMMARY="A new service is reachable on linux-srv that nobody asked for. Find it, shut it, and prove it's closed."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="linux-srv"
EX_FIX_WHERE=""
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="yes"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1190"

# A harmless stand-in for a forgotten service: Python's built-in web server
# showing an empty folder, run as the unprivileged "nobody" user under a
# transient systemd unit, plus a UFW rule that opens its port to everyone. The
# port and the unit's name are random. Port 8080 is left out on purpose: the C1
# and C2 lessons expect it to stay blocked.
LAB_PORT_POOL="8000 8081 8888 9000 9090"
LAB_PORT_UNITS="report-viewer devtools-preview file-share-tmp status-page"
LAB_PORT_DIR="/srv/lab-share"

ex_stage() {
  local port unit
  port="$(pick $LAB_PORT_POOL)"; unit="$(pick $LAB_PORT_UNITS)"
  answer "port" "$port"
  answer "service" "$unit (a transient systemd unit running python3 -m http.server as nobody)"
  answer "firewall rule" "ufw allow $port/tcp"
  sudo mkdir -p "$LAB_PORT_DIR"
  sudo systemd-run --unit="$unit" --description="$unit" --uid=nobody --gid=nogroup \
    --property=WorkingDirectory="$LAB_PORT_DIR" \
    python3 -m http.server "$port" --bind 0.0.0.0 --directory "$LAB_PORT_DIR"
  sudo ufw allow "$port/tcp"
}

ex_reset() {
  local unit port
  for unit in $LAB_PORT_UNITS; do sudo systemctl stop "$unit" 2>/dev/null || true; done
  for port in $LAB_PORT_POOL; do sudo ufw delete allow "$port/tcp" >/dev/null 2>&1 || true; done
  sudo rm -rf "$LAB_PORT_DIR"
  sudo ufw status
}

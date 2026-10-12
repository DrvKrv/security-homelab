#!/usr/bin/env bash
# simulate-blocked-connections.sh - LAB ONLY. Run ON THE WAZUH VM, aimed at
# linux-srv (which has UFW on from setup-linux-srv.sh).
#
#   !!! Only point this at your own lab VM. It refuses non-lab addresses.
#
# Tries to connect to a handful of services that linux-srv does NOT allow
# (databases, RDP, SMB, telnet, a web admin port). UFW drops each one and logs
# "[UFW BLOCK] ... SRC=<wazuh ip> ... DPT=<port>".
#
# Expected in Wazuh: rule 100100 "Lab: UFW firewall blocked a connection"
# once per port (6 by default: below the port-scan threshold on purpose).
#
# Usage:
#   bash simulate-blocked-connections.sh               # target = LINUX_IP
#   bash simulate-blocked-connections.sh 10.0.1.30

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TARGET="${1:-$LINUX_IP}"
require_lab_target "$TARGET"

declare -A PORTS=([23]=telnet [445]=smb [1433]=mssql [3306]=mysql [3389]=rdp [8080]=web-admin)
LOG="$EVIDENCE_DIR/blocked-connections-$(date +%Y%m%d-%H%M%S).txt"

{
  say "Target: $TARGET   source (this VM): $(hostname -I | awk '{print $1}')"
  for port in 23 445 1433 3306 3389 8080; do
    if nc -z -w 2 "$TARGET" "$port" 2>/dev/null; then
      warn "  $port/${PORTS[$port]}: OPEN (not blocked!) - check 'sudo ufw status' on linux-srv"
    else
      echo "  $port/${PORTS[$port]}: no answer (dropped by firewall)"
    fi
    sleep 3   # spread out so each block is its own log line despite UFW rate limiting
  done
  say "Finished."
} 2>&1 | tee "$LOG"

cat <<EOF
Saved this output to $LOG
Next:
  * On linux-srv:  sudo journalctl -k --since "-10 min" | grep 'UFW BLOCK'
  * In Wazuh:      Threat Hunting > Events, search  rule.id:100100
EOF

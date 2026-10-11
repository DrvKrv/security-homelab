#!/usr/bin/env bash
# run-authorized-nmap-scan.sh - LAB ONLY. Run ON THE WAZUH VM.
#
#   !!! Port scanning devices you don't own or aren't authorized to test can be
#   !!! illegal and can get you banned from your network. This script only
#   !!! scans private addresses inside LAB_SUBNET, and asks you to confirm.
#
# Two scans, saved to ~/lab-evidence:
#   1. SYN scan of the top 1000 TCP ports  -> generates many UFW blocks on
#      linux-srv -> Wazuh 100100 per block, then 100102 "possible port scan".
#   2. Version detection on the open ports  -> service names + versions you
#      look up on NVD in the vulnerability runbook (05).
#
# Usage:
#   bash run-authorized-nmap-scan.sh                # target = LINUX_IP
#   bash run-authorized-nmap-scan.sh 192.168.50.20  # e.g. scan win-client instead

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TARGET="${1:-$LINUX_IP}"
require_lab_target "$TARGET"

if ! command -v nmap >/dev/null; then
  say "Installing nmap"
  sudo apt-get install -y nmap
fi

cat <<EOF
Authorization check
  Scanner : $(hostname) ($(hostname -I | awk '{print $1}'))
  Target  : $TARGET
  Scope   : $LAB_SUBNET (my own isolated lab)
  Time    : $(date '+%Y-%m-%d %H:%M:%S %Z')
EOF
confirm "I own this target and authorize this scan."

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$EVIDENCE_DIR/nmap-$TARGET-$STAMP"

say "Scan 1/2: SYN scan, top 1000 TCP ports (about a minute)"
sudo nmap -sS -T3 --top-ports 1000 --reason -oN "$OUT-syn.txt" -oX "$OUT-syn.xml" "$TARGET"

open_ports="$(grep -oE '^[0-9]+/tcp +open' "$OUT-syn.txt" | cut -d/ -f1 | paste -sd, - || true)"
if [[ -n "$open_ports" ]]; then
  say "Scan 2/2: version detection on open ports: $open_ports"
  sudo nmap -sV --version-light -p "$open_ports" -oN "$OUT-versions.txt" "$TARGET"
else
  warn "No open ports found, skipping version detection."
fi

cat <<EOF

Saved:
  $OUT-syn.txt  (screenshot this)
  $OUT-syn.xml
  ${open_ports:+$OUT-versions.txt}
Next:
  * Wazuh: Threat Hunting > Events, search  rule.id:(100100 or 100102)
  * linux-srv:  sudo journalctl -k --since "-10 min" | grep -c 'UFW BLOCK'
EOF

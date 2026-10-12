#!/usr/bin/env bash
# setup-manager.sh - run ON THE WAZUH VM (Ubuntu 24.04), once, after the
# Wazuh all-in-one install works and you can log in to the dashboard.
#
# What it does:
#   1. Backs up and installs the lab's custom decoder + rules.
#   2. Creates two agent groups, "windows" and "linux", with their agent.conf.
#   3. Checks the config for mistakes BEFORE restarting (so a typo can't take
#      the manager down), then restarts wazuh-manager.
#
# Usage (from the folder that contains this script):
#   sudo bash setup-manager.sh
#
# Then put each agent in its group (see lab/runbooks/00-prepare-the-lab.md):
#   sudo /var/ossec/bin/agent_control -l                 # list agents and their IDs
#   sudo /var/ossec/bin/agent_groups -a -i 001 -g windows -q
#   sudo /var/ossec/bin/agent_groups -a -i 002 -g linux -q

set -euo pipefail

OSSEC=/var/ossec
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash $0" >&2
  exit 1
fi
if [[ ! -x "$OSSEC/bin/wazuh-control" ]]; then
  echo "Wazuh manager not found in $OSSEC. Run this on the Wazuh VM." >&2
  exit 1
fi

install_file() { # src dst
  local src="$1" dst="$2"
  if [[ -f "$dst" ]]; then
    cp -p "$dst" "$dst.bak-$STAMP"
    echo "  backed up $dst -> $dst.bak-$STAMP"
  fi
  install -o wazuh -g wazuh -m 660 "$src" "$dst"
  echo "  installed $dst"
}

echo "[1/3] Installing custom decoder and rules"
install_file "$HERE/manager/local_decoder.xml" "$OSSEC/etc/decoders/local_decoder.xml"
install_file "$HERE/manager/local_rules.xml"   "$OSSEC/etc/rules/local_rules.xml"

echo "[2/3] Creating agent groups"
for group in windows linux; do
  if [[ -d "$OSSEC/etc/shared/$group" ]]; then
    echo "  group '$group' already exists"
  else
    "$OSSEC/bin/agent_groups" -a -g "$group" -q
    echo "  created group '$group'"
  fi
  install_file "$HERE/agent-groups/$group/agent.conf" "$OSSEC/etc/shared/$group/agent.conf"
  "$OSSEC/bin/verify-agent-conf" -f "$OSSEC/etc/shared/$group/agent.conf"
done

echo "[3/3] Testing manager configuration, then restarting"
if ! "$OSSEC/bin/wazuh-analysisd" -t; then
  echo
  echo "Config test FAILED. Nothing was restarted, so Wazuh is still running"
  echo "the old rules. Restore the backups (*.bak-$STAMP) or fix the error above." >&2
  exit 1
fi
systemctl restart wazuh-manager
sleep 5
systemctl --no-pager --lines=0 status wazuh-manager

echo
echo "Done. Next: test the rules with sample logs:"
echo "  sudo $OSSEC/bin/wazuh-logtest"
echo "and paste lines from $HERE/manager/logtest-samples.txt"

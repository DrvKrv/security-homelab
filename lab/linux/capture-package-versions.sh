#!/usr/bin/env bash
# capture-package-versions.sh - run ON linux-srv (or the Wazuh VM) before AND
# after patching, so you have proof of what changed for the remediation ticket.
#
#   bash capture-package-versions.sh before openssh-server openssl sudo
#   ...patch...
#   bash capture-package-versions.sh after  openssh-server openssl sudo
#   diff ~/lab-evidence/packages-before-*.txt ~/lab-evidence/packages-after-*.txt
#
# With no package names it records every installed package.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LABEL="${1:-}"
[[ "$LABEL" == "before" || "$LABEL" == "after" ]] || die "Usage: bash $0 before|after [package ...]"
shift

OUT="$EVIDENCE_DIR/packages-$LABEL-$(hostname)-$(date +%Y%m%d-%H%M%S).txt"
{
  echo "# $(hostname)  $(date '+%Y-%m-%d %H:%M:%S %Z')  kernel $(uname -r)"
  if [[ $# -gt 0 ]]; then
    dpkg-query -W -f='${Package}\t${Version}\n' "$@" 2>&1
  else
    dpkg-query -W -f='${Package}\t${Version}\n'
  fi
  echo "# upgradable right now:"
  apt list --upgradable 2>/dev/null | tail -n +2
  [[ -f /var/run/reboot-required ]] && echo "# REBOOT REQUIRED"
} > "$OUT"

echo "Saved $OUT"

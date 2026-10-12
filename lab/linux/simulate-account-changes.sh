#!/usr/bin/env bash
# simulate-account-changes.sh - LAB ONLY. Run ON linux-srv with sudo.
#
# Simulates an attacker who got root creating a backdoor admin account,
# then (separately) your cleanup as the defender.
#
#   sudo bash simulate-account-changes.sh attack
#       1. useradd svc_backup              -> Wazuh 5902 "New user added to the system"
#       2. gpasswd -a svc_backup sudo      -> Wazuh 100110 (lab rule, level 10) on top of 2961
#       3. set a random password           -> Wazuh 5555 "PAM: User changed password"
#       Also file-integrity alerts (550/554) for /etc/passwd, /etc/group, /etc/shadow
#       because the lab's agent.conf watches those files in real time.
#
#   sudo bash simulate-account-changes.sh cleanup
#       4. gpasswd -d svc_backup sudo
#       5. userdel -r svc_backup           -> Wazuh 5903 "Group (or user) deleted"
#
# The password is random and never shown.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ $EUID -eq 0 ]] || die "Please run with sudo:  sudo bash $0 attack|cleanup"
PHASE="${1:-}"
BACKDOOR="${2:-svc_backup}"
LOG="$EVIDENCE_DIR/account-changes-$PHASE-$(date +%Y%m%d-%H%M%S).txt"

case "$PHASE" in
  attack)
    id "$BACKDOOR" &>/dev/null && die "$BACKDOOR already exists. Run: sudo bash $0 cleanup"
    {
      say "1. Creating user $BACKDOOR"
      useradd -m -s /bin/bash -c "Backup Service" "$BACKDOOR"
      sleep 5
      say "2. Adding $BACKDOOR to sudo (admin rights)"
      gpasswd -a "$BACKDOOR" sudo
      sleep 5
      say "3. Setting a random password for $BACKDOOR"
      echo "$BACKDOOR:$(openssl rand -base64 24)" | chpasswd
      say "Result:"
      id "$BACKDOOR"
      say "Incident staged. Investigate in Wazuh BEFORE running cleanup."
    } 2>&1 | tee "$LOG"
    ;;
  cleanup)
    id "$BACKDOOR" &>/dev/null || die "$BACKDOOR doesn't exist; nothing to clean up."
    {
      say "4. Removing $BACKDOOR from sudo"
      gpasswd -d "$BACKDOOR" sudo || true
      sleep 5
      say "5. Deleting $BACKDOOR and its home folder"
      pkill -KILL -u "$BACKDOOR" 2>/dev/null || true
      userdel -r "$BACKDOOR" 2>/dev/null || userdel "$BACKDOOR"
      say "Verify:"
      getent passwd "$BACKDOOR" || echo "  $BACKDOOR no longer exists"
      getent group sudo
    } 2>&1 | tee "$LOG"
    ;;
  *)
    die "Usage: sudo bash $0 attack|cleanup"
    ;;
esac
echo "Saved this output to $LOG"

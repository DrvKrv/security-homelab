#!/usr/bin/env bash
# simulate-ssh-bruteforce.sh - LAB ONLY. Run ON THE WAZUH VM (playing the
# attacker), aimed at linux-srv.
#
#   !!! Only point this at your own lab VM. It refuses non-lab addresses.
#
# Two rounds, like a real password-guessing tool:
#   Round 1: usernames that don't exist (admin, oracle, test ...)
#            -> Wazuh 5710 per try, 5712 "brute force ... non existent user" after 8
#   Round 2: wrong passwords for the real test account (labuser)
#            -> Wazuh 5760 per try, 5763 "brute force ... authentication failed" after 8
#            (also PAM 5503 / 5551)
#            ONLY when linux-srv accepts password logins. Azure Ubuntu images are
#            key-only until you run setup-linux-srv.sh (it adds a drop-in that turns
#            PasswordAuthentication on). If password logins are off, Round 2 is
#            skipped with a message, because no "Failed password" lines can appear.
#            (For reference: on a key-only server, connection attempts by a real
#            user show up only as 5762 "sshd: connection reset", level 4, with no
#            brute-force correlation. Seen on the live lab, 2026-10-12.)
#
# Usage:
#   bash simulate-ssh-bruteforce.sh                # target = LINUX_IP from lab.env
#   bash simulate-ssh-bruteforce.sh 10.0.1.30 10

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TARGET="${1:-$LINUX_IP}"
TRIES="${2:-10}"
require_lab_target "$TARGET"

if ! command -v sshpass >/dev/null; then
  say "Installing sshpass (lets the script type wrong passwords automatically)"
  sudo apt-get install -y sshpass
fi

SSH_OPTS=(-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
LOG="$EVIDENCE_DIR/ssh-bruteforce-$(date +%Y%m%d-%H%M%S).txt"
exec > >(tee -a "$LOG") 2>&1

say "Target: $TARGET   attempts per round: $TRIES   attacker: $(hostname -I | awk '{print $1}')"
nc -z -w 3 "$TARGET" 22 || die "Can't reach SSH on $TARGET:22. Is linux-srv on and UFW allowing the lab subnet?"

say "Round 1: usernames that don't exist"
fake_users=(admin oracle test postgres ubuntu support guest ftp backup deploy git pi)
for ((i = 0; i < TRIES; i++)); do
  u="${fake_users[i % ${#fake_users[@]}]}"
  # No password is sent; sshd still logs "Invalid user <u> from <ip>".
  ssh "${SSH_OPTS[@]}" -o BatchMode=yes -o PubkeyAuthentication=no "$u@$TARGET" true 2>/dev/null || true
  echo "  try $((i + 1)): user=$u -> rejected"
  sleep 1
done

say "Round 2: wrong passwords for '$LAB_SSH_USER'"
# Ask the server which login methods it offers; no password is sent here.
methods="$(ssh "${SSH_OPTS[@]}" -o BatchMode=yes -o PreferredAuthentications=none \
  "$LAB_SSH_USER@$TARGET" true 2>&1 | grep -o 'Permission denied ([^)]*)' || true)"
if [[ "$methods" != *password* && "$methods" != *keyboard-interactive* ]]; then
  warn "  Skipped: $TARGET only accepts SSH keys (${methods:-no answer}),"
  warn "  so wrong-password attempts can't be logged. Run setup-linux-srv.sh on"
  warn "  linux-srv to turn password logins on, then run this script again."
  say "Finished (Round 1 only). Saved this output to $LOG"
  echo "Next: Wazuh dashboard > Threat Hunting > Events, search:  rule.id:(5710 or 5712)"
  exit 0
fi
for ((i = 1; i <= TRIES; i++)); do
  pw="$(openssl rand -hex 8)"      # random wrong password
  sshpass -p "$pw" ssh "${SSH_OPTS[@]}" -o PubkeyAuthentication=no \
    -o PreferredAuthentications=password -o NumberOfPasswordPrompts=1 \
    "$LAB_SSH_USER@$TARGET" true 2>/dev/null \
    && warn "  try $i: UNEXPECTED SUCCESS" || echo "  try $i: user=$LAB_SSH_USER -> wrong password"
  sleep 1
done

say "Finished. Saved this output to $LOG"
echo "Next: Wazuh dashboard > Threat Hunting > Events, search:  rule.id:(5710 or 5712 or 5760 or 5763)"

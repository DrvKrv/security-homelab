#!/usr/bin/env bash
# setup-linux-srv.sh - run ON linux-srv (Ubuntu 24.04), once, after the
# Wazuh agent is installed and shows Active in the dashboard.
#
#   sudo bash setup-linux-srv.sh
#
# What it does:
#   1. Turns on the UFW firewall: block everything incoming except SSH from the
#      lab subnet, and LOG what it blocks (that's what Wazuh will alert on).
#   2. Creates "labuser", a throwaway account for the SSH failed-login exercise.
#      Its password is random and never shown: nobody is meant to log in as it.
#   3. Makes sure SSH accepts password logins, so wrong-password attempts are
#      logged as "Failed password". (You'll turn this OFF again as a
#      remediation step in runbook 05.)
#
# Safe to run more than once.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ $EUID -eq 0 ]] || die "Please run with sudo:  sudo bash $0"

say "1. Firewall (UFW)"
command -v ufw >/dev/null || apt-get install -y ufw
ufw --force reset >/dev/null      # start from a known state; old rules are saved as *.rules.<date>
ufw default deny incoming
ufw default allow outgoing        # agent -> manager traffic (1514/1515) goes out, so it keeps working
ufw allow from "$LAB_SUBNET" to any port 22 proto tcp comment 'SSH from lab only'
ufw logging low                   # log blocked packets (rate-limited)
ufw --force enable
ufw status verbose

say "2. Test account '$LAB_SSH_USER'"
if id "$LAB_SSH_USER" &>/dev/null; then
  echo "  $LAB_SSH_USER already exists"
else
  useradd -m -s /bin/bash -c "Lab test account (failed-login exercise)" "$LAB_SSH_USER"
  echo "$LAB_SSH_USER:$(openssl rand -base64 24)" | chpasswd
  echo "  created $LAB_SSH_USER with a random password nobody knows"
fi

say "3. SSH password authentication"
if sshd -T 2>/dev/null | grep -qi '^passwordauthentication yes'; then
  echo "  already on"
else
  cat > /etc/ssh/sshd_config.d/10-lab-password-auth.conf <<'EOF'
# Added by lab/linux/setup-linux-srv.sh so failed password guesses are logged.
# Remediation (runbook 05): delete this file and set up SSH keys instead.
PasswordAuthentication yes
EOF
  sshd -t
  systemctl restart ssh
  echo "  turned on (via /etc/ssh/sshd_config.d/10-lab-password-auth.conf)"
fi

say "Checks"
echo "  Wazuh agent: $(systemctl is-active wazuh-agent 2>/dev/null || echo 'NOT RUNNING - install it first')"
echo "  Listening TCP ports:"
ss -tlnp | sed 's/^/    /'

cat <<EOF

Done. Optional: snapshot linux-srv's disk in Azure now and call it "baseline" (see runbook 00, step 5).
Screenshot the 'ufw status verbose' output above for your write-up.
EOF

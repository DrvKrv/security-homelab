#!/usr/bin/env bash
# verify.sh - checks that linux-srv's SSH server no longer accepts passwords.
# Run as part of:  ./run.sh verify A3/ssh-keys-only      (on linux-srv)
#
# Asks sshd for its effective settings, including for connections from the lab
# VMs (so a "Match" block can't quietly turn passwords back on for them).
# PASS when: the config is valid, sshd is running, and password and
# keyboard-interactive logins are off everywhere. Read-only.

set -uo pipefail
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
WAZUH_IP="10.0.1.10"; WIN_IP="10.0.1.20"
# shellcheck source=/dev/null
[[ -f "$LAB_DIR/lab.env" ]] && source "$LAB_DIR/lab.env"
fail=0

check() { # check "<description>" <0-if-good>
  if [[ "$2" -eq 0 ]]; then printf '  [ OK ] %s\n' "$1"; else printf '  [FAIL] %s\n' "$1" >&2; fail=1; fi
}
check_if() { # check_if "<description>" <test command...>: OK if the command succeeds
  local d="$1"; shift
  if "$@"; then check "$d" 0; else check "$d" 1; fi
}
setting() { # setting <name> [match spec]: the effective value sshd reports
  if [[ -n "${2:-}" ]]; then sudo sshd -T -C "$2" 2>/dev/null; else sudo sshd -T 2>/dev/null; fi \
    | awk -v k="$1" 'tolower($1) == k && !done { print tolower($2); done = 1 }'
}

running() { sudo systemctl is-active --quiet ssh || sudo systemctl is-active --quiet ssh.socket; }
check_if "the SSH configuration is valid (sshd -t)" sudo sshd -t
check_if "the SSH service is running" running
check_if "password logins are off" [ "$(setting passwordauthentication)" = no ]
check_if "keyboard-interactive (another way to ask for a password) is off" \
  [ "$(setting kbdinteractiveauthentication)" = no ]

for who in "win-srv $WIN_IP" "wazuh $WAZUH_IP"; do
  read -r name addr <<< "$who"
  check_if "password logins are off for connections from $name too" \
    [ "$(setting passwordauthentication "user=$(id -un),host=$name,addr=$addr")" = no ]
done

check_if "root can't log in with a password" [ "$(setting permitrootlogin)" != yes ]
check_if "your own account still has an SSH key on this server" [ -s "$HOME/.ssh/authorized_keys" ]

echo
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed. Now prove it from another VM, and open a new key-based session (see the brief)."
  exit 0
fi
echo "One or more checks failed. See the [FAIL] lines above, fix, and run verify again." >&2
exit 1

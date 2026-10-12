#!/usr/bin/env bash
# verify.sh - checks that the Level 3 Linux backdoor account has been fully
# removed. Run as part of: ./run.sh verify 3/linux-backdoor-user  (on linux-srv)
#
# PASS when: the account does not exist, is not in the sudo group, and its home
# directory is gone. Read-only; it changes nothing.

set -uo pipefail
USER_NAME="${BACKDOOR_USER:-svc_backup}"
fail=0

check() { # check "<description>" <0-if-good>
  if [[ "$2" -eq 0 ]]; then
    printf '  [ OK ] %s\n' "$1"
  else
    printf '  [FAIL] %s\n' "$1" >&2
    fail=1
  fi
}

echo "Verifying removal of backdoor account: $USER_NAME"

# 1. account must not exist
if getent passwd "$USER_NAME" >/dev/null; then acct_gone=1; else acct_gone=0; fi
check "account '$USER_NAME' no longer exists in /etc/passwd" "$acct_gone"

# 2. must not be in the sudo group
if getent group sudo | tr ',' '\n' | grep -qx "$USER_NAME"; then in_sudo=1; else in_sudo=0; fi
check "'$USER_NAME' is not a member of the sudo group" "$in_sudo"

# 3. home directory must be gone
if [[ -d "/home/$USER_NAME" ]]; then home_left=1; else home_left=0; fi
check "home directory /home/$USER_NAME removed" "$home_left"

# 4. no lingering processes owned by the account
if pgrep -u "$USER_NAME" >/dev/null 2>&1; then procs=1; else procs=0; fi
check "no running processes owned by '$USER_NAME'" "$procs"

echo
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed - the backdoor account is fully removed."
  exit 0
else
  echo "One or more checks failed. See [FAIL] lines above, fix, and re-run." >&2
  echo "Tip: './run.sh reset 3/linux-backdoor-user' shows the correct cleanup command." >&2
  exit 1
fi

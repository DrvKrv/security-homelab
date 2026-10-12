# shellcheck shell=bash
EX_TITLE="Unexpected sudo rights: who granted them, when"
EX_SUMMARY="An account on linux-srv can suddenly run admin commands. Work out how, who did it, and when."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="linux-srv"
EX_FIX_WHERE=""
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1548.003"

# Staging grants sudo rights to the lab test account with a standard sudoers
# drop-in file (checked with visudo before it's installed), not with the sudo
# group. The file name, the command allowed and whether a password is needed
# are random. Names have no dot, because sudo skips files in sudoers.d whose
# names contain one.
LAB_SUDO_FILES="80-backup-jobs 90-helpdesk 95-ops-temp 99-vendor-support"

ex_stage() {
  local acct="${LAB_SSH_USER:-labuser}" f cmd nopw tmp
  if ! id "$acct" &>/dev/null; then
    echo "The lab test account from lab/linux/setup-linux-srv.sh doesn't exist on this VM. Run that setup first."
    return 1
  fi
  f="$(pick $LAB_SUDO_FILES)"
  cmd="$(pick ALL /usr/bin/apt /usr/bin/systemctl /usr/bin/journalctl)"
  nopw="$(pick 'NOPASSWD: ' '')"
  answer "account" "$acct"
  answer "file" "/etc/sudoers.d/$f"
  answer "grant" "$acct ALL=(ALL) $nopw$cmd"
  tmp="$(mktemp)"
  printf '%s ALL=(ALL) %s%s\n' "$acct" "$nopw" "$cmd" > "$tmp"
  sudo visudo -cf "$tmp"
  sudo install -m 0440 -o root -g root "$tmp" "/etc/sudoers.d/$f"
  rm -f "$tmp"
}

ex_reset() {
  local f
  for f in $LAB_SUDO_FILES; do sudo rm -f "/etc/sudoers.d/$f"; done
  sudo visudo -c
}

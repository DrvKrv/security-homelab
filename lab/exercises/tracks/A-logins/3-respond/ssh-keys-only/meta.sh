# shellcheck shell=bash
EX_TITLE="Switch SSH to keys only and prove passwords stop working"
EX_SUMMARY="Password logins are back on for SSH on linux-srv. Turn them off for good and prove it."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="linux-srv"
EX_FIX_WHERE=""
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="yes"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1110"

# Staging drops a small sshd setting file that turns password logins on, the
# same setting lab/linux/setup-linux-srv.sh uses, under a random name. Files in
# sshd_config.d are read in name order and sshd keeps the first value it sees,
# so a name sorting before the image's own "no" file (50-cloud-init.conf or
# 60-cloudimg-settings.conf) wins.
LAB_PW_FILES="05-legacy-logins.conf 10-helpdesk-access.conf 20-vendor-support.conf 15-temp-migration.conf"

ex_stage() {
  local f; f="$(pick $LAB_PW_FILES)"
  answer "file" "/etc/ssh/sshd_config.d/$f"
  printf '%s\n' "# $(pick 'Temporary' 'Requested by support' 'Needed for the migration'), remove later." \
    'PasswordAuthentication yes' | sudo tee "/etc/ssh/sshd_config.d/$f" >/dev/null
  sudo sshd -t
  sudo systemctl restart ssh
  # Fail the staging (and say so) if sshd didn't pick the setting up.
  sudo sshd -T | grep -i '^passwordauthentication yes' >/dev/null
}

ex_reset() {
  local f
  for f in $LAB_PW_FILES; do sudo rm -f "/etc/ssh/sshd_config.d/$f"; done
  sudo sshd -t && sudo systemctl restart ssh
  sudo sshd -T | grep -i '^passwordauthentication'
}

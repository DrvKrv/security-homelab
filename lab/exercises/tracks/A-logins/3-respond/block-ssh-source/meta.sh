# shellcheck shell=bash
EX_TITLE="Block the attacking source and prove it's blocked"
EX_SUMMARY="Someone keeps guessing at SSH on linux-srv. Stop them at the firewall, then prove it."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="wazuh"
EX_FIX_WHERE="linux-srv"
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="yes"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1110.001"

# A random number of tries each time, from wazuh against linux-srv (lib/staging.sh).
ex_stage() { stage_ssh_bruteforce; }

# Runs on linux-srv. Deletes every UFW rule that denies or rejects the wazuh VM
# on port 22 (or on every port), highest rule number first so the numbers of the
# rules still to delete don't shift.
ex_reset() {
  local n
  for n in $(sudo ufw status numbered \
      | grep -v '(v6)' \
      | grep -E "^\[ *[0-9]+\] +(22|22/tcp|Anywhere) +(DENY|REJECT) IN +${WAZUH_IP//./\\.}(/32)?( |$)" \
      | sed -E 's/^\[ *([0-9]+)\].*/\1/' | sort -rn); do
    sudo ufw --force delete "$n"
  done
  sudo ufw status numbered
}

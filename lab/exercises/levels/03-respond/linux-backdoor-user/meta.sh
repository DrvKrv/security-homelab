# shellcheck shell=bash
EX_TITLE="Remove the Linux backdoor account"
EX_SUMMARY="Clean up the rogue sudo account and prove the box is clean."
EX_STAGE_WHERE="linux-srv"
EX_STAGE="sudo bash linux/simulate-account-changes.sh attack"
EX_RESET="sudo bash linux/simulate-account-changes.sh cleanup"
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="yes"

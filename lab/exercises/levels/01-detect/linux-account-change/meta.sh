# shellcheck shell=bash
EX_TITLE="A new Linux admin account appears"
EX_SUMMARY="A user was added and given sudo on linux-srv. Spot it in Wazuh."
EX_STAGE_WHERE="linux-srv"
EX_STAGE="sudo bash linux/simulate-account-changes.sh attack"
EX_RESET="sudo bash linux/simulate-account-changes.sh cleanup"
EX_WAZUH_SEARCH="rule.id:(5902 OR 5555 OR 2961 OR 100110) OR rule.groups:syscheck"
EX_HAS_VERIFY="no"

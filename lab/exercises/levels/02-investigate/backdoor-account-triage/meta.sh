# shellcheck shell=bash
EX_TITLE="Triage the backdoor account"
EX_SUMMARY="A rogue admin account exists. Scope it fully before touching it."
EX_STAGE_WHERE="linux-srv"
EX_STAGE="sudo bash linux/simulate-account-changes.sh attack"
EX_RESET="sudo bash linux/simulate-account-changes.sh cleanup"
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"

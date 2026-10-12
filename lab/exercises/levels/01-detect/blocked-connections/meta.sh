# shellcheck shell=bash
EX_TITLE="Firewall-blocked connections"
EX_SUMMARY="Something tried services linux-srv doesn't offer. Find the UFW blocks."
EX_STAGE_WHERE="wazuh"
EX_STAGE="bash linux/simulate-blocked-connections.sh"
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"

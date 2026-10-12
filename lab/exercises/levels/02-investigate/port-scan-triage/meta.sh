# shellcheck shell=bash
EX_TITLE="Triage the port scan"
EX_SUMMARY="A scan hit linux-srv. Work out what's exposed and what the risk is."
EX_STAGE_WHERE="wazuh"
EX_STAGE="bash linux/run-authorized-nmap-scan.sh"
EX_RESET=""
EX_WAZUH_SEARCH="rule.id:(100100 OR 100102) AND agent.name:linux-srv"
EX_HAS_VERIFY="no"

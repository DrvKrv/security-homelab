# shellcheck shell=bash
EX_TITLE="A port scan against linux-srv"
EX_SUMMARY="Many ports probed fast. Find the port-scan correlation alert."
EX_STAGE_WHERE="wazuh"
EX_STAGE="bash linux/run-authorized-nmap-scan.sh"
EX_RESET=""
EX_WAZUH_SEARCH="rule.id:(100100 OR 100102)"
EX_HAS_VERIFY="no"

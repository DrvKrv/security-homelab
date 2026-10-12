# shellcheck shell=bash
EX_TITLE="SSH brute force against linux-srv"
EX_SUMMARY="Someone is guessing SSH logins. Find and identify the alert in Wazuh."
EX_STAGE_WHERE="wazuh"
EX_STAGE="bash linux/simulate-ssh-bruteforce.sh"
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"

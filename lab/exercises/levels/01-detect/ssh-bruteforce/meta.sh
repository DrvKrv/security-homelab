# shellcheck shell=bash
EX_TITLE="SSH brute force against linux-srv"
EX_SUMMARY="Someone is guessing SSH logins. Find and identify the alert in Wazuh."
EX_STAGE_WHERE="wazuh"
EX_STAGE="bash linux/simulate-ssh-bruteforce.sh"
EX_RESET=""
EX_WAZUH_SEARCH="rule.id:(5710 OR 5712 OR 5760 OR 5763)"
EX_HAS_VERIFY="no"

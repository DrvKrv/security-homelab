# shellcheck shell=bash
EX_TITLE="SSH brute force against linux-srv"
EX_SUMMARY="Someone is guessing SSH logins. Find and identify the alert in Wazuh."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="wazuh"
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"
EX_ATTACK="T1110.001 Brute Force: Password Guessing"

# A random number of tries each time, from wazuh against linux-srv.
ex_stage() { stage_ssh_bruteforce; }

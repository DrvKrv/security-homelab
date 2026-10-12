# shellcheck shell=bash
EX_TITLE="Did the SSH attacker get in?"
EX_SUMMARY="Reconstruct an SSH attack timeline and decide if it succeeded."
EX_STAGE_WHERE="wazuh"
EX_STAGE="bash linux/simulate-ssh-bruteforce.sh"
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"

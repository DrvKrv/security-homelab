# shellcheck shell=bash
EX_TITLE="Remove the Linux backdoor account"
EX_SUMMARY="Clean up the rogue sudo account and prove the box is clean."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="linux-srv"
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="yes"
EX_ATTACK="T1136.001 Create Account: Local Account"

# A backdoor admin account with a random service-style name (see lib/staging.sh).
ex_stage() { stage_backdoor_account; }
ex_reset() { reset_backdoor_account; }

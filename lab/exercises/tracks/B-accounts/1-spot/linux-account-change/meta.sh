# shellcheck shell=bash
EX_TITLE="A new Linux admin account appears"
EX_SUMMARY="A user was added and given sudo on linux-srv. Spot it in Wazuh."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="linux-srv"
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"
EX_ATTACK="T1136.001 Create Account: Local Account; T1098 Account Manipulation"

# A backdoor admin account with a random service-style name (see lib/staging.sh).
ex_stage() { stage_backdoor_account; }
ex_reset() { reset_backdoor_account; }

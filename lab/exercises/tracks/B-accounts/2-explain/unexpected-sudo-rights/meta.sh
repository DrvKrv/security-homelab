# shellcheck shell=bash
EX_TITLE="Unexpected sudo rights: who granted them, when"
EX_SUMMARY="An account on linux-srv can suddenly run admin commands. Work out how, who did it, and when."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="linux-srv"
EX_FIX_WHERE=""
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1548.003"

# A sudoers drop-in grant with random details (see lib/staging.sh).
ex_stage() { stage_sudoers_grant; }
ex_reset() { reset_sudoers_grant; }

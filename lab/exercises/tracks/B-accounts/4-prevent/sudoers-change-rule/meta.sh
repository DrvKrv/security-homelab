# shellcheck shell=bash
EX_TITLE="Alert on changes to sudo rights, then test it"
EX_SUMMARY="Admin rights can be granted without touching the sudo group. Write a rule that notices, and prove it fires."
EX_ENV="core"
EX_ROUND="2"
EX_WHERE="linux-srv"
EX_FIX_WHERE="wazuh"
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="yes"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1548.003"

# The same kind of grant as B2, with random details (see lib/staging.sh).
ex_stage() { stage_sudoers_grant; }
ex_reset() { reset_sudoers_grant; }

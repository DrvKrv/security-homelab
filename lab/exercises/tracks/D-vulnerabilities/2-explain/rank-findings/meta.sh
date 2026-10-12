# shellcheck shell=bash
EX_TITLE="Rank a list of findings by real risk, not just score"
EX_SUMMARY="Six findings, one patch window. Put them in order and defend the order."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="none"
EX_FIX_WHERE=""
EX_STAGE="# Nothing to stage: you rank findings Wazuh already reported. Your assignment above adds a twist."
EX_RESET=""
EX_WAZUH_SEARCH=""
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK=""

# The findings are always two per VM; the twist changes each time, so repeating
# the lesson means re-ranking under a different situation.
ex_assign() {
  echo "Findings: two from each VM (linux-srv, win-srv, wazuh), at least two different severities."
  echo "Twist:    $(pick \
    'none. Rank them as the lab is today.' \
    'pretend someone opened RDP on win-srv to the whole internet by mistake (they did not).' \
    'you may only take one VM down for patching this week.' \
    'pretend linux-srv now hosts the company payroll system.' \
    'pretend your lowest-ranked finding was just added to CISA KEV.')"
}

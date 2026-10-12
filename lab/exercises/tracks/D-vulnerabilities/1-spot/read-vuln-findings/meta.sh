# shellcheck shell=bash
EX_TITLE="Read Wazuh's vulnerability findings for one VM"
EX_SUMMARY="Wazuh compares each VM's software with public vulnerability data. Read what it found for one VM."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="none"
EX_FIX_WHERE=""
EX_STAGE="# Nothing to stage: the findings are already in Wazuh. Your assignment above says which VM to read."
EX_RESET=""
EX_WAZUH_SEARCH=""
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK=""

# A different VM and starting severity each time you start the lesson.
ex_assign() {
  echo "VM to read:             $(pick linux-srv win-srv wazuh)"
  echo "Severity to start with: $(pick Critical High)"
  echo "(If there are none at that severity, use the next one down.)"
}

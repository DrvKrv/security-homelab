# shellcheck shell=bash
EX_TITLE="Research one CVE: CVSS, NVD record, does it really apply here?"
EX_SUMMARY="Take one finding from Wazuh and research it properly, ending with a verdict you can defend."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="none"
EX_FIX_WHERE=""
EX_STAGE="# Nothing to stage: you research a finding Wazuh already reported. Your assignment above says which one."
EX_RESET=""
EX_WAZUH_SEARCH=""
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK=""

# A different VM and a different way of choosing the finding each time.
ex_assign() {
  echo "VM:          $(pick linux-srv win-srv wazuh)"
  echo "Research:    $(pick \
    'the finding with the highest CVSS score' \
    'the most recently published High or Critical finding' \
    'a finding in a package that runs a network service (or the OS itself on win-srv)' \
    'a Medium finding that you suspect is less serious than it sounds')"
}

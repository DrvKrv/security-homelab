# shellcheck shell=bash
EX_TITLE="Map your detections to MITRE ATT&CK and publish a coverage map"
EX_SUMMARY="List what the lab can detect, tag each detection with its ATT&CK technique, and be honest about the gaps."
EX_ENV="detect"
EX_ROUND="2"
EX_WHERE="none"
EX_FIX_WHERE=""
EX_STAGE="# Nothing to stage: you work from the rules, tests and lessons you already have, and Atomic Red Team for one gap."
EX_RESET=""
EX_WAZUH_SEARCH=""
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK=""

# A different technique to test for real each time.
ex_assign() {
  echo "Technique to test with Atomic Red Team this time: $(pick T1136.001 T1053.005 T1059.001 T1547.001 T1087.001)"
  echo "(Read its tests with -ShowDetailsBrief first, pick one, run it, then run its -Cleanup.)"
}
# The concept uses T1110 / T1110.001 as the example of what an ATT&CK id looks like.
EX_CHECK_ALLOW="T1110 T1110.001"

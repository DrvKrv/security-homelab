# shellcheck shell=bash
EX_TITLE="Spot an unusual program running on linux-srv"
EX_SUMMARY="A program is running from an odd place on linux-srv. Find it."
EX_ENV="detect"
EX_ROUND="2"
EX_WHERE="linux-srv"
EX_FIX_WHERE=""
# Staging is randomized, so it lives in the ex_stage / ex_reset functions below.
EX_STAGE="ex_stage"
EX_RESET="ex_reset"
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1036.005"

# A harmless stand-in: a copy of /bin/sleep given a daemon-ish name and run from a
# hidden directory under /tmp. It does nothing but sleep. The "unusual" part is the
# name and the location, not the behaviour.
LAB_PROC_NAMES="kworkerx dbus-cache sysupd netd-helper"
LAB_PROC_UNIT="lab-unusual-proc"
LAB_PROC_DIR="/tmp/.cache"

ex_stage() {
  # 1. pick an odd, daemon-looking name and record it for reveal/verify
  local name; name="$(pick $LAB_PROC_NAMES)"
  answer "program_name" "$name"
  answer "program_path" "$LAB_PROC_DIR/$name"
  # 2. make the hidden directory the program will run from
  sudo mkdir -p "$LAB_PROC_DIR"
  # 3. copy the harmless /bin/sleep there under the odd name
  sudo cp /bin/sleep "$LAB_PROC_DIR/$name"
  # 4. run it as a long sleep under a known transient unit, so it keeps running and reset can find it
  sudo systemd-run --unit="$LAB_PROC_UNIT" --description="lab F1 unusual program" "$LAB_PROC_DIR/$name" 86400
}

ex_reset() {
  # 1. stop the transient unit if it is still running
  sudo systemctl stop "$LAB_PROC_UNIT" 2>/dev/null || true
  # 2. remove every candidate stand-in this lesson could have created
  local name
  for name in $LAB_PROC_NAMES; do sudo rm -f "$LAB_PROC_DIR/$name"; done
  # 3. remove the hidden directory if it is now empty
  sudo rmdir "$LAB_PROC_DIR" 2>/dev/null || true
}

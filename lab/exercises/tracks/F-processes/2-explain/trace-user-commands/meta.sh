# shellcheck shell=bash
EX_TITLE="Trace what a user ran after logging in"
EX_SUMMARY="A user ran a handful of commands on linux-srv. Rebuild what they did."
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
EX_ATTACK="T1059.004"

# A harmless stand-in: create a temporary local user and run a few read-only
# discovery commands as that user. Nothing is changed on the system, and the
# user is removed in ex_reset.
LAB_USERS="jmorris pchen dkhan rsingh"

ex_stage() {
  # 1. pick a plausible username and record it for reveal
  local u; u="$(pick $LAB_USERS)"
  answer "username" "$u"
  # 2. create the temporary local user (with a home directory)
  sudo useradd -m -s /bin/bash "$u"
  # 3. run a few harmless, read-only discovery commands as that user
  sudo -u "$u" id
  sudo -u "$u" uname -a
  sudo -u "$u" cat /etc/os-release
  sudo -u "$u" ls /home
  # 4. record the exact commands that were run, in order
  answer "commands" "id; uname -a; cat /etc/os-release; ls /home"
}

ex_reset() {
  # remove every candidate user this lesson could have created, home dir and all
  local u
  for u in $LAB_USERS; do
    # kill any leftover processes, then delete the account and its home directory
    sudo pkill -u "$u" 2>/dev/null || true
    sudo userdel -r "$u" 2>/dev/null || true
  done
}

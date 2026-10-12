# shellcheck shell=bash
EX_TITLE="Where did the blocked traffic come from, and did anything get through?"
EX_SUMMARY="linux-srv's firewall refused some connections. Trace them to their source and check whether anything else got in."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="wazuh"
EX_FIX_WHERE=""
EX_STAGE=""
EX_RESET=""
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1046"

# Staging reuses lab/linux/simulate-blocked-connections.sh. On some runs the same
# source also opens one ordinary SSH connection to linux-srv, which the firewall
# allows; it offers no key or password, so it never logs in. Whether that happens,
# and whether before or after the blocked attempts, is random.
c2_reach_ssh() {
  sleep "$(rand_between 5 40)"
  ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "${LAB_SSH_USER:-labuser}@$LINUX_IP" true || true
}

ex_stage() {
  local when; when="$(pick before after none none)"
  answer "source" "wazuh ($WAZUH_IP)"
  answer "target" "linux-srv ($LINUX_IP)"
  if [[ "$when" == none ]]; then
    answer "did anything get through" "no: every connection from the source was refused"
  else
    answer "did anything get through" "yes: one SSH connection $when the blocked attempts reached sshd (allowed port) but did not log in"
  fi
  [[ "$when" == before ]] && c2_reach_ssh
  bash linux/simulate-blocked-connections.sh "$LINUX_IP"
  [[ "$when" == after ]] && c2_reach_ssh
  return 0
}

# shellcheck shell=bash
# staging.sh - staging steps shared by several lessons. engine.sh sources it.
#
# Each step reuses a script from lab/linux (or a standard admin tool) with
# randomized details, and records what it chose with `answer`, so `reveal` can
# show this run's details and verify.sh can check against them. They run from
# lab/ with their output going to the staging log, never to the screen.

# Service-style names a backdoor account might hide behind.
ACCOUNT_POOL=(svc_backup svc_monitor sysmaint backup_svc ops_agent svc_update svc_patch it_tmp)

# Pick an account name from the pool that doesn't exist on this machine yet.
fresh_account() {
  local acct tries=0
  acct="$(pick "${ACCOUNT_POOL[@]}")"
  while id "$acct" &>/dev/null && (( tries++ < 20 )); do acct="$(pick "${ACCOUNT_POOL[@]}")"; done
  id "$acct" &>/dev/null && { echo "Every name in the pool already exists. Run ./run.sh reset first." >&2; return 1; }
  echo "$acct"
}

# SSH brute force from wazuh against linux-srv, with a random number of tries.
stage_ssh_bruteforce() {
  local tries; tries="$(rand_between 8 16)"
  answer "source" "wazuh ($WAZUH_IP)"
  answer "target" "linux-srv ($LINUX_IP)"
  answer "attempts per round" "$tries"
  bash linux/simulate-ssh-bruteforce.sh "$LINUX_IP" "$tries"
}

# A backdoor admin account on linux-srv with a random service-style name.
stage_backdoor_account() {
  local acct; acct="$(fresh_account)"
  answer "account" "$acct"
  sudo bash linux/simulate-account-changes.sh attack "$acct"
}

reset_backdoor_account() {
  local acct; acct="$(recall account)"
  if [[ -z "$acct" ]]; then
    echo "No staged account is recorded on this VM, so there's nothing to reset."
  elif ! id "$acct" &>/dev/null; then
    echo "The staged account '$acct' is already gone."
  else
    sudo bash linux/simulate-account-changes.sh cleanup "$acct"
  fi
}

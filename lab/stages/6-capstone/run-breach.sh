#!/usr/bin/env bash
# run-breach.sh - stage the capstone's multi-step breach (unit 10), quietly.
#
# This is a CONDUCTOR, not an attack tool. It does not contain any attack code of
# its own: it decides which of the lab's existing simulation scripts run, in what
# order and with what timing, to tell one coherent breach story across machines.
# Every step reuses a script already in lab/linux or lab/windows, or a manual
# action against OWASP Juice Shop. It only ever targets your own lab VMs.
#
# The breach spans more than one VM, so you run this on each one; the plan is
# computed from a shared seed, so the pieces line up into one timeline:
#   - on wazuh      it runs the network-origin steps (recon, SSH guessing, probing)
#   - on linux-srv  it plants the Linux persistence account
#   - on win-srv     the Windows steps run via Invoke-BreachStep.ps1 (see the plan)
#
#   bash run-breach.sh plan [--seed N] [--envs core,web,ad] [--within 90m]
#                                     # roll the plan once, seal the answer key
#   bash run-breach.sh arm            # schedule THIS VM's steps at their offsets
#   bash run-breach.sh fire            # run THIS VM's steps now, in order
#   bash run-breach.sh status          # what is pending/fired here (no spoilers)
#   bash run-breach.sh disarm          # cancel anything armed on this VM
#   bash run-breach.sh hint            # one incident-response nudge at a time
#   bash run-breach.sh reveal          # print the sealed answer key
#   bash run-breach.sh cleanup         # undo persistence this VM created
#
# Quiet by design: plan/arm/fire print only "done". The plan, timings and the
# accounts used live in the git-ignored spoilers/ folder; `reveal` shows them.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$HERE/../.." && pwd)"          # the repo's lab/ folder
SPOILERS="$HERE/spoilers"
PLAN_MD="$SPOILERS/breach-plan.md"
STATE="$SPOILERS/breach-state"                 # seed/envs/within for this plan
PY="$(command -v python3 || true)"

say()  { printf '\033[36m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

[[ -n "$PY" ]] || die "python3 is required but not found."

# Lab addresses, so the reused scripts' "$LINUX_IP" etc. resolve. lab.env wins.
WAZUH_IP="10.0.1.10"; WIN_IP="10.0.1.20"; LINUX_IP="10.0.1.30"; LAB_SUBNET="10.0.1.0/24"
# shellcheck source=/dev/null
[[ -f "$LAB_DIR/lab.env" ]] && source "$LAB_DIR/lab.env"
export WAZUH_IP WIN_IP LINUX_IP LAB_SUBNET

# Which VM is this? (Azure names the OS host after the VM.) Override for testing.
this_host() { local h="${LAB_BREACH_HOST:-$(hostname -s 2>/dev/null || hostname)}"; echo "${h,,}"; }

# Plan parameters. Flags (parsed per-command) win; the saved state file fills in
# anything a flag did not set, so you can `arm` with no flags after `plan`.
SEED=""; ENVS=""; WITHIN=""
load_state() {
  local f_seed="$SEED" f_envs="$ENVS" f_within="$WITHIN"
  if [[ -f "$STATE" ]]; then
    # shellcheck source=/dev/null
    source "$STATE"
  fi
  [[ -n "$f_seed" ]]   && SEED="$f_seed"
  [[ -n "$f_envs" ]]   && ENVS="$f_envs"
  [[ -n "$f_within" ]] && WITHIN="$f_within"
  ENVS="${ENVS:-core}"; WITHIN="${WITHIN:-0}"
}

# Emit THIS VM's runnable steps as:  offset_min<TAB>key<TAB>command
steps_for_host() {
  "$PY" "$HERE/breach-plan.py" --seed "$SEED" --envs "$ENVS" --within "$WITHIN" \
    --host "$(this_host)" --json \
  | "$PY" -c 'import json,sys
for s in json.load(sys.stdin):
    if "command" in s:
        print("%s\t%s\t%s" % (s["offset_min"], s["key"], s["command"]))'
}

run_one() { # run_one <command>  (from lab/, quietly, to the staging log)
  local cmd="$1" log
  log="$SPOILERS/fired-$(date +%Y%m%d-%H%M%S)-$RANDOM.log"
  ( cd "$LAB_DIR" && eval "$cmd" ) >"$log" 2>&1
}

cmd="${1:-status}"; shift || true

case "$cmd" in
  plan)
    # Parse flags.
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --seed)   SEED="$2"; shift 2 ;;
        --envs)   ENVS="$2"; shift 2 ;;
        --within) WITHIN="$2"; shift 2 ;;
        *) die "Unknown flag '$1'. See the header of this script." ;;
      esac
    done
    mkdir -p "$SPOILERS"
    ENVS="${ENVS:-core}"; WITHIN="${WITHIN:-0}"
    [[ -n "$SEED" ]] || SEED="$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')"
    printf 'SEED=%s\nENVS=%s\nWITHIN=%s\n' "$SEED" "$ENVS" "$WITHIN" > "$STATE"
    "$PY" "$HERE/breach-plan.py" --seed "$SEED" --envs "$ENVS" --within "$WITHIN" \
      --answer-key > "$PLAN_MD"
    echo "done"
    warn "The sealed plan (the answer key) is in $PLAN_MD."
    warn "Use this SEED to arm the other VMs:  $SEED"
    warn "If you plan to investigate this yourself, do not open that plan file: let the breach run, then check against it with 'reveal'."
    ;;

  arm)
    while [[ $# -gt 0 ]]; do case "$1" in --seed) SEED="$2"; shift 2 ;; --envs) ENVS="$2"; shift 2 ;; --within) WITHIN="$2"; shift 2 ;; *) shift ;; esac; done
    load_state
    [[ -n "$SEED" ]] || die "No plan yet. Run 'plan' first, or pass --seed <N> (same seed as the other VMs)."
    mkdir -p "$SPOILERS"
    : > "$SPOILERS/armed-pids"
    local_count=0
    while IFS=$'\t' read -r off key cmd; do
      [[ -z "$key" ]] && continue
      secs="$("$PY" -c "print(int(float('$off')*60))")"
      ( trap '' HUP; sleep "$secs"; cd "$LAB_DIR" && eval "$cmd" ) \
        >"$SPOILERS/fired-$key.log" 2>&1 </dev/null &
      echo "$! $key" >> "$SPOILERS/armed-pids"
      local_count=$((local_count+1))
    done < <(steps_for_host)
    echo "done"
    [[ $local_count -eq 0 ]] && warn "Nothing on this VM ($(this_host)) to arm for this plan; its steps run on another VM."
    ;;

  fire)
    while [[ $# -gt 0 ]]; do case "$1" in --seed) SEED="$2"; shift 2 ;; --envs) ENVS="$2"; shift 2 ;; --within) WITHIN="$2"; shift 2 ;; *) shift ;; esac; done
    load_state
    [[ -n "$SEED" ]] || die "No plan yet. Run 'plan' first, or pass --seed <N>."
    # Fire in order, now (ignores offsets). Sudo steps prompt once up front.
    if steps_for_host | cut -f3 | grep -q sudo; then sudo -v; fi
    n=0
    while IFS=$'\t' read -r off key cmd; do
      [[ -z "$key" ]] && continue
      run_one "$cmd"
      n=$((n+1))
      sleep 2
    done < <(steps_for_host)
    echo "done"
    [[ $n -eq 0 ]] && warn "Nothing on this VM ($(this_host)) to fire for this plan."
    ;;

  status)
    load_state
    host="$(this_host)"
    if [[ ! -f "$STATE" ]]; then echo "No plan here yet. Run: bash $0 plan"; exit 0; fi
    echo "A plan exists (its contents are sealed in spoilers/). This VM: $host"
    if [[ -f "$SPOILERS/armed-pids" && -s "$SPOILERS/armed-pids" ]]; then
      pending=0
      while read -r pid _; do kill -0 "$pid" 2>/dev/null && pending=$((pending+1)); done < "$SPOILERS/armed-pids"
      echo "Armed steps still waiting to fire on this VM: $pending"
    else
      echo "Nothing armed on this VM."
    fi
    fired=$(find "$SPOILERS" -maxdepth 1 -name 'fired-*.log' 2>/dev/null | wc -l)
    echo "Step logs recorded on this VM so far: $fired  (contents are spoilers)"
    ;;

  disarm)
    if [[ -f "$SPOILERS/armed-pids" ]]; then
      while read -r pid _; do kill "$pid" 2>/dev/null || true; done < "$SPOILERS/armed-pids"
      : > "$SPOILERS/armed-pids"
      say "Cancelled anything still waiting to fire on this VM."
    else
      say "Nothing armed on this VM."
    fi
    ;;

  hint)
    track="$SPOILERS/hint-count"; mkdir -p "$SPOILERS"
    n=0; [[ -f "$track" ]] && n="$(cat "$track")"
    hints=(
      "Start by scoping, not fixing. Which machines and which accounts show anything unusual, and from when? Build a timeline before you touch anything."
      "An incident this size is several alerts that belong together. Line them up by time: recon, then login attempts, then a change on a host, then probing elsewhere."
      "Pivot on the source address. One attacker tends to show up across several of the steps. Following one address often connects the dots."
      "A new privileged account appearing in the middle of all this is the attacker's persistence. Note when it was created and by whom, do not delete it yet."
      "Write the timeline into docs/incidents/TEMPLATE-final-report.md as you go. Then check it against: bash run-breach.sh reveal"
    )
    if (( n >= ${#hints[@]} )); then echo "No more hints. Compare your timeline with:  bash $0 reveal"
    else printf 'Hint %d of %d:\n  %s\n' "$((n+1))" "${#hints[@]}" "${hints[$n]}"; echo "$((n+1))" > "$track"; fi
    ;;

  reveal)
    if [[ -s "$PLAN_MD" ]]; then
      say "Try to finish your own timeline first. Showing the sealed plan in 3s (Ctrl-C to stop)..."
      sleep 3 || true
      cat "$PLAN_MD"
      echo
      echo "This VM's step logs (raw output of each step that ran here) are in:"
      find "$SPOILERS" -maxdepth 1 -name 'fired-*.log' 2>/dev/null | sed 's/^/  /' || true
    else
      warn "No sealed plan on this VM. If the breach was planned on another VM, run"
      warn "'reveal' there, or re-create the answer key here with the shared seed:"
      warn "  bash $0 plan --seed <N> --envs <...> --within <...>"
    fi
    ;;

  cleanup)
    while [[ $# -gt 0 ]]; do case "$1" in --seed) SEED="$2"; shift 2 ;; --envs) ENVS="$2"; shift 2 ;; --within) WITHIN="$2"; shift 2 ;; *) shift ;; esac; done
    load_state
    [[ -n "$SEED" ]] || die "No plan here to clean up. Pass --seed <N> if you planned on another VM."
    # Run the cleanup command for any persistence step that belongs to this VM.
    undo="$("$PY" "$HERE/breach-plan.py" --seed "$SEED" --envs "$ENVS" --within "$WITHIN" --host "$(this_host)" --json \
      | "$PY" -c 'import json,sys
for s in json.load(sys.stdin):
    if s.get("cleanup"): print(s["cleanup"])')"
    if [[ -z "$undo" ]]; then say "Nothing this VM created needs undoing."; exit 0; fi
    say "Undoing persistence created on this VM:"
    echo "$undo" | sed 's/^/  /'
    [[ "$undo" == *sudo* ]] && sudo -v
    if ( cd "$LAB_DIR" && eval "$undo" ) >/dev/null 2>&1; then
      say "Done."
    else
      warn "Cleanup reported a problem; check by hand."
    fi
    ;;

  *)
    die "Usage: bash $0 {plan|arm|fire|status|disarm|hint|reveal|cleanup}"
    ;;
esac

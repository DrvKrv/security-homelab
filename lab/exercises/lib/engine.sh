# shellcheck shell=bash
# engine.sh - shared logic for the lab exercise runner. Not run directly; run.sh sources it.
#
# An "exercise" is a directory under levels/NN-name/<variant>/ containing:
#   meta.sh       - variables describing the exercise (sourced; see FIELDS below)
#   brief.md      - the goal + progressive hints shown to the learner
#   solution.md   - the answer key (only shown with `reveal`)
#   verify.sh     - optional; exits 0 when the learner's fix/cleanup is correct
#
# meta.sh FIELDS:
#   EX_TITLE        one-line name
#   EX_SUMMARY      one sentence shown in the catalog
#   EX_STAGE_WHERE  which VM to run the staging on: wazuh | linux-srv | win-srv
#   EX_STAGE        command that stages the incident. This REFERENCES an existing
#                   script in lab/ (it does not contain attack logic itself).
#   EX_RESET        optional command that undoes the staging / returns to clean.
#   EX_WAZUH_SEARCH a starting Wazuh "Threat Hunting > Events" search string.
#   EX_HAS_VERIFY   "yes" if a verify.sh exists (a fix the learner must prove).
#   EX_STAGE_CONFIRM "yes" if the staging script asks for a typed YES (the scan).
#                   `stage` asks the learner once, then passes the YES along.
#
# `./run.sh stage` runs EX_STAGE with its output sent to a log file, so the
# learner sees "Done" instead of a play-by-play that gives the answers away.

set -euo pipefail

EXROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_DIR="$(cd "$EXROOT/.." && pwd)"
STATE_DIR="${LAB_EXERCISE_STATE:-$HOME/lab-exercises}"
mkdir -p "$STATE_DIR"

c_cyan()  { printf '\033[36m%s\033[0m\n' "$*"; }
c_green() { printf '\033[32m%s\033[0m\n' "$*"; }
c_yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
c_red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
rule()    { printf '%s\n' "------------------------------------------------------------"; }

# All exercise directories, sorted by level then variant.
list_exercise_dirs() {
  find "$EXROOT/levels" -mindepth 2 -maxdepth 2 -type d -name '*' 2>/dev/null \
    | while read -r d; do [[ -f "$d/meta.sh" ]] && echo "$d"; done | sort
}

# Exercise dirs for a given level number (e.g. 1 -> levels/01-*).
dirs_for_level() {
  local lvl; lvl=$(printf '%02d' "$1")
  find "$EXROOT/levels/$lvl"-* -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
    | while read -r d; do [[ -f "$d/meta.sh" ]] && echo "$d"; done | sort
}

# Human id for an exercise dir, e.g. "1/ssh-bruteforce".
ex_id() {
  local d="$1" lvl var
  lvl="$(basename "$(dirname "$d")")"; lvl="${lvl%%-*}"; lvl="$((10#$lvl))"
  var="$(basename "$d")"
  echo "$lvl/$var"
}

load_meta() {
  local d="$1"
  EX_TITLE=""; EX_SUMMARY=""; EX_STAGE_WHERE=""; EX_STAGE=""; EX_RESET=""
  EX_WAZUH_SEARCH=""; EX_HAS_VERIFY="no"; EX_STAGE_CONFIRM="no"
  # shellcheck source=/dev/null
  source "$d/meta.sh"
}

# The VM this shell is running on. Azure names the OS host after the VM
# (wazuh, linux-srv, win-srv). LAB_EXERCISE_HOST overrides it for testing.
this_host() { echo "${LAB_EXERCISE_HOST:-$(hostname -s 2>/dev/null || hostname)}"; }

# Log file for one run of an exercise's staging or reset.
run_log() { echo "$STATE_DIR/$1-$(echo "$2" | tr / -)-$(date +%Y%m%d-%H%M%S).log"; }

# A PowerShell line for win-srv that sends all of the script's output to a log
# file instead of the screen, so staging doesn't show the answers.
win_quiet_cmd() {
  local cmd="$1" name="$2"
  printf '%s *> "$env:TEMP\\%s.log"; "Done. Details saved to $env:TEMP\\%s.log"' "$cmd" "$name" "$name"
}

cmd_list() {
  local cur_lvl="" d id lvl
  c_cyan "Lab exercises  (defensive-security practice, all inside your own VNet)"
  rule
  while read -r d; do
    [[ -z "$d" ]] && continue
    load_meta "$d"; id="$(ex_id "$d")"; lvl="${id%%/*}"
    if [[ "$lvl" != "$cur_lvl" ]]; then
      cur_lvl="$lvl"
      echo; c_yellow "Level $lvl"
    fi
    printf '  %-26s %s\n' "$id" "$EX_SUMMARY"
  done < <(list_exercise_dirs)
  echo; rule
  cat <<EOF
Start one:        ./run.sh start <level>/<variant>
Random at a level:./run.sh start <level>            (picks a variant you haven't done recently)
Stage it quietly: ./run.sh stage <level>/<variant>  (run on the VM the brief names)
Get a hint:       ./run.sh hint <level>/<variant>
Reveal answer:    ./run.sh reveal <level>/<variant>
Check your fix:   ./run.sh verify <level>/<variant>
Reset to clean:   ./run.sh reset  <level>/<variant>
EOF
}

# Resolve a user argument ("1" or "1/ssh-bruteforce") to a single exercise dir.
resolve_target() {
  local arg="$1" d id matches=()
  if [[ "$arg" == */* ]]; then
    while read -r d; do [[ "$(ex_id "$d")" == "$arg" ]] && matches+=("$d"); done < <(list_exercise_dirs)
  else
    # a bare level number: pick a variant, preferring ones not recently done
    local recent; recent="$STATE_DIR/recent-level-$arg"
    local last=""; [[ -f "$recent" ]] && last="$(cat "$recent")"
    local pool=() pd
    while read -r pd; do [[ -n "$pd" ]] && pool+=("$pd"); done < <(dirs_for_level "$arg")
    [[ ${#pool[@]} -eq 0 ]] && { c_red "No exercises for level $arg."; return 1; }
    local pick=""
    for pd in $(printf '%s\n' "${pool[@]}" | shuf); do
      [[ "$(ex_id "$pd")" != "$last" ]] && { pick="$pd"; break; }
    done
    [[ -z "$pick" ]] && pick="${pool[0]}"
    echo "$(ex_id "$pick")" > "$recent"
    matches=("$pick")
  fi
  [[ ${#matches[@]} -eq 1 ]] || { c_red "Couldn't find exercise '$arg'. Try ./run.sh list"; return 1; }
  RESOLVED_DIR="${matches[0]}"
}

# Confirm the staging script this exercise references actually exists in lab/.
check_stage_script() {
  local first_word="$1"
  case "$first_word" in
    bash|sudo|pwsh|powershell) : ;;  # wrapper, the real path is the next token
  esac
  # pull the first path-looking token
  local tok path=""
  for tok in $EX_STAGE; do
    case "$tok" in
      */*.sh|*/*.ps1) path="$tok"; break ;;
    esac
  done
  [[ -z "$path" ]] && return 0
  local abs="$LAB_DIR/$path"
  if [[ ! -f "$abs" ]]; then
    c_yellow "Note: this exercise stages the incident with:"
    c_yellow "    $path"
    c_yellow "That file is part of the lab/ scripts (added in a separate PR). If you don't"
    c_yellow "have it yet, pull the full lab/ tree first, then re-run. The brief below still"
    c_yellow "explains what to look for."
    echo
  fi
}

cmd_start() {
  resolve_target "$1" || return 1
  load_meta "$RESOLVED_DIR"
  local id; id="$(ex_id "$RESOLVED_DIR")"
  c_cyan "== Exercise $id : $EX_TITLE =="
  rule
  cat "$RESOLVED_DIR/brief.md"
  echo; rule
  if [[ -z "$EX_STAGE" || "$EX_STAGE" == \#* ]]; then
    c_yellow "Step 1: nothing to stage for this one."
    echo "    ${EX_STAGE#\# }"
  else
    c_yellow "Step 1: stage the incident. It runs quietly, so the details stay hidden."
    if [[ "$EX_STAGE_WHERE" == "win-srv" ]]; then
      echo "    It runs on win-srv. ./run.sh stage $id prints the PowerShell line to use there."
    else
      echo "    On the $EX_STAGE_WHERE VM:  ./run.sh stage $id"
    fi
  fi
  echo
  c_yellow "Step 2: investigate in Wazuh (Threat Hunting > Events)."
  [[ -n "$EX_WAZUH_SEARCH" ]] && echo "    Start broad with:  $EX_WAZUH_SEARCH"
  echo
  echo "When you're ready, start your case file from: $EXROOT/case-file-template.md"
  echo "Stuck?  ./run.sh hint $id        See the answer?  ./run.sh reveal $id"
  [[ "$EX_HAS_VERIFY" == "yes" ]] && echo "Prove your fix: ./run.sh verify $id"
  # track start time for the case file
  date +%s > "$STATE_DIR/started-$(echo "$id" | tr / -)"
}

cmd_stage() {
  resolve_target "$1" || return 1
  load_meta "$RESOLVED_DIR"
  local id; id="$(ex_id "$RESOLVED_DIR")"
  if [[ -z "$EX_STAGE" || "$EX_STAGE" == \#* ]]; then
    c_yellow "Nothing to stage for this exercise. ${EX_STAGE#\# }"
    return 0
  fi
  if [[ "$EX_STAGE_WHERE" == "win-srv" ]]; then
    c_yellow "This one stages on win-srv. Open PowerShell as Administrator, go to the"
    c_yellow "repo's lab\\ folder, and run this line. It prints only 'Done':"
    echo
    echo "    $(win_quiet_cmd "$EX_STAGE" "lab-stage-$(echo "$id" | tr / -)")"
    return 0
  fi
  local here; here="$(this_host)"
  if [[ "${here,,}" != "$EX_STAGE_WHERE" ]]; then
    c_red "This exercise stages on the $EX_STAGE_WHERE VM, but this is '$here'."
    c_red "Connect to $EX_STAGE_WHERE (it needs its own copy of the repo) and run:"
    c_red "    ./run.sh stage $id"
    c_red "(Already on $EX_STAGE_WHERE under another name? LAB_EXERCISE_HOST=$EX_STAGE_WHERE ./run.sh stage $id)"
    return 1
  fi
  check_stage_script "${EX_STAGE%% *}"
  if [[ "$EX_STAGE_CONFIRM" == "yes" ]]; then
    local answer
    read -r -p "This runs a scan against your own lab VM. Type YES to confirm you're authorized: " answer
    [[ "$answer" == "YES" ]] || { c_red "Cancelled."; return 1; }
  fi
  local log rc=0; log="$(run_log staging "$id")"
  c_cyan "Staging $id quietly. This can take a minute or two..."
  if [[ "$EX_STAGE_CONFIRM" == "yes" ]]; then
    (cd "$LAB_DIR" && echo YES | bash -c "$EX_STAGE") >"$log" 2>&1 || rc=$?
  else
    (cd "$LAB_DIR" && bash -c "$EX_STAGE") </dev/null >"$log" 2>&1 || rc=$?
  fi
  if [[ $rc -eq 0 ]]; then
    c_green "Done. The incident is staged. Give Wazuh a minute, then go find it."
    echo "(The raw staging output is in $log. It gives the answers away, so save it for after.)"
  else
    c_red "Staging failed (exit code $rc). The last lines of the log say why:"
    tail -n 5 "$log" >&2
    c_red "Full log: $log"
    return 1
  fi
}

cmd_hint() {
  resolve_target "$1" || return 1
  local id; id="$(ex_id "$RESOLVED_DIR")"
  local track="$STATE_DIR/hints-$(echo "$id" | tr / -)"
  local n=0; [[ -f "$track" ]] && n="$(cat "$track")"
  # hints are the lines under "## Hints" in brief.md, one per numbered item
  mapfile -t hints < <(awk '/^## Hints/{f=1;next} /^## /{f=0} f&&/^[0-9]+\./' "$RESOLVED_DIR/brief.md")
  if [[ $n -ge ${#hints[@]} ]]; then
    c_yellow "No more hints. If you're still stuck: ./run.sh reveal $id"
    return 0
  fi
  c_yellow "Hint $((n+1)) of ${#hints[@]}:"
  echo "  ${hints[$n]#*.}"
  echo "$((n+1))" > "$track"
}

cmd_reveal() {
  resolve_target "$1" || return 1
  load_meta "$RESOLVED_DIR"
  c_yellow "Try to write your own answer first. Showing the answer key in 3s (Ctrl-C to stop)..."
  sleep 3 || true
  rule; cat "$RESOLVED_DIR/solution.md"; rule
}

cmd_verify() {
  resolve_target "$1" || return 1
  load_meta "$RESOLVED_DIR"
  if [[ "$EX_HAS_VERIFY" != "yes" || ! -f "$RESOLVED_DIR/verify.sh" ]]; then
    c_yellow "This exercise has nothing to auto-verify (it's detect/investigate only)."
    c_yellow "Check your work against: ./run.sh reveal $(ex_id "$RESOLVED_DIR")"
    return 0
  fi
  c_cyan "Checking your work..."
  if bash "$RESOLVED_DIR/verify.sh"; then
    c_green "PASS - your fix holds up. Write it up in your case file."
  else
    c_red "NOT YET - see the message above. Fix it and run verify again."
    return 1
  fi
}

cmd_reset() {
  resolve_target "$1" || return 1
  load_meta "$RESOLVED_DIR"
  local id; id="$(ex_id "$RESOLVED_DIR")"
  if [[ -z "$EX_RESET" ]]; then
    c_yellow "This exercise leaves nothing behind to reset."
    return 0
  fi
  if [[ "$EX_STAGE_WHERE" == "win-srv" ]]; then
    c_yellow "Reset runs on win-srv. In an Administrator PowerShell, from the repo's lab\\ folder:"
    echo "    $EX_RESET"
    return 0
  fi
  local here; here="$(this_host)"
  if [[ "${here,,}" != "$EX_STAGE_WHERE" ]]; then
    c_red "Reset runs on the $EX_STAGE_WHERE VM, but this is '$here'. Run ./run.sh reset $id there."
    return 1
  fi
  local answer
  read -r -p "This undoes the staged incident on $EX_STAGE_WHERE. Continue? [y/N] " answer
  [[ "$answer" =~ ^[Yy] ]] || { c_yellow "Left as is."; return 0; }
  (cd "$LAB_DIR" && bash -c "$EX_RESET")
}

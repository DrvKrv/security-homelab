# shellcheck shell=bash
# engine.sh - shared logic for the lesson runner. Not run directly; run.sh sources it.
#
# The curriculum is a grid: 7 concept tracks (A-G) x 5 levels (1 Spot, 2 Explain,
# 3 Respond, 4 Prevent, 5 Hunt). Each box, such as A1, holds a few lessons of the
# same type and difficulty. A lesson lives at
#   tracks/<T>-<track>/<N>-<level>/<lesson>/
# and its id is <T><N>/<lesson>, for example A1/ssh-bruteforce.
#
# A lesson folder holds meta.sh, brief.md (hints are the numbered lines under
# "## Hints"), solution.md and an optional verify.sh. LESSON-GUIDE.md documents
# every meta.sh field and how to write a lesson.
#
# `./run.sh stage` runs a lesson's staging with its output sent to a log file, so
# the learner sees "Done" instead of a play-by-play that gives the answers away.
# Staging can randomize details and record them with `answer`; `reveal` shows them.

set -euo pipefail

EXROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_DIR="$(cd "$EXROOT/.." && pwd)"
STATE_DIR="${LAB_EXERCISE_STATE:-$HOME/lab-exercises}"
mkdir -p "$STATE_DIR"

# Lab addresses for staging functions. lab.env (git-ignored) overrides them.
WAZUH_IP="10.0.1.10"; WIN_IP="10.0.1.20"; LINUX_IP="10.0.1.30"
# shellcheck source=/dev/null
[[ -f "$LAB_DIR/lab.env" ]] && source "$LAB_DIR/lab.env"

c_cyan()  { printf '\033[36m%s\033[0m\n' "$*"; }
c_green() { printf '\033[32m%s\033[0m\n' "$*"; }
c_yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
c_red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
rule()    { printf '%s\n' "------------------------------------------------------------"; }

TRACKS="A B C D E F G"
track_name() {
  case "$1" in
    A) echo "Logins and passwords" ;;      B) echo "Accounts and privileges" ;;
    C) echo "Network" ;;                   D) echo "Vulnerabilities and hardening" ;;
    E) echo "Web applications" ;;          F) echo "What runs on a machine" ;;
    G) echo "Cloud and infrastructure as code" ;;
  esac
}
level_name() {
  case "$1" in 1) echo "Spot" ;; 2) echo "Explain" ;; 3) echo "Respond" ;; 4) echo "Prevent" ;; 5) echo "Hunt" ;; esac
}
env_desc() {
  case "$1" in
    core)     echo "your 3 current VMs" ;;
    detect)   echo "detection add-ons: Sysmon, Suricata, Atomic Red Team (unit 4)" ;;
    cloud)    echo "the lab in code, infra/ (unit 5)" ;;
    web)      echo "web-srv (unit 6)" ;;
    ad)       echo "dc01, Active Directory (unit 7)" ;;
    zones)    echo "network zones (unit 8)" ;;
    office)   echo "busy-office noise (unit 9)" ;;
    capstone) echo "the capstone breach (unit 10)" ;;
    *)        echo "$1" ;;
  esac
}
ALL_ENVS="core detect cloud web ad zones office capstone"

# ---- environments the learner has built -------------------------------------
ENV_FILE="$STATE_DIR/environments"
envs_enabled() { echo core; [[ -f "$ENV_FILE" ]] && grep -v '^core$' "$ENV_FILE" || true; }
env_enabled() { [[ "$1" == "core" ]] || { [[ -f "$ENV_FILE" ]] && grep -qx "$1" "$ENV_FILE"; }; }

# ---- finding lessons --------------------------------------------------------
# All lesson directories, sorted by track, level, then name.
list_lesson_dirs() {
  find "$EXROOT/tracks" -mindepth 3 -maxdepth 3 -type d 2>/dev/null \
    | while read -r d; do [[ -f "$d/meta.sh" ]] && echo "$d"; done | sort
}

# Lesson id for a directory, e.g. "A1/ssh-bruteforce".
ex_id() {
  local d="$1" lvl trk
  lvl="$(basename "$(dirname "$d")")"; trk="$(basename "$(dirname "$(dirname "$d")")")"
  echo "${trk%%-*}${lvl%%-*}/$(basename "$d")"
}
id_track() { echo "${1:0:1}"; }
id_level() { local b="${1%%/*}"; echo "${b:1}"; }
safe_id()  { echo "$1" | tr / -; }

load_meta() {
  local d="$1"
  EX_TITLE=""; EX_SUMMARY=""; EX_ENV="core"; EX_ROUND=""; EX_WHERE=""; EX_FIX_WHERE=""
  EX_STAGE=""; EX_RESET=""; EX_WAZUH_SEARCH=""; EX_HAS_VERIFY="no"; EX_STAGE_CONFIRM="no"
  EX_ATTACK=""
  unset -f ex_stage ex_reset ex_assign 2>/dev/null || true
  # shellcheck source=/dev/null
  source "$d/meta.sh"
  [[ -n "$EX_FIX_WHERE" ]] || EX_FIX_WHERE="$EX_WHERE"
}

has_stage()    { declare -F ex_stage >/dev/null || [[ -n "$EX_STAGE" && "$EX_STAGE" != \#* ]]; }
has_reset()    { declare -F ex_reset >/dev/null || [[ -n "$EX_RESET" && "$EX_RESET" != \#* ]]; }
stage_note()   { [[ "$EX_STAGE" == \#* ]] && echo "${EX_STAGE#\# }"; }
lesson_ready() { env_enabled "$EX_ENV"; }

DONE_FILE="$STATE_DIR/done"
is_done() { [[ -f "$DONE_FILE" ]] && grep -q "^$1 " "$DONE_FILE"; }

# ---- helpers for staging functions in meta.sh -------------------------------
pick() { local a=("$@"); echo "${a[RANDOM % ${#a[@]}]}"; }
rand_between() { echo $(( $1 + RANDOM % ($2 - $1 + 1) )); }
answers_file() { echo "$STATE_DIR/answers-$(safe_id "$1")"; }
answer() { printf '%s: %s\n' "$1" "$2" >> "$EX_ANSWERS"; }
# Read one recorded detail back, e.g. in ex_reset: acct="$(recall account)".
recall() { [[ -f "$EX_ANSWERS" ]] && sed -n "s/^$1: //p" "$EX_ANSWERS" | tail -n 1; }
# shellcheck source=staging.sh
source "$EXROOT/lib/staging.sh"

# The VM this shell is running on. Azure names the OS host after the VM
# (wazuh, linux-srv, win-srv). LAB_EXERCISE_HOST overrides it for testing.
this_host() { local h="${LAB_EXERCISE_HOST:-$(hostname -s 2>/dev/null || hostname)}"; echo "${h,,}"; }

# Stop with a clear message when a command must run on another VM.
require_host() { # require_host <vm> <what> <id> <command>
  local here; here="$(this_host)"
  [[ "$here" == "$1" ]] && return 0
  c_red "$2 runs on the $1 VM, but this is '$here'."
  c_red "Connect to $1 (it needs its own copy of the repo) and run:  ./run.sh $4 $3"
  c_red "(Already on $1 under another name? LAB_EXERCISE_HOST=$1 ./run.sh $4 $3)"
  return 1
}

# A PowerShell line for win-srv that sends all of the script's output to a log
# file instead of the screen, so staging doesn't show the answers.
win_quiet_cmd() {
  local cmd="$1" name="$2"
  printf '%s *> "$env:TEMP\\%s.log"; "Done. Details saved to $env:TEMP\\%s.log"' "$cmd" "$name" "$name"
}

# ---- resolving what the learner typed ---------------------------------------
# Accepts a lesson id (A1/ssh-bruteforce), a lesson name (ssh-bruteforce), a box
# (A1), a track (A) or a level (L2 or 2). Anything but a lesson picks at random
# among the lessons you can run, preferring ones you haven't done.
resolve_target() {
  local arg="$1" d id matches=() pool=()
  [[ "$arg" == */* && "$arg" != [A-Ga-g][1-5]/* ]] && arg="${arg#*/}"   # old ids like 1/ssh-bruteforce
  if [[ "$arg" == */* ]]; then
    arg="${arg^}"
    while read -r d; do [[ "$(ex_id "$d")" == "$arg" ]] && matches+=("$d"); done < <(list_lesson_dirs)
  elif [[ "$arg" =~ ^[A-Ga-g]([1-5])?$ || "$arg" =~ ^[Ll]?[1-5]$ ]]; then
    local want_t="" want_l=""
    if [[ "$arg" =~ ^[A-Ga-g] ]]; then want_t="${arg:0:1}"; want_t="${want_t^}"; want_l="${arg:1}"
    else want_l="${arg: -1}"; fi
    while read -r d; do
      id="$(ex_id "$d")"
      [[ -n "$want_t" && "$(id_track "$id")" != "$want_t" ]] && continue
      [[ -n "$want_l" && "$(id_level "$id")" != "$want_l" ]] && continue
      load_meta "$d"; lesson_ready && pool+=("$d")
    done < <(list_lesson_dirs)
    if [[ ${#pool[@]} -eq 0 ]]; then
      c_red "No lessons in '$arg' can run yet: they need an environment you haven't built."
      c_red "See them with ./run.sh list $arg, and read any of them with ./run.sh start <id>."
      return 1
    fi
    matches=("$(pick_from_pool "$arg" "${pool[@]}")")
  else
    while read -r d; do [[ "$(basename "$d")" == "$arg" ]] && matches+=("$d"); done < <(list_lesson_dirs)
  fi
  [[ ${#matches[@]} -eq 1 ]] || { c_red "Couldn't find lesson '$1'. Try ./run.sh list"; return 1; }
  RESOLVED_DIR="${matches[0]}"
}

# Prefer lessons not done yet, and not the one picked last time for this target.
pick_from_pool() {
  local key="$1"; shift
  local recent="$STATE_DIR/recent-$key" last="" d fresh=() pool=("$@")
  [[ -f "$recent" ]] && last="$(cat "$recent")"
  for d in "${pool[@]}"; do is_done "$(ex_id "$d")" || fresh+=("$d"); done
  [[ ${#fresh[@]} -gt 0 ]] && pool=("${fresh[@]}")
  if [[ ${#pool[@]} -gt 1 ]]; then
    fresh=(); for d in "${pool[@]}"; do [[ "$(ex_id "$d")" != "$last" ]] && fresh+=("$d"); done
    pool=("${fresh[@]}")
  fi
  d="$(pick "${pool[@]}")"
  ex_id "$d" > "$recent"
  echo "$d"
}

# ---- list / progress --------------------------------------------------------
cmd_list() {
  [[ $# -gt 0 ]] && { list_lessons "$1"; return; }
  declare -A ready total
  local d id box
  while read -r d; do
    id="$(ex_id "$d")"; box="${id%%/*}"; load_meta "$d"
    total[$box]=$(( ${total[$box]:-0} + 1 ))
    lesson_ready && ready[$box]=$(( ${ready[$box]:-0} + 1 ))
  done < <(list_lesson_dirs)
  c_cyan "Lessons: 7 concepts x 5 levels. Built so far: $(envs_enabled | paste -sd, - | sed 's/,/, /g')"
  rule
  printf '%-34s' ""; for n in 1 2 3 4 5; do printf '%-10s' "L$n $(level_name "$n")"; done; echo
  local t n cell
  for t in $TRACKS; do
    printf '%-34s' "$t $(track_name "$t")"
    for n in 1 2 3 4 5; do
      cell="${ready[$t$n]:-0}/${total[$t$n]:-0}"; [[ "${total[$t$n]:-0}" -eq 0 ]] && cell="-"
      printf '%-10s' "$cell"
    done; echo
  done
  rule
  cat <<EOF
2/4 means 2 of the box's 4 lessons can run on what you've built; the rest need a
later environment. You can still read those with ./run.sh start <id>.

See a box:        ./run.sh list A1        (or a track: A, or a level: L2)
Start one:        ./run.sh start A1       (random lesson in the box) or start A1/<name>
Stage it quietly: ./run.sh stage <id>     (on the VM the brief names; add --surprise for a random time)
Get a hint:       ./run.sh hint <id>
Reveal answer:    ./run.sh reveal <id>
Check your fix:   ./run.sh verify <id>
Mark it done:     ./run.sh done <id>
Your progress:    ./run.sh progress       (and what to do next)
Reset to clean:   ./run.sh reset <id>
Built something:  ./run.sh env add web    (unlocks lessons that need it)
EOF
}

list_lessons() {
  local f="$1" d id t n tag want_t="" want_l=""
  if [[ "$f" =~ ^[A-Ga-g] ]]; then want_t="${f:0:1}"; want_t="${want_t^}"; want_l="${f:1}"
  elif [[ "$f" =~ ^[Ll]?([1-5])$ ]]; then want_l="${BASH_REMATCH[1]}"
  else c_red "Use a box (A1), a track (A) or a level (L2)."; return 1; fi
  local cur=""
  while read -r d; do
    id="$(ex_id "$d")"; t="$(id_track "$id")"; n="$(id_level "$id")"
    [[ -n "$want_t" && "$t" != "$want_t" ]] && continue
    [[ -n "$want_l" && "$n" != "$want_l" ]] && continue
    load_meta "$d"
    if [[ "$cur" != "$t$n" ]]; then
      cur="$t$n"; echo; c_yellow "$t$n  $(track_name "$t") · L$n $(level_name "$n")"
    fi
    tag=""
    is_done "$id" && tag="[done] "
    lesson_ready || tag+="[needs $(env_desc "$EX_ENV")]"
    printf '  %-36s %s %s\n' "$id" "$EX_TITLE" "$tag"
  done < <(list_lesson_dirs)
  echo
}

cmd_progress() {
  declare -A done_n open
  local d id box t n
  while read -r d; do
    id="$(ex_id "$d")"; box="${id%%/*}"; load_meta "$d"
    lesson_ready && open[$box]=1
    is_done "$id" && done_n[$box]=$(( ${done_n[$box]:-0} + 1 ))
  done < <(list_lesson_dirs)
  c_cyan "Your progress (lessons done per box; '.' = open but not started, blank = not built yet)"
  rule
  printf '%-34s' ""; for n in 1 2 3 4 5; do printf '%-10s' "L$n"; done; echo
  for t in $TRACKS; do
    printf '%-34s' "$t $(track_name "$t")"
    for n in 1 2 3 4 5; do
      if [[ -n "${done_n[$t$n]:-}" ]]; then printf '%-10s' "${done_n[$t$n]}"
      elif [[ -n "${open[$t$n]:-}" ]]; then printf '%-10s' "."
      else printf '%-10s' ""; fi
    done; echo
  done
  rule
  # Go across before going up: the lowest level with an open box not yet done.
  local next=()
  for n in 1 2 3 4 5; do
    for t in $TRACKS; do
      [[ -n "${open[$t$n]:-}" && -z "${done_n[$t$n]:-}" ]] && next+=("$t$n")
    done
    [[ ${#next[@]} -gt 0 ]] && break
  done
  if [[ ${#next[@]} -gt 0 ]]; then
    echo "Next: go across before going up. Open boxes at L$n you haven't done: ${next[*]}"
    echo "      Try:  ./run.sh start ${next[0]}"
  else
    echo "Every open box has at least one lesson done. Repeat a box you felt shaky on"
    echo "(the details change each time), or build the next environment to unlock more."
  fi
  echo "Level up once you've done two lessons at a level in different tracks without hints."
}

cmd_done() {
  resolve_target "$1" || return 1
  local id; id="$(ex_id "$RESOLVED_DIR")"
  echo "$id $(date +%Y-%m-%d)" >> "$DONE_FILE"
  c_green "Marked $id as done. ./run.sh progress shows where you are."
}

cmd_env() {
  local action="${1:-show}" name="${2:-}"
  case "$action" in
    show|"")
      c_cyan "Environments (what you've built):"
      local e
      for e in $ALL_ENVS; do
        if env_enabled "$e"; then printf '  [x] %-9s %s\n' "$e" "$(env_desc "$e")"
        else printf '  [ ] %-9s %s\n' "$e" "$(env_desc "$e")"; fi
      done
      echo "Mark one as built: ./run.sh env add <name>    Undo: ./run.sh env remove <name>" ;;
    add)
      [[ " $ALL_ENVS " == *" $name "* && "$name" != core ]] || { c_red "Unknown environment '$name'. Choose from: $ALL_ENVS"; return 1; }
      env_enabled "$name" || echo "$name" >> "$ENV_FILE"
      c_green "Marked $name ($(env_desc "$name")) as built. Its lessons are unlocked." ;;
    remove)
      [[ -f "$ENV_FILE" ]] && { grep -vx "$name" "$ENV_FILE" > "$ENV_FILE.tmp" || true; mv "$ENV_FILE.tmp" "$ENV_FILE"; }
      c_yellow "Marked $name as not built." ;;
    *) c_red "Usage: ./run.sh env [add|remove <name>]"; return 1 ;;
  esac
}

# ---- one lesson -------------------------------------------------------------
# Confirm the staging script a lesson references actually exists in lab/.
check_stage_script() {
  local tok path=""
  for tok in $EX_STAGE; do
    case "$tok" in */*.sh|*/*.ps1) path="$tok"; break ;; esac
  done
  [[ -z "$path" || -f "$LAB_DIR/$path" ]] && return 0
  c_red "This lesson stages with $path, which isn't in your copy of lab/. Run git pull, then try again."
  return 1
}

cmd_start() {
  resolve_target "$1" || return 1
  load_meta "$RESOLVED_DIR"
  local id t n; id="$(ex_id "$RESOLVED_DIR")"; t="$(id_track "$id")"; n="$(id_level "$id")"
  c_cyan "== $id : $EX_TITLE =="
  echo "Track $t ($(track_name "$t")) · L$n $(level_name "$n") · round ${EX_ROUND:-?}"
  rule
  cat "$RESOLVED_DIR/brief.md"
  echo; rule
  if ! lesson_ready; then
    c_yellow "This lesson needs $(env_desc "$EX_ENV"), which you haven't marked as built."
    echo "Read it now. Once that's built, run ./run.sh env add $EX_ENV and come back."
    return 0
  fi
  if declare -F ex_assign >/dev/null; then
    c_yellow "Your assignment this time:"
    ex_assign | sed 's/^/    /'
    echo
  fi
  if ! has_stage; then
    c_yellow "Step 1: nothing to stage for this one."
    [[ -n "$(stage_note)" ]] && echo "    $(stage_note)"
  else
    c_yellow "Step 1: stage the incident. It runs quietly, so the details stay hidden."
    if [[ "$EX_WHERE" == "win-srv" ]]; then
      echo "    It runs on win-srv. ./run.sh stage $id prints the PowerShell line to use there."
    else
      echo "    On the $EX_WHERE VM:  ./run.sh stage $id"
    fi
    echo "    (Add --surprise to have it happen at a random time in the next 15 minutes.)"
  fi
  echo
  c_yellow "Step 2: investigate."
  [[ -n "$EX_WAZUH_SEARCH" ]] && echo "    In Wazuh (Threat Hunting > Events), start broad with:  $EX_WAZUH_SEARCH"
  echo "    Write it up in a copy of: $EXROOT/case-file-template.md"
  echo
  echo "Stuck?  ./run.sh hint $id        See the answer?  ./run.sh reveal $id"
  [[ "$EX_HAS_VERIFY" == "yes" ]] && echo "Prove your fix (on $EX_FIX_WHERE): ./run.sh verify $id"
  echo "Finished?  ./run.sh done $id"
  date +%s > "$STATE_DIR/started-$(safe_id "$id")"
}

# The body of a staging run. Runs in a subshell with output going to the log.
run_stage_body() {
  set -e
  cd "$LAB_DIR"
  answer "staged at (UTC)" "$(date -u '+%Y-%m-%d %H:%M:%S')"
  if declare -F ex_stage >/dev/null; then
    ex_stage
  elif [[ "$EX_STAGE_CONFIRM" == "yes" ]]; then
    echo YES | bash -c "$EX_STAGE"
  else
    bash -c "$EX_STAGE" </dev/null
  fi
  answer "finished at (UTC)" "$(date -u '+%Y-%m-%d %H:%M:%S')"
}

cmd_stage() {
  local surprise=no target="" a
  for a in "$@"; do case "$a" in --surprise) surprise=yes ;; *) target="$a" ;; esac; done
  [[ -n "$target" ]] || { c_red "Usage: ./run.sh stage <lesson> [--surprise]"; return 1; }
  resolve_target "$target" || return 1
  load_meta "$RESOLVED_DIR"
  local id; id="$(ex_id "$RESOLVED_DIR")"
  if ! has_stage; then
    c_yellow "Nothing to stage for this lesson. $(stage_note)"
    return 0
  fi
  if ! lesson_ready; then
    c_red "This lesson needs $(env_desc "$EX_ENV"). Once it's built: ./run.sh env add $EX_ENV"
    return 1
  fi
  if [[ "$EX_WHERE" == "win-srv" ]]; then
    c_yellow "This one stages on win-srv. Open PowerShell as Administrator, go to the"
    c_yellow "repo's lab\\ folder, and run this line. It prints only 'Done':"
    echo
    echo "    $(win_quiet_cmd "$EX_STAGE" "lab-stage-$(safe_id "$id")")"
    return 0
  fi
  require_host "$EX_WHERE" "Staging" "$id" stage || return 1
  check_stage_script || return 1
  if [[ "$EX_STAGE_CONFIRM" == "yes" ]]; then
    local reply
    read -r -p "This runs a scan against your own lab VM. Type YES to confirm you're authorized: " reply
    [[ "$reply" == "YES" ]] || { c_red "Cancelled."; return 1; }
  fi
  # Ask for a sudo password now (if one is needed), not halfway through a quiet run.
  if declare -f ex_stage 2>/dev/null | grep -q sudo || [[ "$EX_STAGE" == *sudo* ]]; then sudo -v; fi
  EX_ANSWERS="$(answers_file "$id")"; : > "$EX_ANSWERS"
  local log rc=0; log="$STATE_DIR/staging-$(safe_id "$id")-$(date +%Y%m%d-%H%M%S).log"
  if [[ "$surprise" == yes ]]; then
    local delay; delay="$(rand_between 60 900)"
    ( trap '' HUP; sleep "$delay"; run_stage_body ) </dev/null >"$log" 2>&1 &
    c_green "Armed. The incident will happen at a random time in the next 15 minutes."
    echo "Keep working, and watch Wazuh. You can close this window; it still runs."
    return 0
  fi
  c_cyan "Staging $id quietly. This can take a minute or two..."
  set +e
  ( run_stage_body ) </dev/null >"$log" 2>&1
  rc=$?
  set -e
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
  local track="$STATE_DIR/hints-$(safe_id "$id")"
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
  local id; id="$(ex_id "$RESOLVED_DIR")"
  c_yellow "Try to write your own answer first. Showing the answer key in 3s (Ctrl-C to stop)..."
  sleep 3 || true
  rule; cat "$RESOLVED_DIR/solution.md"; rule
  [[ -n "$EX_ATTACK" ]] && echo "MITRE ATT&CK: $EX_ATTACK"
  local ans; ans="$(answers_file "$id")"
  if [[ "$EX_WHERE" == "win-srv" ]] && has_stage; then
    echo "This run's details are in the staging log on win-srv: \$env:TEMP\\lab-stage-$(safe_id "$id").log"
  elif [[ -s "$ans" ]]; then
    c_cyan "This run's details:"
    sed 's/^/    /' "$ans"
  elif has_stage; then
    echo "This run's details are recorded on $EX_WHERE. Run ./run.sh reveal $id there to see them."
  fi
}

# Export each recorded detail as LAB_ANSWER_<KEY> for verify.sh.
export_answers() {
  local f="$1" k v
  export LAB_ANSWERS="$f"
  [[ -s "$f" ]] || return 0
  while IFS= read -r line; do
    k="${line%%: *}"; v="${line#*: }"
    k="$(echo "$k" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z0-9]/_/g')"
    export "LAB_ANSWER_$k=$v"
  done < "$f"
}

cmd_verify() {
  resolve_target "$1" || return 1
  load_meta "$RESOLVED_DIR"
  local id; id="$(ex_id "$RESOLVED_DIR")"
  if [[ "$EX_HAS_VERIFY" != "yes" || ! -f "$RESOLVED_DIR/verify.sh" ]]; then
    c_yellow "This lesson has nothing to auto-verify. Check your work against: ./run.sh reveal $id"
    return 0
  fi
  require_host "$EX_FIX_WHERE" "Verify" "$id" verify || return 1
  export_answers "$(answers_file "$id")"
  c_cyan "Checking your work..."
  if bash "$RESOLVED_DIR/verify.sh"; then
    c_green "PASS: your fix holds up. Write it up in your case file."
    is_done "$id" || echo "$id $(date +%Y-%m-%d)" >> "$DONE_FILE"
  else
    c_red "NOT YET: see the message above. Fix it and run verify again."
    return 1
  fi
}

cmd_reset() {
  resolve_target "$1" || return 1
  load_meta "$RESOLVED_DIR"
  local id; id="$(ex_id "$RESOLVED_DIR")"
  if ! has_reset; then
    c_yellow "This lesson leaves nothing behind to reset. $([[ "$EX_RESET" == \#* ]] && echo "${EX_RESET#\# }")"
    return 0
  fi
  if [[ "$EX_FIX_WHERE" == "win-srv" ]]; then
    c_yellow "Reset runs on win-srv. In an Administrator PowerShell, from the repo's lab\\ folder:"
    echo "    $EX_RESET"
    return 0
  fi
  require_host "$EX_FIX_WHERE" "Reset" "$id" reset || return 1
  local reply
  read -r -p "This undoes the staged incident on $EX_FIX_WHERE. Continue? [y/N] " reply
  [[ "$reply" =~ ^[Yy] ]] || { c_yellow "Left as is."; return 0; }
  EX_ANSWERS="$(answers_file "$id")"
  if declare -F ex_reset >/dev/null; then
    (cd "$LAB_DIR" && ex_reset)
  else
    (cd "$LAB_DIR" && bash -c "$EX_RESET")
  fi
  c_green "Reset done."
}

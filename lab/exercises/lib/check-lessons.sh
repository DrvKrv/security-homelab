#!/usr/bin/env bash
# check-lessons.sh - checks every lesson against LESSON-GUIDE.md before it's
# committed. Read-only; it stages nothing and needs no VM.
#
#   bash lib/check-lessons.sh          # from lab/exercises/
#
# It checks that each lesson has its files, that meta.sh uses known values and
# points at staging scripts that exist, that brief.md has the usual heading and
# one-line hints, that no rule id, event id, ATT&CK id or staged account name
# appears in a brief before "## Hints", and that relative links resolve.
#
# A brief that teaches an id on purpose (F1 explains what event 4688 is) lists
# it in meta.sh as EX_CHECK_ALLOW="4688", so the check skips just that id.
# Exits 1 if anything fails.

set -uo pipefail

EXROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_DIR="$(cd "$EXROOT/.." && pwd)"

ENVS=" core detect cloud web ad zones office capstone "
HOSTS=" wazuh linux-srv win-srv web-srv dc01 none "
LEVELS=([1]=Spot [2]=Explain [3]=Respond [4]=Prevent [5]=Hunt)

# Ids a brief must not name before its hints (the facts list in LESSON-GUIDE.md).
SPOILER_IDS='550|553|554|2961|5402|5501|5502|5503|5551|5555|5710|5712|5715|5760|5762|5763|5902|5903'
SPOILER_IDS+='|60109|60110|60111|60112|60115|60122|60154|60204|1001[0-9][0-9]|1004[0-9][0-9]'
SPOILER_IDS+='|4104|4624|4625|4634|4648|4672|4688|4698|4719|4720|4722|4724|4725|4726|4728|4732|4733|4738|4740|4756'
SPOILER_IDS+='|4768|4769|4771|4776|7045'
# (100300-100399 is the learner's own rule range, so naming it is fine.)
# Account names that staging picks at random (lib/staging.sh and lesson pools).
SPOILER_NAMES='svc_backup|svc_monitor|sysmaint|backup_svc|ops_agent|svc_update|svc_patch|it_tmp'

errors=0
fail() { printf '  [FAIL] %s: %s\n' "$1" "$2"; errors=$((errors + 1)); }

check_links() { # check_links <lesson id> <file>
  local dir target
  dir="$(dirname "$2")"
  while IFS= read -r target; do
    target="${target%%#*}"
    [[ -z "$target" ]] && continue
    [[ -e "$dir/$target" ]] || fail "$1" "$(basename "$2") links to $target, which doesn't exist"
  done < <(grep -o '](\([^)]*\))' "$2" | sed 's/^](//; s/)$//' | grep -v -E '^(https?:|mailto:|#)')
}

declare -A seen_slug
count=0
while IFS= read -r d; do
  count=$((count + 1))
  lvl="$(basename "$(dirname "$d")")"; trk="$(basename "$(dirname "$(dirname "$d")")")"
  slug="$(basename "$d")"; id="${trk%%-*}${lvl%%-*}/$slug"
  t="${trk%%-*}"; n="${lvl%%-*}"

  [[ -n "${seen_slug[$slug]:-}" ]] && fail "$id" "slug '$slug' is also used by ${seen_slug[$slug]}"
  seen_slug[$slug]="$id"
  [[ "$t" =~ ^[A-G]$ && "$n" =~ ^[1-5]$ ]] || { fail "$id" "folder isn't tracks/<A-G>-<name>/<1-5>-<level>/"; continue; }
  for f in meta.sh brief.md solution.md; do [[ -s "$d/$f" ]] || fail "$id" "missing $f"; done
  [[ -s "$d/meta.sh" && -s "$d/brief.md" ]] || continue

  # ---- meta.sh -------------------------------------------------------------
  out="$(
    EX_TITLE=""; EX_SUMMARY=""; EX_ENV="core"; EX_ROUND=""; EX_WHERE=""; EX_FIX_WHERE=""
    EX_STAGE=""; EX_RESET=""; EX_WAZUH_SEARCH=""; EX_HAS_VERIFY="no"; EX_STAGE_CONFIRM="no"; EX_ATTACK=""
    EX_CHECK_ALLOW=""
    # shellcheck source=/dev/null
    source "$d/meta.sh" || { echo "meta.sh failed to load"; exit; }
    echo "ALLOW ${EX_CHECK_ALLOW:-}"
    [[ -n "$EX_TITLE" ]] || echo "EX_TITLE is empty"
    [[ -n "$EX_SUMMARY" ]] || echo "EX_SUMMARY is empty"
    [[ "$ENVS" == *" $EX_ENV "* ]] || echo "EX_ENV '$EX_ENV' isn't one of:$ENVS"
    [[ "$EX_ROUND" =~ ^[1-8]$ ]] || echo "EX_ROUND '$EX_ROUND' isn't 1-8"
    [[ "$HOSTS" == *" $EX_WHERE "* ]] || echo "EX_WHERE '$EX_WHERE' isn't one of:$HOSTS"
    [[ -z "$EX_FIX_WHERE" || "$HOSTS" == *" $EX_FIX_WHERE "* ]] || echo "EX_FIX_WHERE '$EX_FIX_WHERE' isn't one of:$HOSTS"
    [[ "$EX_HAS_VERIFY" == yes || "$EX_HAS_VERIFY" == no ]] || echo "EX_HAS_VERIFY must be yes or no"
    [[ "$EX_STAGE_CONFIRM" == yes || "$EX_STAGE_CONFIRM" == no ]] || echo "EX_STAGE_CONFIRM must be yes or no"
    [[ "$EX_HAS_VERIFY" == yes && ! -f "$d/verify.sh" ]] && echo "EX_HAS_VERIFY=yes but there's no verify.sh"
    [[ "$EX_HAS_VERIFY" == no && -f "$d/verify.sh" ]] && echo "verify.sh exists but EX_HAS_VERIFY=no"
    if declare -F ex_stage >/dev/null && [[ "$EX_WHERE" == win-srv ]]; then
      echo "ex_stage is bash, but EX_WHERE is win-srv: use a PowerShell EX_STAGE instead"
    fi
    for tok in $EX_STAGE $EX_RESET; do
      case "$tok" in
        */*.sh|*\\*.ps1|*/*.ps1)
          p="${tok//\\\\//}"; p="${p//\\//}"; p="${p//\"/}"; p="${p//\'/}"
          [[ -f "$LAB_DIR/$p" ]] || echo "staging refers to lab/$p, which doesn't exist" ;;
      esac
    done
  )"
  allow="$(sed -n 's/^ALLOW //p' <<< "$out")"
  out="$(grep -v '^ALLOW' <<< "$out")"
  while IFS= read -r line; do [[ -n "$line" ]] && fail "$id" "meta.sh: $line"; done <<< "$out"

  # ---- brief.md ------------------------------------------------------------
  b="$d/brief.md"
  head -n 1 "$b" | grep -q "^# $t$n ${LEVELS[$n]}: " \
    || fail "$id" "brief.md should start with '# $t$n ${LEVELS[$n]}: <title>'"
  grep -q '^## Hints' "$b" || fail "$id" "brief.md has no '## Hints' section"
  hints="$(awk '/^## Hints/{f=1;next} /^## /{f=0} f&&/^[0-9]+\./' "$b" | wc -l)"
  [[ "$hints" -ge 2 ]] || fail "$id" "brief.md has $hints hints (want 3-5)"
  # A hint that wraps gets cut off by ./run.sh hint.
  awk '/^## Hints/{f=1;next} /^## /{f=0} f&&NF&&!/^[0-9]+\./{print; exit 1}' "$b" >/dev/null \
    || fail "$id" "a hint in brief.md runs onto a second line"
  before="$(awk '/^## Hints/{exit} {print}' "$b")"
  for tok in $allow; do before="$(sed -E "s/(^|[^0-9A-Za-z.])${tok//./\\.}([^0-9A-Za-z.]|$)/\\1\\2/g" <<< "$before")"; done
  hit="$(grep -n -o -w -E "($SPOILER_IDS)" <<< "$before" | head -n 3 | paste -sd ' ' -)"
  [[ -z "$hit" ]] || fail "$id" "brief.md names a rule/event id before the hints (line:id $hit)"
  hit="$(grep -n -o -w -E 'T1[0-9]{3}(\.[0-9]{3})?' <<< "$before" | head -n 3 | paste -sd ' ' -)"
  [[ -z "$hit" ]] || fail "$id" "brief.md names an ATT&CK id before the hints (line:id $hit)"
  hit="$(grep -n -o -w -E "($SPOILER_NAMES)" <<< "$before" | head -n 3 | paste -sd ' ' -)"
  [[ -z "$hit" ]] || fail "$id" "brief.md names a staged account before the hints (line:name $hit)"
  check_links "$id" "$b"

  # ---- solution.md ---------------------------------------------------------
  [[ -s "$d/solution.md" ]] || continue
  head -n 1 "$d/solution.md" | grep -q '^# Answer key: ' \
    || fail "$id" "solution.md should start with '# Answer key: <title>'"
  check_links "$id" "$d/solution.md"
done < <(find "$EXROOT/tracks" -mindepth 3 -maxdepth 3 -type d | sort)

echo
if [[ "$errors" -eq 0 ]]; then
  echo "All $count lessons pass."
else
  echo "$errors problem(s) across $count lessons."
  exit 1
fi

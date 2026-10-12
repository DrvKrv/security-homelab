#!/usr/bin/env bash
# test-rules.sh - "detection as code": run sample log lines through Wazuh's
# real rule engine and check each one fires the rule you expect.
#
# Run ON THE WAZUH VM, after setup-manager.sh (and any stage's rules) are in:
#   sudo bash test-rules.sh                    # every tests/*.tests file
#   sudo bash test-rules.sh tests/ssh.tests    # just one file
#
# Or anywhere with Docker, against a throwaway Wazuh manager (nothing to do
# with your lab's real manager):  bash test-rules-docker.sh
#
# Test file format (tests/*.tests). Blocks are separated by a [name] line:
#
#   [ufw block is decoded]
#   log: Oct 11 21:40:01 linux-srv kernel: [UFW BLOCK] ... SRC=10.0.1.10 ...
#   repeat: 8          optional: send the log lines this many times (for
#                      rules that count events, like brute force)
#   rule: 100100       the rule id the LAST event must fire
#   level: 5           optional: its level
#   field: srcip=10.0.1.10    optional, repeatable: a decoded field value
#
# Each block runs in its own wazuh-logtest session, so counting rules start
# from zero every time. Lines starting with # are comments.
#
# Why bother: a rule you never tested is a guess. A test also catches a rule
# that silently stops working after you edit it, or after a Wazuh upgrade.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGTEST="${WAZUH_LOGTEST:-/var/ossec/bin/wazuh-logtest}"

if [[ "$LOGTEST" == /* && ! -x "$LOGTEST" ]]; then
  echo "wazuh-logtest not found at $LOGTEST. Run this on the wazuh VM (with sudo)," >&2
  echo "or use test-rules-docker.sh on a machine with Docker." >&2
  exit 2
fi

files=("$@")
[[ ${#files[@]} -gt 0 ]] || files=("$HERE"/tests/*.tests)

pass=0; fail=0

# run_block <name> <repeat> <expected rule> <expected level> <fields...> -- <log lines...>
run_block() {
  local name="$1" repeat="$2" want_rule="$3" want_level="$4"; shift 4
  local -a fields=() logs=()
  while [[ $# -gt 0 && "$1" != -- ]]; do fields+=("$1"); shift; done
  shift
  logs=("$@")
  local input="" i out last got_rule got_level problems=""
  for ((i = 0; i < repeat; i++)); do input+="$(printf '%s\n' "${logs[@]}")"$'\n'; done
  out="$(printf '%s' "$input" | $LOGTEST 2>&1)"
  # Keep only the output for the last event.
  last="$(awk '/^\*\*Phase 1/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' <<< "$out")"
  got_rule="$(awk '/^\*\*Phase 3/{p=1} p && /^[[:space:]]+id:/{gsub(/[^0-9]/,"",$2); print $2; exit}' <<< "$last")"
  got_level="$(awk '/^\*\*Phase 3/{p=1} p && /^[[:space:]]+level:/{gsub(/[^0-9]/,"",$2); print $2; exit}' <<< "$last")"
  if grep -q 'logtest error' <<< "$out"; then
    problems+=" wazuh-logtest reported an error: $(grep -A2 'logtest error' <<< "$out" | tail -n 2 | tr -s '\t\n' '  ')"
  fi
  [[ "$got_rule" == "$want_rule" ]] || problems+=" rule ${got_rule:-none} (want $want_rule)"
  [[ -z "$want_level" || "$got_level" == "$want_level" ]] || problems+=" level ${got_level:-none} (want $want_level)"
  local f k v got
  for f in "${fields[@]}"; do
    k="${f%%=*}"; v="${f#*=}"
    got="$(awk -v k="$k" '/^\*\*Phase 2/{p=1} /^\*\*Phase 3/{p=0} p { line=$0; sub(/^[[:space:]]+/, "", line); if (index(line, k ": ") == 1) { sub(/^[^:]+: /, "", line); gsub(/^'"'"'|'"'"'$/, "", line); print line; exit } }' <<< "$last")"
    [[ "$got" == "$v" ]] || problems+=" field $k='${got}' (want '$v')"
  done
  if [[ -z "$problems" ]]; then
    printf '  [PASS] %s\n' "$name"; pass=$((pass + 1))
  else
    printf '  [FAIL] %s:%s\n' "$name" "$problems"; fail=$((fail + 1))
  fi
}

for file in "${files[@]}"; do
  [[ -f "$file" ]] || { echo "No such test file: $file" >&2; fail=$((fail + 1)); continue; }
  basename "$file"
  name=""; repeat=1; rule=""; level=""; fields=(); logs=()
  flush() {
    [[ -n "$name" ]] || return 0
    if [[ -z "$rule" || ${#logs[@]} -eq 0 ]]; then
      printf '  [FAIL] %s: needs at least one log: line and a rule: line\n' "$name"; fail=$((fail + 1))
    else
      run_block "$name" "$repeat" "$rule" "$level" "${fields[@]}" -- "${logs[@]}"
    fi
    name=""; repeat=1; rule=""; level=""; fields=(); logs=()
  }
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      ''|'#'*) ;;
      '['*']') flush; name="${line:1:${#line}-2}" ;;
      log:*)    logs+=("${line#log: }") ;;
      repeat:*) repeat="${line#repeat: }" ;;
      rule:*)   rule="${line#rule: }" ;;
      level:*)  level="${line#level: }" ;;
      field:*)  fields+=("${line#field: }") ;;
      *) printf '  [FAIL] %s: line not understood: %s\n' "${name:-?}" "$line"; fail=$((fail + 1)) ;;
    esac
  done < "$file"
  flush
done

echo
echo "$pass passed, $fail failed."
[[ "$fail" -eq 0 ]]

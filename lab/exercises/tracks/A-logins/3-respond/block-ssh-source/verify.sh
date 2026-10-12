#!/usr/bin/env bash
# verify.sh - checks the A3 SSH block on linux-srv. Run as part of:
#   ./run.sh verify A3/block-ssh-source        (on linux-srv)
#
# Reads UFW's rules in order, the way UFW does (first match wins), and works out
# what happens to SSH from the source that attacked and from win-srv.
# PASS when: UFW is on, the first rule that matches the attacking source on port
# 22 drops it and logs it, and win-srv can still reach SSH. Read-only.

set -uo pipefail
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
WAZUH_IP="10.0.1.10"; WIN_IP="10.0.1.20"
# shellcheck source=/dev/null
[[ -f "$LAB_DIR/lab.env" ]] && source "$LAB_DIR/lab.env"
SOURCE_IP="${BLOCKED_IP:-$WAZUH_IP}"
fail=0

check() { # check "<description>" <0-if-good>
  if [[ "$2" -eq 0 ]]; then printf '  [ OK ] %s\n' "$1"; else printf '  [FAIL] %s\n' "$1" >&2; fail=1; fi
}

check_if() { # check_if "<description>" <test command...>: OK if the command succeeds
  local d="$1"; shift
  if "$@"; then check "$d" 0; else check "$d" 1; fi
}
ip_to_int() { local a b c d; IFS=. read -r a b c d <<< "$1"; echo $(( (a << 24) + (b << 16) + (c << 8) + d )); }
# ip_matches <ip> <ufw "From" value: Anywhere, an address or a CIDR range>
ip_matches() {
  local ip="$1" from="$2" net bits mask
  [[ "$from" == Anywhere ]] && return 0
  net="${from%/*}"; bits=32; [[ "$from" == */* ]] && bits="${from#*/}"
  [[ "$net" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  mask=$(( bits == 0 ? 0 : (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF ))
  (( ($(ip_to_int "$ip") & mask) == ($(ip_to_int "$net") & mask) ))
}
# port_matches <ufw "To" value>: does it cover TCP port 22?
port_matches() {
  local to="$1" ports proto="tcp" p
  [[ "$to" == Anywhere ]] && return 0
  ports="${to%%/*}"; [[ "$to" == */* ]] && proto="${to#*/}"
  [[ "$proto" == tcp ]] || return 1
  IFS=, read -ra list <<< "$ports"
  for p in "${list[@]}"; do
    [[ "$p" == 22 ]] && return 0
    [[ "$p" == *:* ]] && (( ${p%%:*} <= 22 && 22 <= ${p#*:} )) && return 0
  done
  return 1
}

status="$(sudo ufw status numbered 2>&1)"
if ! grep -q '^Status: active' <<< "$status"; then
  check "UFW is active on linux-srv" 1
  echo; echo "Turn UFW back on (sudo ufw enable) and run verify again." >&2; exit 1
fi
check "UFW is active on linux-srv" 0
mapfile -t RULES < <(grep -E '^\[ *[0-9]+\]' <<< "$status" | grep -v '(v6)' | grep -E ' IN ')

# first_rule <ip>: prints "<number> <action> <from> <logged>" for the first rule
# that matches <ip> on 22/tcp, or "default" when none does.
first_rule() {
  local ip="$1" line num to action from rest
  for line in "${RULES[@]}"; do
    num="$(sed -E 's/^\[ *([0-9]+)\].*/\1/' <<< "$line")"
    rest="${line#*] }"; rest="${rest%%#*}"
    read -r to action _ from _ <<< "$rest"
    if ! port_matches "$to" || ! ip_matches "$ip" "$from"; then continue; fi
    if [[ "$line" == *"(log"* ]]; then echo "$num $action $from logged"; else echo "$num $action $from silent"; fi
    return
  done
  echo "default"
}

read -r num action from logged <<< "$(first_rule "$SOURCE_IP")"
if [[ "$num" == default ]]; then
  check "a rule decides what happens to SSH from the source that attacked" 1
else
  if [[ "$action" == DENY || "$action" == REJECT ]]; then
    check "the first rule UFW applies to the attacking source on port 22 blocks it (rule [$num])" 0
    check_if "that rule names the one attacking address, not a range or Anywhere" \
      [ "$from" = "$SOURCE_IP" -o "$from" = "$SOURCE_IP/32" ]
    check_if "that rule logs what it drops, so Wazuh can see it" [ "$logged" = logged ]
  else
    check "the first rule UFW applies to the attacking source on port 22 blocks it (rule [$num] is $action)" 1
  fi
fi

read -r wnum waction _ <<< "$(first_rule "$WIN_IP")"
check_if "win-srv ($WIN_IP) can still reach SSH, so you can't lock yourself out" \
  [ "$wnum" != default -a \( "$waction" = ALLOW -o "$waction" = LIMIT \) ]

echo
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed. Now prove it from the source side and in Wazuh (see the brief)."
  exit 0
fi
echo "One or more checks failed. 'sudo ufw status numbered' shows the order UFW reads rules in." >&2
exit 1

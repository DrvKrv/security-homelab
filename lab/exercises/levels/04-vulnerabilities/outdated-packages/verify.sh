#!/usr/bin/env bash
# verify.sh - measures patching progress on linux-srv for the Level 4 exercise.
#
# First run: records a baseline of how many packages are upgradable.
# Later runs: compares to the baseline and passes when the count has dropped
# (0 upgradable = fully patched). Read-only; it never installs or changes
# anything itself.
#
# Note: this reads apt's cached package lists. Run `sudo apt update` yourself
# first so the numbers are current.

set -uo pipefail
STATE_DIR="${LAB_EXERCISE_STATE:-$HOME/lab-exercises}"
mkdir -p "$STATE_DIR"
BASE="$STATE_DIR/level4-baseline"

if ! command -v apt >/dev/null 2>&1; then
  echo "This verifier expects a Debian/Ubuntu host (apt). Run it on linux-srv." >&2
  exit 1
fi

# Count upgradable packages from cached lists (the header line is excluded).
current="$(apt list --upgradable 2>/dev/null | grep -c '/' || true)"
current="${current:-0}"

if [[ ! -f "$BASE" ]]; then
  echo "$current" > "$BASE"
  cat <<EOF
Baseline recorded: $current package(s) currently upgradable.

Now do the exercise:
  1. Research which of these matter (CVE / CVSS / exposure).
  2. Patch the ones you prioritised (e.g. sudo apt install --only-upgrade <pkg>,
     or sudo apt upgrade for everything).
  3. Run this verify again to measure your progress.
EOF
  exit 1   # not done yet - baseline is just the starting point
fi

baseline="$(cat "$BASE")"; baseline="${baseline:-0}"
echo "Upgradable packages: baseline $baseline  ->  now $current"

if [[ "$current" -eq 0 ]]; then
  echo "Fully patched: nothing left upgradable. Excellent."
  echo "(Document in your CVE worksheet WHICH CVEs you addressed and why.)"
  exit 0
elif [[ "$current" -lt "$baseline" ]]; then
  echo "Progress: you patched $((baseline - current)) package(s)."
  echo "That's a pass for this exercise - the key skill is the prioritise-and-fix"
  echo "loop, not reaching zero. Make sure your worksheet names the CVEs you fixed."
  exit 0
else
  echo "No reduction yet ($current still upgradable)." >&2
  echo "Did you run 'sudo apt update' then patch your prioritised packages?" >&2
  exit 1
fi

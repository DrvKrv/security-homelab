# shellcheck shell=bash
# common.sh - shared helpers for the lab's Linux scripts. Not run directly.

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$LAB_DIR/lab.env" ]]; then
  # shellcheck source=/dev/null
  source "$LAB_DIR/lab.env"
else
  echo "Note: $LAB_DIR/lab.env not found, using the placeholder IPs from lab.env.example." >&2
  # shellcheck source=../lab.env.example
  source "$LAB_DIR/lab.env.example"
fi

EVIDENCE_DIR="${EVIDENCE_DIR:-$HOME/lab-evidence}"
mkdir -p "$EVIDENCE_DIR"

say()  { printf '\033[36m%s  %s\033[0m\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

# Safety guard: the attack scripts only ever touch private (RFC 1918) addresses
# inside LAB_SUBNET. This stops a typo from sending traffic at the internet.
require_lab_target() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] \
    || die "'$ip' is not an IPv4 address. Use the lab VM's IP, e.g. $LINUX_IP."
  local a=${BASH_REMATCH[1]} b=${BASH_REMATCH[2]}
  if ! { [[ $a -eq 10 ]] || [[ $a -eq 172 && $b -ge 16 && $b -le 31 ]] || [[ $a -eq 192 && $b -eq 168 ]]; }; then
    die "Refusing: $ip is not a private lab address. Only scan/attack your own lab VMs."
  fi
  python3 - "$ip" "$LAB_SUBNET" <<'PY' || die "Refusing: $ip is outside LAB_SUBNET ($LAB_SUBNET). Fix lab.env if your subnet is different."
import ipaddress, sys
sys.exit(0 if ipaddress.ip_address(sys.argv[1]) in ipaddress.ip_network(sys.argv[2], strict=False) else 1)
PY
}

confirm() {
  local answer
  read -r -p "$1 Type YES to continue: " answer
  [[ "$answer" == "YES" ]] || die "Cancelled."
}

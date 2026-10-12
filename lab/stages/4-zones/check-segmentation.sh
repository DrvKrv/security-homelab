#!/usr/bin/env bash
# check-segmentation.sh - proves the network zones work (unit 8).
# Run ON web-srv, after `terraform apply` with enable_zones = true.
#
#   bash lab/stages/4-zones/check-segmentation.sh
#
# It opens one ordinary TCP connection to each address and port below and
# closes it straight away (nc -z), the same check you'd do by hand. It only
# ever targets the lab's own private addresses.
#
#   MUST connect:   wazuh 1514 and 1515 (the agent's ports; the design allows them)
#   MUST NOT:       anything else in the internal zone (dc01, win-srv,
#                   linux-srv, and wazuh's SSH and dashboard)
#
# A "blocked" result only proves something if the target is switched on and
# listening. Before trusting a PASS, check from win-srv that the same ports do
# answer there (exercise 06 shows the PowerShell line). Read-only.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../linux/common.sh"
DC01_IP="${DC01_IP:-10.0.1.50}"

# "name ip port" lines: what the DMZ should and shouldn't reach.
ALLOWED=(
  "wazuh-agent-events $WAZUH_IP 1514"
  "wazuh-agent-enrol  $WAZUH_IP 1515"
)
BLOCKED=(
  "dc01-kerberos      $DC01_IP 88"
  "dc01-ldap          $DC01_IP 389"
  "dc01-smb           $DC01_IP 445"
  "dc01-rdp           $DC01_IP 3389"
  "dc01-winrm         $DC01_IP 5985"
  "win-srv-rdp        $WIN_IP 3389"
  "win-srv-smb        $WIN_IP 445"
  "linux-srv-ssh      $LINUX_IP 22"
  "wazuh-ssh          $WAZUH_IP 22"
  "wazuh-dashboard    $WAZUH_IP 443"
)

reaches() { nc -z -w 3 "$1" "$2" >/dev/null 2>&1; }
fail=0

echo "Running on $(hostname) ($(hostname -I | awk '{print $1}'))"
echo
echo "Should connect (the design allows it):"
for row in "${ALLOWED[@]}"; do
  read -r name ip port <<< "$row"; require_lab_target "$ip"
  if reaches "$ip" "$port"; then printf '  [ OK ] %-20s %s:%s connects\n' "$name" "$ip" "$port"
  else printf '  [FAIL] %-20s %s:%s does not connect (agent traffic is blocked, or wazuh is off)\n' "$name" "$ip" "$port"; fail=1; fi
done
echo
echo "Should be blocked (DMZ must not reach the internal zone):"
for row in "${BLOCKED[@]}"; do
  read -r name ip port <<< "$row"; require_lab_target "$ip"
  if reaches "$ip" "$port"; then printf '  [FAIL] %-20s %s:%s CONNECTS\n' "$name" "$ip" "$port"; fail=1
  else printf '  [ OK ] %-20s %s:%s blocked\n' "$name" "$ip" "$port"; fi
done
echo
if [[ "$fail" -eq 0 ]]; then
  echo "PASS: from here, only the agent ports reach the internal zone."
  echo "Now confirm the 'blocked' targets were switched on (see exercise 06), or the PASS proves nothing."
  exit 0
fi
echo "FAIL: see the lines above. Read your NSG rules in the Azure portal (Effective security rules on the NIC) or in infra/zones.tf." >&2
exit 1

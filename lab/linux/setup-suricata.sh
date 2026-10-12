#!/usr/bin/env bash
# setup-suricata.sh - unit 4: install Suricata, a network intrusion detection
# system (IDS), on linux-srv and get its alerts into Wazuh.
#
#   sudo bash setup-suricata.sh                  # install and configure
#   sudo bash setup-suricata.sh --low-memory-ok  # go ahead on a 1 GB VM (see below)
#   sudo bash setup-suricata.sh --skip-update    # keep the rules already downloaded
#
# Run ON linux-srv. Safe to run again: it backs up suricata.yaml first.
#
# What it does, and why:
#   1. Installs Suricata from Ubuntu's own packages.
#   2. Tells it which network is "home" (the lab VNet), which network card to
#      watch, and to write its alerts as JSON to /var/log/suricata/eve.json.
#   3. Downloads the free Emerging Threats Open ruleset with suricata-update.
#      These are published detection rules, the same ones many companies use.
#   4. Tests the config before (re)starting Suricata, so a typo can't leave it
#      half-running.
#   The Wazuh agent reads eve.json through the "linux" agent group config
#   (lab/wazuh/agent-groups/linux/agent.conf), and Wazuh's built-in Suricata
#   rules turn each Suricata alert into a Wazuh alert.
#
# What Suricata can see in Azure: only traffic to and from linux-srv itself.
# Azure has no "mirror port" to copy other VMs' traffic, so this is a host
# IDS for one machine, not a sensor for the whole network.
#
# Memory: Suricata with a full ruleset wants several hundred MB. linux-srv is a
# 1 GB VM that also runs the Wazuh agent. On less than 1.5 GB the script stops
# unless you pass --low-memory-ok; then it uses Suricata's low-memory profile
# and adds a 1 GB swap file if there's none. Check `free -m` afterwards.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[[ $EUID -eq 0 ]] || die "Please run with sudo:  sudo bash $0"

LOW_MEM_OK=no; SKIP_UPDATE=no
for a in "$@"; do
  case "$a" in
    --low-memory-ok) LOW_MEM_OK=yes ;;
    --skip-update) SKIP_UPDATE=yes ;;
    *) die "Unknown option: $a" ;;
  esac
done

CONF=/etc/suricata/suricata.yaml
HOME_NET_CIDR="${LAB_VNET:-10.0.0.0/16}"
IFACE="$(ip route show default | awk '{print $5; exit}')"
[[ -n "$IFACE" ]] || die "Couldn't find the network card with the default route."

mem_mb="$(awk '/^MemTotal:/ {print int($2 / 1024)}' /proc/meminfo)"
low_mem=no
if (( mem_mb < 1500 )); then
  low_mem=yes
  if [[ "$LOW_MEM_OK" != yes ]]; then
    die "This VM has ${mem_mb} MB of memory. Suricata may squeeze out the Wazuh agent.
Re-run with --low-memory-ok to use the low-memory profile and a swap file, or give
linux-srv more memory first (a bigger size costs more; see docs/plan/vm-create-settings.md)."
  fi
fi

say "1. Installing Suricata"
DEBIAN_FRONTEND=noninteractive apt-get install -y suricata >/dev/null
suricata -V

say "2. Configuring it (backup first)"
[[ -f "$CONF.lab-original" ]] || cp -p "$CONF" "$CONF.lab-original"
cp -p "$CONF" "$CONF.bak-$(date +%Y%m%d-%H%M%S)"
# The lab VNet is "home", so rules can tell inside from outside.
sed -i -E "s|^(\s*)HOME_NET: \"[^\"]*\"|\1HOME_NET: \"[$HOME_NET_CIDR]\"|" "$CONF"
# Watch the VM's real network card (the first af-packet interface entry).
sed -i -E "0,/^  - interface: .*/s//  - interface: $IFACE/" "$CONF"
# Community ID: a standard flow hash, so the same connection can be matched across tools.
sed -i -E "0,/^(\s*)community-id: false/s//\1community-id: true/" "$CONF"
if [[ "$low_mem" == yes ]]; then
  sed -i -E "s|^(\s*)profile: (medium|high)$|\1profile: low|" "$CONF"
  if ! swapon --show | grep -q .; then
    say "   adding a 1 GB swap file (/swapfile) for headroom"
    fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null && swapon /swapfile
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi
fi
grep -nE "HOME_NET: \"|^  - interface:|community-id: true|^  profile:" "$CONF" | head -n 5 | sed 's/^/   /'

# Your own rules go in local.rules (lessons C4 and later). It's created empty,
# and listed after the downloaded rules so Suricata loads both.
LOCAL_RULES=/etc/suricata/rules/local.rules
if [[ ! -f "$LOCAL_RULES" ]]; then
  mkdir -p "$(dirname "$LOCAL_RULES")"
  printf '%s\n' '# Your own Suricata rules. One rule per line; sids 9000000-9099999 are yours.' \
    '# Test after editing: sudo suricata -T -c /etc/suricata/suricata.yaml, then sudo systemctl restart suricata' > "$LOCAL_RULES"
fi
grep -q -- "- $LOCAL_RULES" "$CONF" || sed -i -E "s|^(rule-files:)$|\1\n  - $LOCAL_RULES|" "$CONF"

say "3. Rules"
if [[ "$SKIP_UPDATE" == yes ]]; then
  echo "   --skip-update: keeping the rules already in /var/lib/suricata/rules"
else
  suricata-update --no-test || die "Downloading the rules failed (no internet from linux-srv?). Fix that, or use --skip-update."
fi
[[ -s /var/lib/suricata/rules/suricata.rules ]] || die "No rules in /var/lib/suricata/rules/suricata.rules. Run without --skip-update."
echo "   $(grep -c '^alert' /var/lib/suricata/rules/suricata.rules) rules loaded"

say "4. Testing the config, then starting Suricata"
if ! suricata -T -c "$CONF" -v >/tmp/suricata-test.log 2>&1; then
  tail -n 15 /tmp/suricata-test.log >&2
  die "Suricata's config test failed. The original config is at $CONF.lab-original."
fi
systemctl enable --now suricata >/dev/null 2>&1 || true
systemctl restart suricata
sleep 5
systemctl is-active --quiet suricata || die "Suricata didn't start. See: sudo journalctl -u suricata -n 50"

cat <<EOF

Done. Suricata is watching $IFACE and writing alerts to /var/log/suricata/eve.json.
Next:
  * On the wazuh VM: git pull, then sudo bash lab/wazuh/setup-manager.sh, so the
    linux-srv agent starts reading eve.json (give it a few minutes).
  * Check it end to end with the lessons in lab/exercises (C4: a scan as a network alert).
  * free -m   (Suricata and the Wazuh agent should both fit; if not, see the notes at the top)
EOF

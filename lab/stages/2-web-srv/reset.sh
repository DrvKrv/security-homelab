#!/usr/bin/env bash
# reset.sh - stop the stack and wipe generated data so you can start clean.
# Run ON web-srv.
#
#   bash reset.sh            # stop containers, delete generated roster + portal DB
#   bash reset.sh --keep     # stop containers but keep the generated company
#
# This puts the lab back to a known state between exercises. It does NOT remove
# Docker or the Wazuh agent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker compose -f "$HERE/docker-compose.yml" down 2>/dev/null || true

if [[ "${1:-}" == "--keep" ]]; then
  echo "Containers stopped. Generated company kept."
  exit 0
fi

rm -f "$HERE/generated/company.json" \
      "$HERE/generated/portal-users.csv" \
      "$HERE/generated/portal.db" \
      "$HERE/generated/lab-credentials.json" \
      "$HERE/generated/seed.txt"
echo "Containers stopped and generated data removed. Run install.sh for a fresh company."

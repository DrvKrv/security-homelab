#!/usr/bin/env bash
# test-rules-docker.sh - run the rule tests against a throwaway Wazuh manager
# in Docker, with the lab's decoders and rules loaded the same way the lab
# installs them. Nothing here touches your real wazuh VM.
#
#   bash lab/wazuh/test-rules-docker.sh
#   WAZUH_VERSION=4.12.0 bash lab/wazuh/test-rules-docker.sh   # pick the manager version
#
# Use the same version as your wazuh VM (the dashboard shows it under About),
# so a pass here means a pass there. Needs Docker; the image is about 2 GB.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB="$(cd "$HERE/.." && pwd)"
IMAGE="wazuh/wazuh-manager:${WAZUH_VERSION:-4.12.0}"
NAME="lab-rule-tests-$$"

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Starting $IMAGE ..."
docker run -d --name "$NAME" "$IMAGE" >/dev/null
docker cp "$HERE" "$NAME:/lab-wazuh"

# Same layout as setup-manager.sh, then each stage's files appended, as their READMEs say.
docker exec "$NAME" bash -c '
  set -e
  install -o wazuh -g wazuh -m 660 /lab-wazuh/manager/local_decoder.xml /var/ossec/etc/decoders/local_decoder.xml
  install -o wazuh -g wazuh -m 660 /lab-wazuh/manager/local_rules.xml   /var/ossec/etc/rules/local_rules.xml'
for stage in "$LAB"/stages/*/wazuh; do
  [[ -f "$stage/local_decoder.xml" ]] && docker exec -i "$NAME" bash -c 'cat >> /var/ossec/etc/decoders/local_decoder.xml' < "$stage/local_decoder.xml"
  [[ -f "$stage/local_rules.xml" ]] && docker exec -i "$NAME" bash -c 'cat >> /var/ossec/etc/rules/local_rules.xml' < "$stage/local_rules.xml"
done

echo "Checking the ruleset loads (wazuh-analysisd -t) ..."
if ! docker exec "$NAME" bash -c '/var/ossec/bin/wazuh-analysisd -t 2>&1 | grep -v "resource limit"; exit ${PIPESTATUS[0]}'; then
  echo "The ruleset doesn't load. A real manager restarted with these files would stop processing events." >&2
  exit 1
fi

echo "Restarting the manager with the lab rules ..."
docker exec "$NAME" /var/ossec/bin/wazuh-control restart >/dev/null 2>&1 || true
for _ in $(seq 1 60); do
  if echo "test" | docker exec -i "$NAME" /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q 'Phase 1'; then break; fi
  sleep 2
done

echo
docker exec "$NAME" bash /lab-wazuh/test-rules.sh

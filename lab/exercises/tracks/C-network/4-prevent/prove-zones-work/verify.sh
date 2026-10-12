#!/usr/bin/env bash
# verify.sh - runs the unit 8 segmentation checker. Run as part of:
#   ./run.sh verify C4/prove-zones-work        (on web-srv)
# PASS when web-srv reaches only the Wazuh agent ports in the internal zone.
set -uo pipefail
exec bash "$(dirname "${BASH_SOURCE[0]}")/../../../../../zones/check-segmentation.sh"

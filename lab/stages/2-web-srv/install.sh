#!/usr/bin/env bash
# install.sh - set up the Acme web stack on web-srv (Ubuntu 24.04). Run ON web-srv.
#
#   sudo bash install.sh
#
# What it does:
#   1. SAFETY: refuses to run if this VM has a public IP (the training target must
#      never be exposed to the internet - lab network only).
#   2. Installs Docker Engine + the compose plugin if they're missing.
#   3. Generates a random fake Acme roster and seeds the portal database (hashes only).
#   4. Starts three containers: the company website, the employee portal, and the
#      OWASP Juice Shop training target (pulled from its official image).
#   5. Prepares /var/log/acme-web and /var/log/acme-portal so the Wazuh agent can
#      ship web and auth logs (see wazuh/README.md to finish the agent side).
#
# Safe to run more than once. Use ./reset.sh to wipe data and start clean.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
say()  { printf '\033[36m%s  %s\033[0m\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Please run with sudo:  sudo bash $0"

# --- 1. Safety: no public IP -------------------------------------------------
say "1. Safety check: this VM must have no public IP"
IMDS="http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress"
pub="$(curl -s -H 'Metadata:true' --max-time 3 "${IMDS}?api-version=2021-02-01&format=text" 2>/dev/null || true)"
if [[ -n "${pub// }" ]]; then
  die "Refusing: this VM has a public IP ($pub). The training target must be lab-only.
Remove the public IP in the Azure portal (web-srv > Networking > IP configurations) and re-run."
fi
if [[ -z "${pub}" ]]; then
  warn "  Could not reach Azure metadata to confirm (that's normal off-Azure). Continuing."
else
  echo "  OK: no public IP assigned."
fi

# --- 2. Docker ---------------------------------------------------------------
say "2. Docker"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
docker compose version >/dev/null 2>&1 || die "Docker compose plugin missing; re-run after installing docker-compose-plugin."
systemctl enable --now docker >/dev/null 2>&1 || true

# --- 3. Company data + portal seed ------------------------------------------
say "3. Generate fake company and seed the portal"
command -v python3 >/dev/null || { apt-get update -qq && apt-get install -y python3; }
if [[ ! -f "$HERE/generated/company.json" ]]; then
  python3 "$HERE/data/generate-company.py"
else
  echo "  roster already generated (run ./reset.sh to roll a new one)"
fi
# Seed needs werkzeug; use a short-lived python container so we don't touch the host.
docker run --rm -v "$HERE:/w" -w /w/portal python:3.12-slim \
  sh -c "pip install -q Werkzeug==3.0.3 && python seed_portal.py"

# --- 4. Log directories ------------------------------------------------------
say "4. Log directories for Wazuh"
mkdir -p /var/log/acme-web /var/log/acme-portal
chmod 755 /var/log/acme-web /var/log/acme-portal

# --- 5. Bring up the stack ---------------------------------------------------
say "5. Start containers (this pulls images the first time)"
# A per-install random secret key for the portal's session cookies.
export PORTAL_SECRET_KEY="$(openssl rand -hex 32)"
docker compose -f "$HERE/docker-compose.yml" up -d --build

say "Done. Next:"
cat <<EOF
  - Company site:    http://<web-srv-ip>/           (browse from win-srv)
  - Employee portal: http://<web-srv-ip>/portal/    (demo login: demo.user / AcmeDemo1!)
  - Training target: http://<web-srv-ip>:3000/
  - Finish the Wazuh agent side:  see wazuh/README.md
  - Check everything:  bash verify.sh
EOF

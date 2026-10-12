# shellcheck shell=bash
EX_TITLE="Stop and remove an unwanted service"
EX_SUMMARY="An unwanted systemd service runs on linux-srv. Stop it, remove it, prove it."
EX_ENV="detect"
EX_ROUND="2"
EX_WHERE="linux-srv"
EX_FIX_WHERE=""
# Staging is randomized, so it lives in the ex_stage / ex_reset functions below.
EX_STAGE="ex_stage"
EX_RESET="ex_reset"
EX_WAZUH_SEARCH="agent.name: linux-srv"
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1543.002"

# A harmless stand-in: a systemd service with a plausible name whose only job is
# to sleep in a loop. It does nothing else. ex_reset stops, disables and removes it.
LAB_SVC_NAMES="sys-telemetry net-updater cache-sync health-check"

ex_stage() {
  # 1. pick a plausible service name and record it for reveal
  local svc; svc="$(pick $LAB_SVC_NAMES)"
  answer "service_name" "$svc"
  answer "unit_file" "/etc/systemd/system/$svc.service"
  # 2. write a minimal unit whose ExecStart is a harmless forever-sleep loop
  sudo tee "/etc/systemd/system/$svc.service" >/dev/null <<EOF
[Unit]
Description=$svc (lab stand-in, harmless)

[Service]
ExecStart=/bin/sh -c 'while true; do sleep 300; done'
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  # 3. reload systemd so it sees the new unit
  sudo systemctl daemon-reload
  # 4. enable it (so it survives reboot) and start it now
  sudo systemctl enable --now "$svc.service"
}

ex_reset() {
  # remove every candidate service this lesson could have created
  local svc
  for svc in $LAB_SVC_NAMES; do
    # stop and disable, then delete the unit file
    sudo systemctl disable --now "$svc.service" 2>/dev/null || true
    sudo rm -f "/etc/systemd/system/$svc.service"
  done
  # reload so systemd forgets the removed units
  sudo systemctl daemon-reload
}

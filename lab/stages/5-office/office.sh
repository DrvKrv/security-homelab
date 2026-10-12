#!/usr/bin/env bash
# office.sh - control the busy-office noise generator (unit 9). Run ON web-srv.
#
#   bash office.sh install     # write config, install the systemd timer, start it
#   bash office.sh start        # resume the timer (staff become active again)
#   bash office.sh stop         # pause the timer (the office goes quiet)
#   bash office.sh status        # is it installed and running? (no spoilers)
#   bash office.sh tick          # run one slice of activity now, prints "done"
#   bash office.sh hint          # one threat-hunting nudge at a time
#   bash office.sh reveal        # show today's red herrings (the answer key)
#   bash office.sh uninstall     # remove the timer and service
#
# What it does: makes the fake Acme staff log into the portal and browse the
# site on their own schedules, so real attacks have to be found inside normal
# noise. It only ever talks to the lab's own portal, as the fake accounts the
# web-srv installer created. It writes no new attack code.
#
# Quiet by design: a tick prints only "done". Red herrings (harmless-but-
# suspicious activity) are recorded in the git-ignored spoilers/ folder, and
# `reveal` shows them when you want to check your answer.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HERE/config.json"
SPOILERS="$HERE/spoilers"
UNIT_DIR="/etc/systemd/system"
PY="$(command -v python3 || true)"

say()  { printf '\033[36m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

[[ -n "$PY" ]] || die "python3 is required but not found."

cmd="${1:-status}"

case "$cmd" in
  install)
    [[ $EUID -eq 0 ]] || die "install needs sudo:  sudo bash $0 install"
    if [[ ! -f "$CONFIG" ]]; then
      say "Writing $CONFIG from config.example (edit it to set work hours / portal URL)."
      cp "$HERE/config.example" "$CONFIG"
      # Roll a per-install seed so this lab's "normal" is its own, and record it
      # in the git-ignored spoilers folder (never printed).
      mkdir -p "$SPOILERS"
      seed="$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')"
      "$PY" - "$CONFIG" "$seed" <<'PYEOF'
import json, sys
p, seed = sys.argv[1], int(sys.argv[2])
cfg = json.load(open(p)); cfg["seed"] = seed
json.dump(cfg, open(p, "w"), indent=2)
PYEOF
      echo "seed=$seed  (set at install)" > "$SPOILERS/office-seed.txt"
    else
      say "Keeping existing $CONFIG."
    fi

    # Resolve who runs the timer: the user who owns this checkout, not root.
    run_user="${SUDO_USER:-$(stat -c '%U' "$HERE")}"
    say "Installing systemd timer (runs as $run_user, calls office.py tick)."
    sed -e "s|@HERE@|$HERE|g" -e "s|@USER@|$run_user|g" \
      "$HERE/systemd/acme-office.service" > "$UNIT_DIR/acme-office.service"
    cp "$HERE/systemd/acme-office.timer" "$UNIT_DIR/acme-office.timer"
    systemctl daemon-reload
    systemctl enable --now acme-office.timer
    say "Done. The office is live. Pause it any time with:  sudo bash $0 stop"
    ;;

  start)
    [[ $EUID -eq 0 ]] || die "start needs sudo:  sudo bash $0 start"
    systemctl start acme-office.timer && say "Office timer resumed."
    ;;

  stop)
    [[ $EUID -eq 0 ]] || die "stop needs sudo:  sudo bash $0 stop"
    systemctl stop acme-office.timer && say "Office timer paused."
    ;;

  status)
    if systemctl list-unit-files 2>/dev/null | grep -q '^acme-office.timer'; then
      systemctl status acme-office.timer --no-pager 2>/dev/null | sed -n '1,4p'
      systemctl list-timers acme-office.timer --no-pager 2>/dev/null | sed -n '1,3p'
    else
      echo "Not installed. Run:  sudo bash $0 install"
    fi
    ;;

  tick)
    exec "$PY" "$HERE/office.py" tick "${@:2}"
    ;;

  hint)
    track="$SPOILERS/hint-count"
    mkdir -p "$SPOILERS"
    n=0; [[ -f "$track" ]] && n="$(cat "$track")"
    hints=(
      "Normal days have a shape. Chart portal logins per hour, then look for activity that sits outside it."
      "Group by source address and by account. One account doing far more than its colleagues, or one address many accounts use, is worth a second look."
      "A cluster of failures that ends in a success is not always an attack. Who is the account, and when did it last log in before today?"
      "Logins outside working hours are the classic red herring. Is the account one that would have a reason (IT, on call), or not?"
      "Compare what you flagged against office.sh reveal. Being wrong about a red herring is the lesson, not a failure."
    )
    if (( n >= ${#hints[@]} )); then
      echo "No more hints. Check your answer with:  bash $0 reveal"
    else
      printf 'Hint %d of %d:\n  %s\n' "$((n+1))" "${#hints[@]}" "${hints[$n]}"
      echo "$((n+1))" > "$track"
    fi
    ;;

  reveal)
    day="$(date -u +%Y%m%d)"
    f="$SPOILERS/red-herrings-$day.log"
    say "Red herrings staged today (UTC). These are harmless, but look suspicious:"
    if [[ -s "$f" ]]; then
      cat "$f"
    else
      echo "  (none recorded yet today)"
    fi
    echo
    echo "Legend:"
    echo "  returning_from_leave  - a rarely-seen account fumbles its password, then gets in"
    echo "  after_hours_admin     - an IT account signs in outside working hours"
    echo "  service_account_burst - one account views many pages very quickly"
    echo
    echo "Everything else in the logs is ordinary staff activity. If a real attack"
    echo "was staged separately (see lab/stages/6-capstone/), it is NOT listed here."
    ;;

  uninstall)
    [[ $EUID -eq 0 ]] || die "uninstall needs sudo:  sudo bash $0 uninstall"
    systemctl disable --now acme-office.timer 2>/dev/null || true
    rm -f "$UNIT_DIR/acme-office.timer" "$UNIT_DIR/acme-office.service"
    systemctl daemon-reload
    say "Removed the office timer and service. config.json and spoilers/ are left in place."
    ;;

  *)
    die "Usage: bash $0 {install|start|stop|status|tick|hint|reveal|uninstall}"
    ;;
esac

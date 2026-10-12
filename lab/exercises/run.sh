#!/usr/bin/env bash
# run.sh - the lab lesson runner.
#
# A menu-driven way to practise the defender's job against your own lab VMs.
# Lessons sit on a grid: 7 concept tracks (A-G) x 5 levels (Spot, Explain,
# Respond, Prevent, Hunt). Each lesson stages an incident quietly, tells you
# where to start looking, gives progressive hints, and (where there's a fix)
# checks your work.
#
# Everything here targets only your own private lab VMs. Staging reuses the
# scripts in lab/linux and lab/windows and standard admin tools.
#
# Usage:
#   ./run.sh list                    # the grid
#   ./run.sh list A1                 # lessons in a box (or a track: A, or a level: L2)
#   ./run.sh start A1                # a random lesson in box A1
#   ./run.sh start A1/ssh-bruteforce # a specific one
#   ./run.sh stage A1/ssh-bruteforce [--surprise]   # stage it quietly
#   ./run.sh hint A1/ssh-bruteforce
#   ./run.sh reveal A1/ssh-bruteforce
#   ./run.sh verify B3/linux-backdoor-user
#   ./run.sh reset  B3/linux-backdoor-user
#   ./run.sh done A1/ssh-bruteforce  # mark it finished
#   ./run.sh progress                # what you've done, and what's next
#   ./run.sh env add web             # mark an environment as built

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/engine.sh"

need() { [[ $1 -ge 1 ]] || { c_red "Usage: ./run.sh $2 <lesson>   (see ./run.sh list)"; exit 1; }; }

cmd="${1:-list}"; shift || true
case "$cmd" in
  list|ls)        cmd_list "$@" ;;
  start|begin)    need $# start;  cmd_start "$1" ;;
  stage)          need $# stage;  cmd_stage "$@" ;;
  hint)           need $# hint;   cmd_hint "$1" ;;
  reveal|answer)  need $# reveal; cmd_reveal "$1" ;;
  verify|check)   need $# verify; cmd_verify "$1" ;;
  reset)          need $# reset;  cmd_reset "$1" ;;
  done|finish)    need $# done;   cmd_done "$1" ;;
  progress)       cmd_progress ;;
  env)            cmd_env "$@" ;;
  -h|--help|help) cmd_list ;;
  *)              c_red "Unknown command '$cmd'."; cmd_list; exit 1 ;;
esac

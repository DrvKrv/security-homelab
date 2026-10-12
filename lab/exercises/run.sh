#!/usr/bin/env bash
# run.sh - the lab exercise runner.
#
# A menu-driven way to practice the detect -> investigate -> respond -> fix
# workflow against your own lab VMs. Each exercise tells you what to stage,
# what to look for in Wazuh, gives progressive hints, and (where there's a fix)
# checks your work.
#
# Everything here targets only your own private lab VMs. The staging itself is
# done by the scripts in lab/ (added separately); this runner only orchestrates
# the learning around them.
#
# Usage:
#   ./run.sh list
#   ./run.sh start 1                 # random Level 1 exercise
#   ./run.sh start 1/ssh-bruteforce  # a specific one
#   ./run.sh hint 1/ssh-bruteforce
#   ./run.sh reveal 1/ssh-bruteforce
#   ./run.sh verify 3/linux-backdoor-user
#   ./run.sh reset  3/linux-backdoor-user

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/engine.sh"

cmd="${1:-list}"; shift || true
case "$cmd" in
  list|ls)        cmd_list ;;
  start|begin)    [[ $# -ge 1 ]] || { c_red "Usage: ./run.sh start <level>[/<variant>]"; exit 1; }; cmd_start "$1" ;;
  hint)           [[ $# -ge 1 ]] || { c_red "Usage: ./run.sh hint <level>/<variant>"; exit 1; }; cmd_hint "$1" ;;
  reveal|answer)  [[ $# -ge 1 ]] || { c_red "Usage: ./run.sh reveal <level>/<variant>"; exit 1; }; cmd_reveal "$1" ;;
  verify|check)   [[ $# -ge 1 ]] || { c_red "Usage: ./run.sh verify <level>/<variant>"; exit 1; }; cmd_verify "$1" ;;
  reset)          [[ $# -ge 1 ]] || { c_red "Usage: ./run.sh reset <level>/<variant>"; exit 1; }; cmd_reset "$1" ;;
  -h|--help|help) cmd_list ;;
  *)              c_red "Unknown command '$cmd'."; cmd_list; exit 1 ;;
esac

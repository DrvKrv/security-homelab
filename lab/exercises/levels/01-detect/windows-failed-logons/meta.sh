# shellcheck shell=bash
EX_TITLE="Windows failed logons on win-srv"
EX_SUMMARY="Repeated bad logins on Windows. Find event 4625 and the lockout."
EX_STAGE_WHERE="win-srv"
EX_STAGE="powershell -ExecutionPolicy Bypass -File windows\\Simulate-FailedLogons.ps1"
EX_RESET=""
EX_WAZUH_SEARCH="data.win.system.eventID:(4625 OR 4740)"
EX_HAS_VERIFY="no"

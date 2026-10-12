# shellcheck shell=bash
EX_TITLE="Windows failed logons on win-srv"
EX_SUMMARY="Repeated bad logins on Windows. Find them and what happened to the account."
EX_STAGE_WHERE="win-srv"
EX_STAGE="powershell -ExecutionPolicy Bypass -File windows\\Simulate-FailedLogons.ps1"
EX_RESET="powershell -ExecutionPolicy Bypass -File windows\\Reset-Lab.ps1 -UnlockUser labuser"
EX_WAZUH_SEARCH="agent.name: win-srv"
EX_HAS_VERIFY="no"

# shellcheck shell=bash
EX_TITLE="Remove the Windows backdoor account"
EX_SUMMARY="Clean up the rogue Administrators account and prove it's gone."
EX_STAGE_WHERE="win-srv"
EX_STAGE="powershell -ExecutionPolicy Bypass -File windows\\Simulate-AccountChanges.ps1"
EX_RESET="powershell -ExecutionPolicy Bypass -File windows\\Reset-Lab.ps1"
EX_WAZUH_SEARCH="data.win.system.eventID:(4726 OR 4733 OR 4729)"
EX_HAS_VERIFY="no"

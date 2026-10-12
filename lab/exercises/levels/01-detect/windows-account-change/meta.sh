# shellcheck shell=bash
EX_TITLE="A new Windows admin account appears"
EX_SUMMARY="A user was created and added to Administrators on win-srv. Find it."
EX_STAGE_WHERE="win-srv"
EX_STAGE="powershell -ExecutionPolicy Bypass -File windows\\Simulate-AccountChanges.ps1"
EX_RESET="powershell -ExecutionPolicy Bypass -File windows\\Reset-Lab.ps1"
EX_WAZUH_SEARCH="data.win.system.eventID:(4720 OR 4722 OR 4724 OR 4728 OR 4732 OR 4756)"
EX_HAS_VERIFY="no"

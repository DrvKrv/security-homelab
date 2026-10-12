# shellcheck shell=bash
EX_TITLE="A new Windows admin account appears"
EX_SUMMARY="A user was created and added to Administrators on win-srv. Find it."
EX_STAGE_WHERE="win-srv"
EX_STAGE="powershell -ExecutionPolicy Bypass -File windows\\Simulate-AccountChanges.ps1 -Phase Attack"
EX_RESET="powershell -ExecutionPolicy Bypass -File windows\\Simulate-AccountChanges.ps1 -Phase Cleanup"
EX_WAZUH_SEARCH="agent.name: win-srv"
EX_HAS_VERIFY="no"

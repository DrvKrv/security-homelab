# shellcheck shell=bash
EX_TITLE="Remove the Windows backdoor account"
EX_SUMMARY="Clean up the rogue Administrators account and prove it's gone."
EX_STAGE_WHERE="win-srv"
EX_STAGE="powershell -ExecutionPolicy Bypass -File windows\\Simulate-AccountChanges.ps1 -Phase Attack"
EX_RESET="powershell -ExecutionPolicy Bypass -File windows\\Simulate-AccountChanges.ps1 -Phase Cleanup"
EX_WAZUH_SEARCH="agent.name: win-srv"
EX_HAS_VERIFY="no"

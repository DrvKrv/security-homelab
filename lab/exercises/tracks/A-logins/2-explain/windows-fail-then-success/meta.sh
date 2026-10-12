# shellcheck shell=bash
EX_TITLE="Windows failed logons, then one success?"
EX_SUMMARY="A run of failed Windows logons on win-srv. Build the timeline and decide whether anyone got in."
EX_ENV="core"
EX_ROUND="1"
EX_WHERE="win-srv"
EX_FIX_WHERE=""
# The scenario script prepares its own throwaway lab account (first run only),
# makes a few wrong-password attempts, and on most runs one real logon after.
EX_STAGE="powershell -ExecutionPolicy Bypass -File windows\\Simulate-SuccessfulLogon.ps1 -Phase Scenario"
EX_RESET="powershell -ExecutionPolicy Bypass -File windows\\Simulate-SuccessfulLogon.ps1 -Phase Cleanup"
EX_WAZUH_SEARCH="agent.name: win-srv"
EX_HAS_VERIFY="no"
EX_STAGE_CONFIRM="no"
EX_ATTACK="T1110.001"

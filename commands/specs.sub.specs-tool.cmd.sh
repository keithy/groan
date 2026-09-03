# Dispatcher alias: `groan specs` -> ./specs-tool
#
# Mirrors the setup-utility dispatcher: re-anchors g_subcmd_locations
# to the sub-suite via g_readConfig, then dispatches the next argument.
# When invoked with no further argument, falls back to g_actions
# (which prints the specs listing under the dispatcher crumb).

me "$BASH_SOURCE" #tradition

s_description="spec/test runner for installed tools"

# Read the sub-suite's conf before the metadata bail so the recursion
# in --all can use g_locations correctly even when sourced with
# METADATAONLY=true (the walker does that).
g_parseScriptPathMore "$s_path"
g_readConfig "$s_dest_path"

$METADATAONLY && return

g_shiftInto_g_next && g_dispatch "$g_next" || g_actions

# Dispatcher alias: `groan specs` -> ./specs-tool
#

me "$BASH_SOURCE" #tradition

s_description="spec/test runner for installed tools"
$METADATAONLY && return

g_parseSubCmdScriptPath "$s_path"
g_readConfig "$s_dest_path"

g_nextDispatch 
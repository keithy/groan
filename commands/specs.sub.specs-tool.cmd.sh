# Dispatcher alias: `groan specs` -> ./specs-tool
#

me "$BASH_SOURCE" #tradition

s_description="spec/test runner for installed tools"

g_subTool "${my_dir}/../specs-tool" specs

$METADATAONLY && return

g_readConfig "$s_dest_path"
g_nextDispatch

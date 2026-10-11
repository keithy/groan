# Dispatcher alias: `groan setup` -> ./setup-tool
#

me "$BASH_SOURCE" #tradition

s_description="setup tool (setup-tool sub-suite)"

g_subTool "${my_dir}/../setup-tool" setup

$METADATAONLY && return

g_readConfig "$s_dest_path"
g_nextDispatch

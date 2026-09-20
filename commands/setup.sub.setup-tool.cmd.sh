# Dispatcher alias: `groan setup` -> ./setup-tool
#
# See remotes.sub.sensible.cmd.sh for the pattern.

me "$BASH_SOURCE" #tradition

s_description="setup tool (setup-tool sub-suite)"

$METADATAONLY && return

g_parseScriptPathMore "$s_path"
g_readConfig "$s_dest_path"
g_nextDispatch 

# Dispatcher alias: `groan utilities` -> ./utilities-tool
#
# See remotes.sub.sensible.cmd.sh for the pattern.

me "$BASH_SOURCE" #tradition

s_description="utilities (utilities-tool sub-suite)"
$METADATAONLY && return

g_parseScriptPathMore "$s_path"
g_readConfig "$s_dest_path"
g_shiftInto_g_next && g_dispatch "$g_next" || g_actions
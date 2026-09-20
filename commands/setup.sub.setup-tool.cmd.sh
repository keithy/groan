# Dispatcher alias: `groan setup` -> ./setup-tool
#
# See setup.sub.setup-tool.cmd.sh for the pattern.

me "$BASH_SOURCE" #tradition

s_description="setup tool (setup-tool sub-suite)"

$METADATAONLY && return

# Extended parser used to recognise dispatcher aliases of the form
# <X>.sub.<Y>.cmd.<Z>.<ext> — i.e. sub-command X dispatches into command Y
# passing Z as the next argument.
g_parseScriptPathMore "$s_path"

g_readConfig "$s_dest_path"
g_nextDispatch 

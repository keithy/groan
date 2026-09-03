# Dispatcher alias: `groan remotes` -> ./sensible
#
# The walker (g_walk_commands) and --all both follow dispatcher
# aliases of the form <X>.sub.<Y>.cmd.<Z>.<ext> to discover nested
# command suites. This file makes `./groan remotes` (and the
# equivalent `./groan remotes <sub>`) dispatch into the sensible
# sub-suite.

me "$BASH_SOURCE" #tradition

s_description="remote execution and deployment (sensible sub-suite)"
$METADATAONLY && return

g_parseScriptPathMore "$s_path"
g_readConfig "$s_dest_path"
g_shiftInto_g_next && g_dispatch "$g_next" || g_actions
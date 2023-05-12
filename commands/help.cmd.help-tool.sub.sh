# Subcommand Alias
#
# A generic sub-command invocation that invokes a nested command e.g. groan help -> groan/helper
#
# by Keith Hodges 2018
#
# The idea is that sub-commands that map to nested commands have identical code (i.e. this file)
# taking parameters from their own name
#
# Sub-commands like 'help.cmd.help-tool.sub.sh' are invoked based upon their prefix <sub>.cmd.*
# 
# This script is then responsible for interpreting useful parameters embedded in its own name.
# Other scripts may provide alternative parameterizations and interpretations.
#
# In this case the sub-command in the parent command's list, is implemented by the .cmd.<helper>.sub
# command contained in the parent folder, whose target script is provided within <helper>.commands 
# The target script may be either
# 1) a specific sub-command
# 2) a g_dispatcher, selecting the sub-sub-command based upon the next argument
# 3) any other bespoke script or g_dispatcher

me "$BASH_SOURCE" #tradition

g_parseScriptPathMore
 "${s_path}"

g_debug_kv s_file
g_debug_kv s_dest_path

g_readConfig "$s_dest_path"

g_shiftArgsInto_g_next
 && g_dispatch "$g_next" || g_default

# "This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
# Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed
# subject to the same license."


# Sub-command
#
# by Keith Hodges 2023
#

me "$BASH_SOURCE" #tradition

crumb="$s_cmd"
g_readConfig "${s_dir}/${s_rest//./\/}"
g_nextDispatch

#"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
# Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed
# subject to the same license."

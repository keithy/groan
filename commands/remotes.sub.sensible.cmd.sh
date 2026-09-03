# Dispatcher alias: `groan remotes` -> ./sensible-tool
#
# The walker and --all both follow dispatcher aliases of the form
# <X>.sub.<Y>.cmd.<Z>.<ext> to discover nested command suites. This
# file makes `./groan remotes` (and the equivalent `./groan remotes
# <sub>`) dispatch into the sensible sub-suite.
#
# Note: the sub-suite lives in `sensible-tool/` but the public command
# name is `sensible` (matching the README and the v1.1 design). The
# dispatcher file is named `remotes.sub.sensible.cmd.sh` so `c_file`
# inside the sub-suite is `sensible`, and `sensible.conf` is the conf
# file. g_readConfig can't auto-discover the dir mismatch, so we
# compute the absolute path from my_path (set by me() above).

me "$BASH_SOURCE" #tradition

s_description="remote execution and deployment (sensible sub-suite)"
$METADATAONLY && return

g_parseScriptPathMore "$s_path"
# my_path = /.../groan-a-lot/groan/commands/remotes.sub.sensible.cmd.sh
# Strip three levels (commands/remotes.sub.sensible.cmd.sh) to reach
# the repo root, then go into sensible-tool/.
g_readConfig "${my_path%/*/*/*}/sensible-tool/sensible"
g_shiftInto_g_next && g_dispatch "$g_next" || g_actions
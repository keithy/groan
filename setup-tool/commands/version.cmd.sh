# setup.version.sh
me "$BASH_SOURCE" #tradition

s_description="show version information"
s_usage="$breadcrumbs version"

$METADATAONLY && return

printf "$g_home "
git --git-dir="$g_dir/.git" --work-tree="$g_dir" describe --long --tags --dirty --always 2>/dev/null || echo "version unknown"

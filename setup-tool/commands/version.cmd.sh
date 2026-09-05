# setup.version.sh
me "$BASH_SOURCE" #tradition

s_description="show version information"
s_usage="$breadcrumbs"

$METADATAONLY && return

function print_git_version () {
    local label="$1" dir="$2" ver
    if [[ -d "$dir/.git" || -f "$dir/.git" ]]; then
        ver=$(git --git-dir="$dir/.git" --work-tree="$dir" describe --long --tags --dirty --always 2>/dev/null)
        if [[ -n "$ver" ]]; then
            printf "%-20s %s\n" "${label}:" "$ver"
            return
        fi
    fi
    printf "%-20s %s\n" "${label}:" "version unknown"
}

print_git_version "${g_cmd:-tool}" "$g_dir"

if [[ -d "$g_dir/.gitmodules" && -f "$g_dir/.gitmodules" ]]; then
    while read -r sm_path; do
        if [[ -n "$sm_path" && -d "$g_dir/$sm_path" ]]; then
            print_git_version "  ${sm_path##*/}" "$g_dir/$sm_path"
        fi
    done < <(git --git-dir="$g_dir/.git" --work-tree="$g_dir" config --file "$g_dir/.gitmodules" --get-regexp path 2>/dev/null | awk '{print $2}')
fi

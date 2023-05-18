# groan version.sub.sh
#
# by Keithy 2019
#
me "$BASH_SOURCE" #tradition #tradition

command="version"
description="versions according to git"
usage="$breadcrumbs"

$METADATAONLY && return 0

c_file_list=()
crumbsList=()
g_findCommands "${g_path}" "${g_file}"

$GDEBUG && g_echo "${!c_file_list[@]}"

# get the cached version, the git version, use cache if git not working, if changed write cache
function get_version()
{
  local version dir="$1" crumbs="${2:-}"

  if [[ -f "$dir/.version" ]]
  then
    version=$(<"$dir/.version")
  else
    if version=$(cd "$dir"; git describe --long --tags --dirty --always 2> /dev/null )
    then
      echo "$version" > "$dir/.version"
    else
      version=""
    fi
  fi
 
  [ -n "$version" ] && printf "%s:${bold}${dim}%16s${reset} ${bold}%s${reset}\n" "${version}" "(${dir##*/})" "$crumbs"
}

# get the version of this sub-command's command (i.e. groan)
get_version "$g_dir"

for i in "${!c_file_list[@]}"
do
  # echo '>>' ${c_file_list[i]}
  g_parseScriptPath "${c_file_list[i]}"
  g_readConfig "$s_dir" "$s_file"
  get_version "${s_dir}" "${crumbs_list[i]}"
done
 
exit 0

#"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
#Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed subject to the same license."

# groan help commands.cmd.sh
#
# by Keith Hodges 2018

$DEBUG && echo "${dim}${BASH_SOURCE}${reset}"

command="commands"
description="list available commands"
#since help doesn't exec anything many common options don't apply
commonOptions="--theme=light    # alternate theme"
usage="$breadcrumbs    # list commands"

$SHOWHELP && executeHelp
$METADATAONLY && return
 
function list_commands()
{
  commandFile="$1"
  readLocations "$commandFile"

  for loc in ${locations[@]} ; do

    $DEBUG && echo "Looking for $target in: $loc"

    for scriptPath in $loc/*
    do
      scriptName="${scriptPath##*/}"        
      scriptPrefix="${scriptName%%.cmd.*}"
      if [[ "$scriptPrefix" =~ [^.].*\.sub\. ]]; then
        if [[ -f "$scriptPath" ]]; then
          scriptSubcommand="${scriptPrefix%%.sub.*}"

          breadcrumbs="$2"
        
          executeScriptPath "$scriptPath" "$loc" "$scriptName" "$scriptSubcommand"
 
          printf "%-45s" "$breadcrumbs"
          echo "$description"
        fi
      fi
    done
  done
}

$DEBUG && echo "METADATAONLY=${bold}true${reset}"
METADATAONLY=true

commandFileList=("$rootCommandFile")
breadcrumbsList=(${rootCommandFile##*/})
 
until [ ${#commandFileList} -eq 0 ]
do
  firstCommandFile="${commandFileList[0]}"
  firstBreadcrumbs="${breadcrumbsList[0]}"

  echo "${bold}${firstCommandFile##*/} commands:${reset}"

  if $DEBUG; then
    echo
    for i in "${!commandFileList[@]}"; do    
         printf "(%d) %-45s" $i ${breadcrumbsList[i]}
         echo "${commandFileList[i]}"
    done
    echo
  fi

  list_commands "$firstCommandFile" "$firstBreadcrumbs"

  #remove first command file from list
  old_array=("${commandFileList[@]}")
  old_bc_list=("${breadcrumbsList[@]}")
  commandFileList=()
  breadcrumbsList=()
  for i in "${!old_array[@]}"; do
    if [ "${old_array[i]}" != "$firstCommandFile" ]; then
      commandFileList+=( "${old_array[i]}" )
      breadcrumbsList+=( "${old_bc_list[i]}" )
    fi
  done
  unset old_array
  unset old_bc_list
  
  echo
done

exit 0

#"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
#Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed subject to the same license."
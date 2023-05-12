# groan single command list of c_sub_cmds.sub.sh
#
# by Keith Hodges 2019

me "$BASH_SOURCE" #tradition

command="commands"
description="list $c_file $command"

#since help doesn't exec anything many common options don't apply
options_common_vertical=\
"
--theme=0                        alternate theme
--install                        install as bash alias
--install=<name>                 install as bash alias <name>
--install=<name> --config=<alt>  install with config <alt>
--temp                           print the temp directory
--which                          print the code directory
"

usage=\
"
$breadcrumbs                            list commands
$breadcrumbs --install                  install as bash alias
$breadcrumbs --install=other --C=other  install as bash alias with config
"

$METADATAONLY && return

g_declare_options LIST INSTALL SHOW_TEMP SHOW_CODE

LIST=true
install_allowed=true
install_as=""
for arg in "$@"
do
    case "$arg" in
      *)
        LIST=false
      ;;& 
	  --install=*)
            INSTALL=true
			install_as=${arg#--install=}
      ;;
      --install)
            INSTALL=true
      ;;
	  --temp)
            SHOW_TEMP=true
      ;;
      --which)
            SHOW_CODE=true	
      ;;
      *)
        :
      ;;
    esac
done

if $SHOW_TEMP; then
	echo "$g_tmp"
	exit
fi 

if $SHOW_CODE; then
	echo "$g_dir"
	exit
fi 

if $INSTALL; then

	tag="##:${install_as:-$g_file}:##"

	function clean()
	{
		local file="$1" #1) dest file
		{ \rm "$file" && grep -v "$tag" > "$file" ; } < "$file" || true
	}

	function append_to ()
	{
		local file="$1" #1) dest file
		local line="$2" #2) line to add
		touch "$file"
		printf "%s %s\n" "$line" "$tag" >> "$file"
	}

	bashrc="${g_tmp}/bashrc"
	touch "$HOME/.bashrc"
	cp "$HOME/.bashrc" "$bashrc" || true

	$GDEBUG && echo "Before:" && cat "$bashrc"

	clean "$bashrc"

	$GDEBUG && echo "Cleaned:" && cat "$bashrc" 

	with_config=""
	if [[ -n ${CONFIG+x} ]]; then
		with_config=" -C=$CONFIG"
	fi

	if [[ "${install_as}" ]]; then
	 	append_to "$bashrc" "alias ${install_as}='${g_file} ==g_file=${install_as}$with_config'"
	else
	 	append_to "$bashrc" "alias ${g_file}='${g_file}$with_config'"
	fi

	$LOUD && echo "installed alias ${bold}${install_as:-$g_file}${reset}"
	$VERBOSE && echo "${dim}bashrc${reset}" && cat "$bashrc" || true
	$CONFIRM && cp "$bashrc" "$HOME/.bashrc" || echo "DRY-RUN --confirm to apply"

	$CONFIRM && source "$HOME/.bashrc"
fi

$LIST || exit

c_file_list=()
crumbsList=()

# start search at this level, not the top level
g_findCommands "$c_file" "$breadcrumbs" false

(( bw = ${breadcrumbs_width:-20} + ${#breadcrumbs} ))

function list_sub_cmds()
{
	local c_file="$1"
	local crumbs="$2"

	g_readLocations "$c_file"

	local cmds=()
	for s_dir in "${g_locations[@]}"
	do
		for s_path in "$s_dir/${g_default_subcommand}.sub."*
		do
			cmds+=("$s_path")
		done
	done

	# Display the default sub-command at the top of  the list (without its breadcrumb)
    for s_path in "${cmds[@]}"
	  do
		g_parseScriptPathMore
 "$s_path"
		$GDEBUG && echo "Parsed: …${s_dir##*/}${dim}/${reset}$s_file (${s_sub_cmd:-no subcommand})"

		METADATAONLY=true
		g_executeScriptPath "$s_path"  

		printf "%-${bw}s" "$crumbs"
		echo "$description"
	  done

	for s_dir in "${g_locations[@]}" ; do

		#Display the c_sub_cmds (with breadcrumb)
		for s_path in "$s_dir"/[^_]*.sub.*
		do
		  g_parseScriptPathMore
 "$s_path"
		  $GDEBUG && echo "Parsed: …${s_dir##*/}${dim}/${reset}$s_file (${s_sub_cmd:-no subcommand})" 

		  # commented out this if clause so as to include display of commands that go a level deeper
		  # these would not normally be included in the full recursive list of commands
  
		  #if [[ -n "$s_sub_cmd" ]] && [[ "$s_dest_subcmd_name" == *.sub.* ]]; then
 
			crumbs="$2 $s_sub_cmd"

			METADATAONLY=true
			printf "%-${bw}s" "$crumbs"
			g_executeScriptPath "$s_path"  

			echo "${description%%$'\n'*}" # first line
			unset description
		 # fi
		done
	done
}

if $GDEBUG; then # print out results of recursive search
  echo
  for i in "${!c_file_list[@]}"; do    
       printf "(%d) %-45s" "$i" "${crumbsList[i]}"
       echo "${c_file_list[i]}"
  done
  echo
fi

# only display our direct c_sub_cmds (no need to loop)
i=0
#for i in "${!c_file_list[@]}"; do
  displayName="${c_file_list[i]##*/}"
  #echo "${bold}${displayName/-/ } commands:${reset}"
  echo "${bold}${g_dir##*/} commands:${reset}"
  
  list_sub_cmds "${c_file_list[i]}" "${crumbsList[i]}"
  
  echo
#done

exit 0

#"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
#Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed subject to the same license."

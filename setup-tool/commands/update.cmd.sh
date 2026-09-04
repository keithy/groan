# groan.setup.update.sh
#
# by Keith Hodges 2019
#
$GDEBUG && echo "${dim}${BASH_SOURCE[0]}${reset}"

command="update"
s_description="self-update ${g_file}"
s_opts=\
"
--code           pull latest framework/tool code from git
"
s_usage=\
"$breadcrumbs                         # update tool data libraries (if defined)
$breadcrumbs --code --confirm        # pull latest code from git"

$METADATAONLY && return

$GDEBUG && echo "Command: '$command'"

UPDATE_CODE=false
UPDATE_DATA=false
HAD_ACTION=false

if [[ $# -eq 0 ]]; then
	UPDATE_DATA=true
fi

for arg in "$@"
do
  case "$arg" in
    --code)
	    UPDATE_CODE=true
	    HAD_ACTION=true
    ;;
    -*)
    # ignore other options
    ;;
    *)
	:
    ;;
  esac
done

if $UPDATE_DATA || ! $HAD_ACTION; then
	# Update any libraries from repositories
	if [[ -n ${repositories+x} && ${#repositories[@]} -gt 0 ]]; then
		repo_directory="${repo_directory:-${g_dir}/library}"
	
		for repo in "${repositories[@]}"; do
			repo_name="${repo##*/}"
			repo_name="${repo_name%.git}"
			repo_local="${repo_directory}/${repo_name}"
			\rm -rf "${repo_local}"
			git clone "${repo}" "${repo_local}"
			\rm -rf "${repo_local}/.git"

			$LOUD && echo "Data files updated (${repo_name})"
		done
	else
		if ! $UPDATE_CODE; then
			p_echo "No data repositories configured to update."
			p_echo "Use '${breadcrumbs} --code --confirm' to pull latest code."
		fi
	fi
fi

if $UPDATE_CODE; then
	$DRYRUN && echo "Code Update: --confirm required" && exit 0
	[[ -d "$g_dir/.git" ]] && git -C "$g_dir" pull
fi

exit 0

"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
#Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed subject to the same license."

# groan.setup.update.sh
#
# by Keith Hodges 2019
#
$GDEBUG && echo "${dim}${BASH_SOURCE[0]}${reset}"

command="update"
s_description="self-update ${g_file}

Pulls the latest source code from git (including submodules) or updates configured data repository libraries.

Destructive/write operations default to dry-run mode; pass --confirm (-Y) to execute."
s_opts=\
"
--code              pull latest framework source code from git ; (requires --confirm)
--submodules        update and sync all git submodules ; (requires --confirm)
--data              update configured data repository libraries ;
--check             fetch remotes and check for available updates ;
"
s_usage=\
"$breadcrumbs --code --confirm        ; pull latest code from git
$breadcrumbs --submodules --confirm  ; update all git submodules
$breadcrumbs --data                  ; update data repository libraries
$breadcrumbs --check                 ; check if remote updates are available"

$METADATAONLY && return

$GDEBUG && echo "Command: '$command'"

UPDATE_CODE=false
UPDATE_SUBS=false
UPDATE_DATA=false
CHECK_STATUS=false
HAD_ACTION=false

if [[ $# -eq 0 ]]; then
	if [[ -n ${repositories+x} && ${#repositories[@]} -gt 0 ]]; then
		UPDATE_DATA=true
	else
		g_displayHelp
		exit 0
	fi
fi

for arg in "$@"
do
  case "$arg" in
    --code)
	    UPDATE_CODE=true
	    HAD_ACTION=true
    ;;
    --submodules | --submodule | --subs)
	    UPDATE_SUBS=true
	    HAD_ACTION=true
    ;;
    --data)
	    UPDATE_DATA=true
	    HAD_ACTION=true
    ;;
    --check | --status)
	    CHECK_STATUS=true
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

if $CHECK_STATUS; then
	if [[ -d "$g_dir/.git" ]]; then
		$LOUD && p_echo "Fetching remotes for $g_dir..."
		git -C "$g_dir" fetch --quiet 2>/dev/null || true
		git -C "$g_dir" status -sb
	else
		p_echo "Not a git repository: $g_dir"
	fi
	exit 0
fi

if $UPDATE_DATA || (! $HAD_ACTION && [[ -n ${repositories+x} && ${#repositories[@]} -gt 0 ]]); then
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
		if ! $UPDATE_CODE && ! $UPDATE_SUBS; then
			p_echo "No data repositories configured to update."
			p_echo "Use '${breadcrumbs} --code --confirm' to pull latest code."
		fi
	fi
fi

if $UPDATE_CODE || $UPDATE_SUBS; then
	if ! $CONFIRM; then
		p_echo "# DRY-RUN --confirm to apply"
		exit 0
	fi
fi

if $UPDATE_CODE; then
	if [[ -d "$g_dir/.git" ]]; then
		$LOUD && p_echo "Pulling latest code in $g_dir..."
		git -C "$g_dir" pull
	else
		p_echo "Not a git repository: $g_dir"
	fi
fi

if $UPDATE_SUBS || ($UPDATE_CODE && [[ -f "$g_dir/.gitmodules" ]]); then
	if [[ -d "$g_dir/.git" && -f "$g_dir/.gitmodules" ]]; then
		$LOUD && p_echo "Updating git submodules in $g_dir..."
		git -C "$g_dir" submodule update --init --recursive
	fi
fi

exit 0

#"This Code is distributed subject to the MIT License, as in
# http://www.opensource.org/licenses/mit-license.php .
# Additional sub-commands created by users may be licensed
# under their own terms."

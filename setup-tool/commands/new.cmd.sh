# groan new.sub.sh
#
# by Keith Hodges 2019
#
#
me "$BASH_SOURCE" #tradition
command="new"
s_description="create a new project/file structure from a template

Copies a template directory structure into a target path using rsync.

Destructive/write operations default to dry-run mode; pass --confirm (-Y) to execute."

s_opts=\
"
--list | --options   list available template presets ;
--template=<tmpl>    select template by name ; (-t=<tmpl>)
--go-ahead           allow populating an existing directory ;
"

s_usage=\
"$breadcrumbs --list                   ; list available project templates
$breadcrumbs my-project --starter     ; create project using 'starter' template
$breadcrumbs my-project -t=starter   ; create project using 'starter' template
$breadcrumbs --starter                 ; inspect files in 'starter' template"

# --options
[[ -z ${g_config_preset_locations+x} ]] && g_config_preset_locations=("${c_dir:-}")

extra="\nAvailable templates:\n"
for presetDir in "${g_config_preset_locations[@]}" 
do
   	for found in "$presetDir/"*.tmpl
   	do
       	title=""
       	#[[ -f "$found/.gitignore" ]] && title="$(grep -m 1 -i "^#" "$found/.gitignore")"
       	[[ -f "$found/README.md" ]] && title="$(grep -m 1 -i "^#" "$found/README.md")"
       	extra="$(printf "$extra %17s - $title" "${found##*/}")\n"
   	done
done

$METADATAONLY && return

$GDEBUG && echo "Command: '$command'"

TEMPLATE=""
targetPath=""
templatePath=""
LIST_TEMPLATES=false
INSTALL=false
NO_TRAMPLE=true

for arg in "$@"
do
    case "$arg" in
        --options|--list)
            LIST_TEMPLATES=true
        ;;
        --go-ahead)
            NO_TRAMPLE=false
        ;;
        --t=|--te=|--tem=|--temp=|--templ=|--templa=|--templat=|--template= )
            TEMPLATE="${arg#--t*=}"
        ;; 
        --*)
            TEMPLATE="${arg#--}"
        ;;
        -*)
        # ignore other options
        ;;
        # ? in this context is a single letter wildcard 
        ?*) 
            targetPath="$arg"
            INSTALL=true
        ;;
    esac
done

$LIST_TEMPLATES && printf "$extra\n\n" && exit 0

[[ -z "$TEMPLATE" ]] && g_displayHelp && exit 0

templatePath="$TEMPLATE"
# auto-append .tmpl extension if not present
[ "${templatePath##*.}" != "tmpl" ] && templatePath="${templatePath}.tmpl"

# search for template dir
if [[ ! -d "$templatePath" ]]; then
	for presetDir in "${g_config_preset_locations[@]}" 
	do
   		[[ -d "${presetDir}/${templatePath}" ]] && templatePath="${presetDir}/${templatePath}"
	done
fi

# exit if template directory does not exist
[[ ! -d "$templatePath" ]] && echo "$TEMPLATE not found" && exit 1

# show if the template exists and install is not requested
if [ $INSTALL == false ]; then
    echo "Showing template in: $templatePath" 1>&2  
    find "$templatePath"
    exit 0
fi

$NO_TRAMPLE && [[ -d "$targetPath" ]] && echo "$targetPath exists (--go-ahead) to populate existing directory" && exit 1

# INSTALL
r_s_opts=""
$VERBOSE && r_s_opts="v"

$LOUD && echo "${bold}Creating new project using:${reset} $TEMPLATE"
$LOUD && echo "rsync -rLtO${r_s_opts}" "$templatePath/" "$targetPath"
$DRYRUN && echo "${dim}dryrun:  --confirm required to proceed${reset}"

if $CONFIRM; then
    rsync "-rLtO${r_s_opts}" "$templatePath/" "$targetPath"
    echo "Created $targetPath"
fi

exit 0

#"This Code is distributed subject to the MIT License, as in
# http://www.opensource.org/licenses/mit-license.php .
# Additional sub-commands created by users may be licensed
# under their own terms."

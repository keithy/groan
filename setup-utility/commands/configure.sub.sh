# groan configure.sub.sh
#
# by Keith Hodges 2010
#
me "$BASH_SOURCE" #tradition

command="configure" ; s_description="select or edit configuration file"
s_opts=\
"
--options        list options and presets
--show           show current config file
"
s_usage=\
"
$breadcrumbs                                 # show current config file
$breadcrumbs --show                          # show current config file
$breadcrumbs --edit                          # edit current config file
$breadcrumbs --options                       # list available location options
$breadcrumbs --install=<option> <file.conf>  # install file at given location (local/user/global)
$breadcrumbs --help                          # this message
"

$METADATAONLY && return

$GDEBUG && echo "Command: '$command'"

g_declare_options SHOWCONFIG EDITCONFIG SHOWOPTIONS INSTALL GETFILE

configure_name="$CONFIG"
config_option=""
SHOWCONFIG=true

for arg in "$@"
do
    case "$arg" in
        --current|--show)
            SHOWCONFIG=true
        ;;
        --edit)
            EDITCONFIG=true
            SHOWCONFIG=false
        ;;
        --options)
            SHOWs_opts=true
            SHOWCONFIG=false
        ;;
        --install=*)
            config_option="${arg#--install=}"
            INSTALL=true
            SHOWCONFIG=false
        ;;
        -*)
        # ignore other options
        ;;
        # ? in this context is a single letter wildcard 
        ?*) 
            configure_name="$arg"
        ;;
    esac
done
 
g_preset_match="${g_preset_match:-*.conf.sh}"

function p_path ()
{
    local path="$1" loc opt i title="${2:-Current setting}"
     
    for i in "${!g_config_options[@]}"
    do
        loc=${g_config_file_locations[$i]}
        opt=${g_config_options[$i]}
        path=${path/$loc/($opt)}
    done

    printf "${path:-default (no config)}"
}

# Find all the configs available in the various locations
# call the callback function with the :idx :name and :filepath
function foreach_config_do ()
{
    local i path needle="$1" callback_conf="$2" callback_location="${3:-}"

    for i in "${!g_config_options[@]}"
    do
        [[ -n "${callback_location}" ]] && "$callback_location" "$i" "${g_config_options[$i]}" "${g_config_file_locations[$i]}"

        for path in "${g_config_file_locations[$i]}"/${needle}.conf ; do
            if [[ -f "$path" ]]; then
               "$callback_conf" "$i" "${path##*/}" "$path" || return 11
            fi
        done
    done
}

function p_location ()
{
    local idx option="$2" path="$3" 
    (( idx = $1 + 1 ))

    case "$option" in
        local)
            path="(pwd)"
        ;;
        *)
            path="${path/${g_dir}/($g_file)}"
        ;;
    esac

    printf "  %d) %s\t${dim}[ %s ]${reset}\n" "$idx" "$option" "$path"
}

function p_config_name ()
{
    local name="$2" 
    printf "              \t${name}\n"
}

function p_config_file ()
{
    local name="$2" path="$3"

    printf "${bold}${name}${reset}\n"
    cat "$path"
    return 11 # finish iteration  
}

function edit_config_file ()
{
    local name="$2" path="$3"

    if [[ "$name" == $match ]]; then
        $EDITOR "${path}"
        return 11 # finish iteration  
    fi
}


# Find all the presets available in the various locations
# call the callback function with the :idx :name and :filepath
# callback returns 0 to finish (other will keep going)
function foreach_preset_do ()
{
    local name path needle="$1" callback="$2" 

    local -A locations
    locations['pwd']='.'
    locations['built-in']="$g_dir"

    for category in "${!locations[@]}"; do
        for path in "${locations[$category]}"/**/${needle}.conf.sh ; do
            "$callback" "$category" "${path##*/}" "$path" || return 10       
        done
    done
}

function p_preset_name()
{
    local category="$1" filename="$2" path="$3"

    case "$category" in
        pwd)
            printf "   %s\n" "${path/./(pwd)}"
        ;;
        built-in)
            printf "   %s\n" "${path/${g_dir}/($g_file)}"
        ;;
    esac
}

function p_preset_file ()
{
    local category="$1" filename="$2" path="$3"

    printf "${bold}${filename}${reset}\n"
    
    cat "$path"
    return 11 # finish iteration  
}

function install_preset_file ()
{
    local n category="$1" filename="$2" path="$3"

    (( n = idx + 1 ))

    $LOUD && echo "$n) $config_option"
    mkdir -p "${g_config_file_locations[$idx]}"
    $LOUD && echo "cp" "$path" "${g_config_file_locations[$idx]/$PWD/\$pwd}/${CONFIG}.conf"
    $DRYRUN && echo "dryrun:  --confirm required to proceed"

    if $CONFIRM; then
        mkdir -p "${g_config_file_locations[$idx]}"
        cp "$path" "${g_config_file_locations[$idx]}/${CONFIG}.conf"
        echo "$filename installed as $config_option configuration"
    fi

    return 1 # finish iteration  
}

if $SHOWOPTIONS; then

    printf "\nSelectable config options:\n"
    foreach_config_do "*" p_config_name p_location

    printf "\nInstallable preset files: (${g_preset_match})\n"
    foreach_preset_do "*" p_preset_name

    echo
    printf "Current setting: " ; p_path "${g_config:-none (no config) ($CONFIG not found)}"
    echo
fi

$INSTALL && $VERBOSE && SHOWCONFIG=true

if $SHOWCONFIG; then

    match="${configure_name%.conf}"

    foreach_config_do "$match" p_config_file || exit 0

    match="${configure_name%.conf.sh}"

    foreach_preset_do "$match" p_preset_file || exit 0

    echo
    printf "Current setting: $CONFIG ($match.conf not found)"
    echo

    exit 1 
fi

# --edit currently selected configuration file contents
if $EDITCONFIG; then
    match="${configure_name%.conf}"

    foreach_config_do "$match" edit_config_file || exit 0

    echo
    printf "Current setting: " ; p_path "${g_config:-$CONFIG ($CONFIG.conf not found)}"
    echo

    exit 1
fi

if $INSTALL; then

    for idx in "${!g_config_options[@]}"
    do
        [[ "$config_option" == "$idx" ]] && config_option="${g_config_options[$idx]}" && break
        [[ "$config_option" == "${g_config_options[$idx]}" ]] && break
        idx=""
    done
 
    [[ -z "$idx" ]] && echo "--install=<location> needed (${g_config_options[@]})" && exit 1

    match="${configure_name%.conf*}"

    foreach_preset_do "$match" install_preset_file || exit 0

    echo
    printf "Current setting: " ; p_path "${g_config:-}"
    echo " (${bold}$match${reset} not found)"

    exit 1 
fi

exit 0

#"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
#Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed subject to the same license."
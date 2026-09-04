# groan.self-install.sh
#
# by Keith Hodges 2010
#

me "$BASH_SOURCE" #tradition

command="self-install"
s_description="install alias, autocompletion, or symlink in system"
s_usage="usage:
$breadcrumbs self-install --alias [name]
$breadcrumbs self-install --unalias [name]
$breadcrumbs self-install --completion [name]
$breadcrumbs self-install /usr/local/bin --link
$breadcrumbs self-install --unlink"

$METADATAONLY && return

$GDEBUG && echo "Command: '$command'"

ADDALIAS=false
UNALIAS=false
COMPLETION=false
ADDLINK=false
UNLINK=false
aliasName="$g_cmd"
installPath="/usr/local/bin"

for arg in "$@"
do
    case "$arg" in
    --alias | --alias=*)
        ADDALIAS=true
        if [[ "$arg" == --alias=* ]]; then
            aliasName="${arg#--alias=}"
        fi
    ;;
    --unalias | --unalias=* | --uninstall)
        UNALIAS=true
        if [[ "$arg" == --unalias=* ]]; then
            aliasName="${arg#--unalias=}"
        fi
    ;;
    --completion | --completion=*)
        COMPLETION=true
        if [[ "$arg" == --completion=* ]]; then
            aliasName="${arg#--completion=}"
        fi
    ;;
    --link)
        ADDLINK=true
    ;;
    --unlink)
        UNLINK=true
    ;;
    -*)
        # ignore other options
    ;;
    *)
        if $ADDLINK; then
            installPath="$arg"
        else
            aliasName="$arg"
        fi
    ;;
    esac
done

if $COMPLETION; then
    _g_bashrc_ "${aliasName}" "${g_path/$HOME/\$HOME}${CONFIG+ --config=}${CONFIG:-}"
    exit 0
fi

if $ADDALIAS; then
    g_bashrc_install "${aliasName}" "$HOME/.bashrc" \
      "${g_path/$HOME/\$HOME}${CONFIG+ --config=}${CONFIG:-}"

    $CONFIRM \
      && p_echo "To use the installed feature - start a new bash" \
      || p_echo "DRY-RUN --confirm to apply"
    exit 0
fi

if $UNALIAS; then
    $CONFIRM \
      && u_deleteLines "$HOME/.bashrc" "##:${aliasName}:##" \
      || p_echo "DRY-RUN --confirm to apply"
    exit 0
fi

if $UNLINK; then
    theInstalledLink="$(command -v "$g_file" || true)"
    if [[ -z "$theInstalledLink" || "$theInstalledLink" == "$g_file" ]]; then
        echo "$g_file appears not to be installed"
        exit 1
    fi

    if [[ ! -L "$theInstalledLink" ]]; then
        echo "Not a link: $theInstalledLink - leaving well alone"
        exit 1
    fi

    theInstalled="$(readlink -n "$theInstalledLink" || true)"
    if [ "$theInstalled" != "$c_file" ]; then
        echo "This link does not point to me: $theInstalledLink - leaving well alone"
        exit 1
    fi

    $LOUD && echo "rm $theInstalledLink"
    $DRYRUN && echo "dryrun:  --confirm required to proceed"
    $CONFIRM && rm "$theInstalledLink" && echo "Removed installed symbolic link $theInstalledLink" || echo "failed"

    exit 0
fi

if $ADDLINK; then
    if [[ "$installPath" = "" ]]; then
        echo "No destination specified, try (/usr/local/bin)"
        exit 1
    fi

    searchablePath=":$PATH:"
    if [[ "$searchablePath" != *":$installPath:"* ]]; then
        echo "Your PATH does not include $installPath, please specify a valid path."
        exit 1
    fi

    if [[ ! -d "$installPath" ]]; then
        echo "Directory $installPath does not exist"
        exit 1
    fi

    $LOUD && echo "ln -s ${g_file} $installPath/${g_file}"
    $DRYRUN && echo "dryrun: --confirm required to proceed"
    $CONFIRM && ln -s "${g_file}" "$installPath/${g_file}" 
    $CONFIRM && echo "Installed symbolic link from $installPath/${g_file} to ${g_file}"
    exit 0
fi

echo "No action specified (--alias, --unalias, --completion, --link, --unlink)"
exit 1

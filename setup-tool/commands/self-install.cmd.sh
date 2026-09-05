# groan.self-install.sh
#
# by Keith Hodges 2010
#

me "$BASH_SOURCE" #tradition

command="self-install"
s_description="install alias, autocompletion, or symlink in system

Configures system-wide or user-level integrations for ${g_cmd:-tool}.

Provides options to:
  • Create or remove shell aliases/functions in ~/.bash_profile
  • Generate Bash tab-completion definitions for interactive shells
  • Symlink the binary into system PATH (e.g., /usr/local/bin) or remove it

Destructive/write operations default to dry-run mode; pass --confirm (-Y) to execute."

s_opts=\
"
--alias[=<name>]     install shell alias/helper function in ~/.bash_profile ; (default name: ${g_cmd:-tool})
--unalias[=<name>]   remove installed shell alias/helper from ~/.bash_profile ; (or --uninstall)
--completion[=<name>] generate autocompletion snippet (or install with --confirm) ;
--link [path]        create symbolic link in system PATH ; (default: /usr/local/bin)
--unlink             remove installed symbolic link from system PATH ;
"

s_usage=\
"$breadcrumbs --alias [name] --confirm          ; install alias into ~/.bash_profile
$breadcrumbs --unalias [name] --confirm        ; remove alias from ~/.bash_profile
$breadcrumbs --completion [name]               ; print completion snippet (for eval)
$breadcrumbs --completion [name] --confirm     ; install completion into ~/.bash_profile
$breadcrumbs [/usr/local/bin] --link --confirm ; create symlink in target PATH directory
$breadcrumbs --unlink --confirm                ; remove installed symlink from PATH"

$METADATAONLY && return

$GDEBUG && echo "Command: '$command'"

function _g_bashrc_alias_ ()
{
  local name="$1" alias_text="$2"
  echo "alias $name='${alias_text}' ##:$name:##"
}

function g_bashrc_install_alias ()
{
  local name="$1" dest="$2" alias_text="$3"
  _g_bashrc_alias_ "$name" "$alias_text" | u_updateConfigFile "$dest" "##:${name}:##"
}

function g_bashrc_install_completion ()
{
  local name="$1" dest="$2" alias_text="$3"
  _g_bashrc_completion_ "$name" "$alias_text" | u_updateConfigFile "$dest" "##:_ac_${name}:##"
}

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
    --link | --link=*)
        ADDLINK=true
        if [[ "$arg" == --link=* ]]; then
            installPath="${arg#--link=}"
        fi
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
        elif [[ -d "$arg" ]]; then
            installPath="$arg"
        else
            aliasName="$arg"
        fi
    ;;
    esac
done

if $COMPLETION; then
    if $CONFIRM; then
        _g_bashrc_completion_ "${aliasName}" "${g_path/$HOME/\$HOME}${CONFIG+ --config=}${CONFIG:-}"
        g_bashrc_install_completion "${aliasName}" "$HOME/.bash_profile" \
          "${g_path/$HOME/\$HOME}${CONFIG+ --config=}${CONFIG:-}"
        p_echo "To use the completion feature - start a new bash"
    else
        _g_bashrc_completion_ "${aliasName}" "${g_path/$HOME/\$HOME}${CONFIG+ --config=}${CONFIG:-}"
        p_echo "# DRY-RUN --confirm to apply (to ~/.bash_profile)"
    fi
    exit 0
fi

if $ADDALIAS; then
    g_bashrc_install_alias "${aliasName}" "$HOME/.bash_profile" \
      "${g_path/$HOME/\$HOME}${CONFIG+ --config=}${CONFIG:-}"

    $CONFIRM \
      && p_echo "To use the installed feature - start a new bash" \
      || p_echo "DRY-RUN --confirm to apply (to ~/.bash_profile)"
    exit 0
fi

if $UNALIAS; then
    $CONFIRM \
      && u_deleteLines "$HOME/.bash_profile" "##:${aliasName}:##" \
      || p_echo "DRY-RUN --confirm to apply (to ~/.bash_profile)"
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
    theInstalledTarget="$theInstalled"
    if [[ "$theInstalled" != /* ]]; then
        theInstalledTarget="$(cd -- "$(dirname -- "$theInstalledLink")" 2>/dev/null && cd -- "$(dirname -- "$theInstalled")" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$theInstalled")")"
    fi
    if [[ "$theInstalled" != "$g_path" && "$theInstalled" != "$c_file" && "$theInstalledTarget" != "$g_path" ]]; then
        echo "This link does not point to me: $theInstalledLink - leaving well alone"
        exit 1
    fi

    $LOUD && echo "rm $theInstalledLink"
    $DRYRUN && echo "dryrun:  --confirm required to proceed"
    if $CONFIRM; then
        if rm "$theInstalledLink"; then
            echo "Removed installed symbolic link $theInstalledLink"
        else
            echo "failed"
        fi
    fi

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

    $LOUD && echo "ln -s ${g_path} $installPath/${g_file}"
    $DRYRUN && echo "dryrun: --confirm required to proceed"
    if $CONFIRM; then
        if ln -s "${g_path}" "$installPath/${g_file}"; then
            echo "Installed symbolic link from $installPath/${g_file} to ${g_path}"
        else
            echo "failed"
        fi
    fi
    exit 0
fi

g_displayHelp
exit 0

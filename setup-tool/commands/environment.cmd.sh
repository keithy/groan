# groan.setup.environment.sh
#
# by Keith Hodges 2010

me "$BASH_SOURCE" #tradition

command="environment"
s_description="show script/environment variables

Displays shell environment variables, framework paths, or evaluates custom expressions within the script context."

s_opts=\
"
--env [filter]      display exported environment variables (optional filter) ;
--all [filter] | -a display all shell variables (via set) ;
--which             print path to the main executable ;
--temp              print temporary workspace directory ;
--origin            print git repository remote origin URL ;
--eval <expr> | -e  evaluate expression in script execution context ;
"

s_usage=\
"$breadcrumbs [filter]               ; filter exported environment variables
$breadcrumbs --env [filter]         ; filter exported environment variables
$breadcrumbs --all [filter]         ; filter all shell variables
$breadcrumbs --which                  ; print path to main executable
$breadcrumbs --temp                   ; print temporary directory
$breadcrumbs --origin                 ; print git remote origin URL
$breadcrumbs --eval \"echo \$g_dir\"  ; evaluate expression in script context"

$METADATAONLY && return

[[ $# -eq 0 ]] && g_displayHelp && exit 0

$GDEBUG && echo "Command: '$command'"

action=""
eval_expr=""
filter=""

for arg in "$@"  
do
    $GDEBUG && echo "Arg: $arg"
    if [[ "$eval_expr" == "pending" ]]; then
        eval_expr="$arg"
        continue
    fi
    case $arg in
    --env)
        action="env"
    ;;
    --all | -a)
        action="set"
    ;;
    --which)
        echo "$g_path"
        exit 0
    ;;
    --temp)
        echo "$g_tmp"
        exit 0
    ;;
    --origin)
        printf "$g_home "
        git --git-dir="$g_dir/.git" --work-tree="$g_dir" remote get-url origin 2>/dev/null || echo "no origin"
        exit 0
    ;;
    --eval=* | -e=*)
        eval_expr="${arg#*=}"
    ;;
    --eval | -e)
        eval_expr="pending"
    ;;
    -*)
        :
    ;;
    *)
        filter="$arg"
    ;;
    esac
done

if [[ -n "$eval_expr" && "$eval_expr" != "pending" ]]; then
    eval "$eval_expr"
    printf '\e[0m\n'
    exit 0
fi

[[ -z "$action" ]] && action="env"

if [[ "$action" == "set" ]]; then
    if [[ -n "$filter" ]]; then
        set | grep -i -- "$filter" | sed $'s/\e/\\\\e/g' | sed "s/^\([A-Za-z_][A-Za-z0-9_]*\)=/${bold}\1${reset}=/" || true
    else
        set | sed $'s/\e/\\\\e/g' | sed "s/^\([A-Za-z_][A-Za-z0-9_]*\)=/${bold}\1${reset}=/"
    fi
elif [[ "$action" == "env" ]]; then
    if [[ -n "$filter" ]]; then
        grep -E '^[A-Za-z_][A-Za-z0-9_]*=' < <(env) | grep -i -- "$filter" | sort | sed $'s/\e/\\\\e/g' | sed "s/^\([A-Za-z_][A-Za-z0-9_]*\)=/${bold}\1${reset}=/" || true
    else
        grep -E '^[A-Za-z_][A-Za-z0-9_]*=' < <(env) | sort | sed $'s/\e/\\\\e/g' | sed "s/^\([A-Za-z_][A-Za-z0-9_]*\)=/${bold}\1${reset}=/" || true
    fi
else
    g_displayHelp
    exit 0
fi
printf '\e[0m\n'
exit 0

#"This Code is distributed subject to the MIT License, as in
# http://www.opensource.org/licenses/mit-license.php .
# Additional sub-commands created by users may be licensed
# under their own terms."

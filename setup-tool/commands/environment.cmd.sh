# groan.setup.environment.sh
#
# by Keith Hodges 2010

me "$BASH_SOURCE" #tradition

command="environment"
s_description="show script/environment variables"
s_usage="usage:
$breadcrumbs environment 
$breadcrumbs environment [--all|-a]
$breadcrumbs environment [--which]
$breadcrumbs environment [--temp]
$breadcrumbs environment [--origin]
$breadcrumbs environment [--eval \"expr\"] - evaluate expression in script context
$breadcrumbs environment --help"

$METADATAONLY && return

$GDEBUG && echo "Command: '$command'"

action="env"
eval_expr=""

for arg in "$@"  
do
    $GDEBUG && echo "Arg: $arg"
    if [[ "$eval_expr" == "pending" ]]; then
        eval_expr="$arg"
        continue
    fi
    case $arg in
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
    --eval | -e)
        eval_expr="pending"
    ;;
    esac
done

if [[ -n "$eval_expr" && "$eval_expr" != "pending" ]]; then
    eval "$eval_expr"
    printf "${reset:-}"
    exit 0
fi

if [[ "$action" == "set" ]]; then
    set
else
    env -0 | grep -zv '^[A-Za-z_][A-Za-z0-9_]*\(\)' | tr '\0' '\n' | sort
fi
printf "${reset:-}"
exit 0

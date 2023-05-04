# groan test.sub.sh & groan environment.sub.sh
# by Keith Hodges 2010
#
# The test command runs suites of tests according to a specified "kind"
# The suites are defined by folders containing the runner */$kind/_run.sh
#
# This allows this same code to run test-suites for different purposes.
# For example: 
# 	- Tool tests - kind=tests      (UnitTests/TDD)
# 	- Tool specs - kind=specs      (Behaviour Specs/BDD)
# 	- Monitoring - kind=monitoring (assess the state of running/deployed services)
# 	- Platform   - kind=platform   (is the platform configured and working correctly)
#	
# The command can be installed in any tool.
# The command name provides the default setting for "kind",
# thus when named monitoring.sub.sh it will run --kind=monitoring suites.
#
# A sub-command configuration file can override the defaults
# so the sub-command can be named or configured to run any set of tests,
# obtaining tests from any directory. 
#
# An example: ./es-tool/setup-tool/commands/test-all-tools.conf
#

me "$BASH_SOURCE" #tradition

command="$s_sub_cmd"

kind=${kind:-$command}
test_search_root="${test_search_root:-${my_dir}/..}"

description="run self-test kind=$kind"

usage="
$breadcrumbs --test=<suite>   run single suite
$breadcrumbs --initialize     initializes test suites (doesnt run)
$breadcrumbs --env            echo the environment
$breadcrumbs --ping <this>    echo <this>
"

# Our default metadata contribution to help
options="
--initialize | -i   initialize fixtures
--list       | -l   list suites
--kind=<type>       select specialised set of suites
--suite=<sA>,<sB>   specify list of suites
--ping <this>       echo <this>
--env               print environment
--theme=light       alternate colour theme
"

function get_suites() #1) $kind
{
  cd "${test_search_root}"
  mapfile -d $'\0' suites < <(find . -path "*/${1}/_run.sh" -print0)
}

function get_kinds()
{
  cd "${test_search_root}"

  case "${g_PLATFORM}" in
    *-apple-darwin*)
        find . -path "*/_run.sh"  | sed -e 's#.*/\(.*\)/_run.sh#\1#' | sort | uniq
    ;;
    *)
        find . -path "*/_run.sh" -printf '%h\n' | sed -e 's#.*/##' | sort | uniq
    ;;
  esac

}

if $METADATAONLY; then
  for a_kind in $(get_kinds); do
    get_suites "$a_kind"
    usage_+="${NL}${bold}suites:${reset} ${dim}(kind=$a_kind)${reset}${NL}"
    usage_+="$(printf "%s\n" "${suites[@]/%\/_run.sh}")${NL}"
  done
  usage_+="${NL}"
  return
fi

INITIALIZE=false
ECHO_TEST=false
ECHO_ENV=false
ECHO_EVAL=false
RUN_TEST=true
LIST_SUITES=false
RESULTS=${RESULTS:-true}
choice=""
for arg in "$@"
do
    case "$arg" in
      --initialize |--i*|-i)
        INITIALIZE=true
        RUNNER=false
        # doesnt run the tests
      ;;
      --ping | -p | --echo | -e)
        ECHO_TEST=true
        RUN_TEST=false
      ;;
      --env)
        ECHO_ENV=true
        RUN_TEST=false
      ;;
      --eval | -e)
        ECHO_EVAL=true
        RUN_TEST=false
      ;;
      --kind=*)
        kind="${arg#--kind=}"
      ;;
      --suite=*)
        RUN_TEST=true
        choice="${arg#--suite=}"
      ;;
      --list|-l)
        LIST_SUITES=true
        RUN_TEST=false
      ;;
      --all)
        RUN_TEST=true
        choice=""
      ;;
      -*)
      :
      ;;
      *)
        what="$arg"
      ;;
    esac
done     

if $ECHO_TEST; then
  echo $what
fi

if $ECHO_ENV; then
  env
  printf "${reset}"
fi

if $ECHO_EVAL; then
  $VERBOSE && echo $what
  eval "$what"
fi

if $LIST_SUITES; then
  for a_kind in $(get_kinds); do
    get_suites "$a_kind"
    printf "${underline}kind=${bold}$a_kind${reset}${underline} suites:${reset}\n"
    printf "%s\n" "${suites[@]/%\/_run.sh}"
    printf "\n"
  done
fi 

if $RUN_TEST; then
  $LOUD && echo "Action: ${bold}${command^}${reset}"
  $DEBUG && echo "Kind: ${kind} Choice: $choice"

  get_suites "${kind}"

  t_fails=0
  t_tests=0
  for suite in "${suites[@]}"
  do
    echo "Suite: ${suite%/_run.sh}"

    [[ "$suite" == "$choice"* ]] \
      && cd "${test_search_root}" \
      && RESULTS=false LOUD=$VERBOSE VERBOSE=$DEBUG DEBUG=$XDEBUG source "${suite}"
  done

  if $RESULTS; then
    if [[ $t_fails == 0 ]]; then
      echo "Ran: ${t_tests} ${bold}Pass: ${t_tests}${reset}"
    else
      echo "Ran: ${t_tests} Fails: ${t_fails}"
    fi
  fi
fi

exit 0

#"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 


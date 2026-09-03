# groan.specs.run.sh
#
# ./groan specs run <tool>     run the spec suite at <tool>/specs or <tool>/tests
# ./groan specs run --all      run every suite under groan/*/specs|groan/*/tests
# ./groan specs run --list     list runnable suites without executing them

me "$BASH_SOURCE" #tradition

command="run"
s_description="run a tool's spec/test suite"
s_usage=\
"$breadcrumbs                          # list tools with suites
$breadcrumbs run <tool>                # run that tool's suite
$breadcrumbs run --all                 # run every suite
$breadcrumbs run --list                # list runnable suites"

$METADATAONLY && return

# A sourced sub-command script (cmd.sh) inherits the calling function's
# positional parameters via $@ because bash's `source` does not reset
# them. So flag arguments like --all and --list are available here even
# though the framework declared --all/--list as g_option* (those fire
# only inside g_actions for the fallback path).

# Whitelist of file patterns we recognise as a runnable suite.
match_spec() {
  local p="$1"
  case "$p" in
    *.sub.*.cmd.*) return 1 ;;  # dispatcher alias
    */lib/*)        return 1 ;;  # helper library
    *.spec.sh)      return 0 ;;
    *.test.sh)      return 0 ;;
    *)              return 1 ;;
  esac
}

# Parent of specs-tool/, i.e. the tool tree where user-added tools live.
groan_root="${my_path%/*/*/*}"

case "${1:-}" in
  --list)
    while IFS= read -r suite; do
      match_spec "$suite" || continue
      printf "  %s\n" "$suite"
    done < <(find "$groan_root" -type f \( -name '*.spec.sh' -o -name '*.test.sh' \) 2>/dev/null | sort)
    ;;

  --all)
    failures=0
    while IFS= read -r suite; do
      match_spec "$suite" || continue
      echo "--- $suite ---"
      bash "$suite" || failures=$((failures+1))
    done < <(find "$groan_root" -type f \( -name '*.spec.sh' -o -name '*.test.sh' \) 2>/dev/null | sort)
    echo "Failures: $failures"
    exit $failures
    ;;

  "")
    echo "specs: missing tool name or flag"
    echo "Try: $breadcrumbs run --all"
    exit 1
    ;;

  *)
    tool="$1"
    suite_dir="$groan_root/$tool/specs"
    [[ -d "$suite_dir" ]] || suite_dir="$groan_root/$tool/tests"
    if [[ ! -d "$suite_dir" ]]; then
      echo "no specs/ or tests/ under $groan_root/$tool" >&2
      exit 2
    fi
    failed=0
    while IFS= read -r suite; do
      match_spec "$suite" || continue
      echo "--- $suite ---"
      bash "$suite" || failed=$((failed+1))
    done < <(find "$suite_dir" -type f \( -name '*.spec.sh' -o -name '*.test.sh' \) 2>/dev/null | sort)
    exit $failed
    ;;
esac

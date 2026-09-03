# groaned.specs.run.sh
#
# ./groan specs run <tool>     run the spec suite at <tool>/specs or <tool>/tests (full output)
# ./groan specs run --all      run every suite under groan/*/specs|groan/*/tests (summarised)
# ./groan specs run --list     list runnable suites without executing them
#
# `--all` summary mode:
#   * a one-line-per-suite index showing pass (√) / fail (X) and the suite name
#   * ERROR.* lines printed in red, WARN.* in yellow, INFO.* in cyan
#   * everything else is suppressed (bash-spec's PASS/FAIL chatter stays quiet)
#   * exit code is the count of failed suites, suitable for CI gating

me "$BASH_SOURCE" #tradition

command="run"
s_description="run a tool's spec/test suite"
s_usage=\
"$breadcrumbs                          # list tools with suites
$breadcrumbs run <tool>                # run that tool's suite (full output)
$breadcrumbs run --all                 # run every suite (summarised, √/X)
$breadcrumbs run --list                # list runnable suites"

$METADATAONLY && return

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

# Find all suites in a directory matching the whitelist. Returns a list
# sorted by tool category, then by name, so the index reads predictably.
list_suites() {
  local dir="$1"
  find "$dir" -type f \( -name '*.spec.sh' -o -name '*.test.sh' \) 2>/dev/null \
    | sort
}

# Filter a stream of suite output down to severity-tagged lines, colour-
# coded. Suited to bash-spec output which intermixes PASS/FAIL/SUMMARY
# with whatever the suite authors choose to print. Three patterns:
#   ^ERROR.* | ERROR:<space>*  -> red   (^ERROR is bash-spec FAIL lines;
#                                      ERROR:<space> is a runtime tag)
#   ^WARN.*  | WARN:<space>*   -> yellow
#   ^INFO.*  | INFO:<space>*   -> cyan
# A line that does not match any pattern is dropped.
colour_filter() {
  awk '
    {
      line = $0
      marker = ""
      color  = ""
      if (line ~ /^[A-Z][A-Z]+[:[:space:]]/) {
        tag = line
        sub(/[:[:space:]].*$/, "", tag)
        if (tag == "ERROR") { color = "\033[31m"; marker = "✖ "; }
        else if (tag == "WARN")  { color = "\033[33m"; marker = "⚠ "; }
        else if (tag == "INFO")  { color = "\033[36m"; marker = "» "; }
      }
      if (color != "") printf "%s%s\033[0m\n", color marker, line
    }
  '
}

# Run a suite, printing a coloured-severity filtered transcript iff
# `mode=summarised`, full output otherwise. Sets SUITE_STATUS=pass|fail
# for the caller.
run_suite() {
  local suite="$1" mode="$2"
  if [[ "$mode" == summarised ]]; then
    out=$(bash "$suite" 2>&1)
    rc=$?
    printf "%s\n" "$out" | colour_filter
  else
    bash "$suite"
    rc=$?
  fi
  if [[ $rc -eq 0 ]]; then SUITE_STATUS=pass; else SUITE_STATUS=fail; fi
  return $rc
}

# Print the √ / X index line for `--all`. Args: status name rc.
# status: pass | fail
# name: suite basename without .spec.sh/.test.sh
# rc: exit code
print_index_line() {
  local status="$1" name="$2" rc="$3"
  if [[ "$status" == pass ]]; then
    printf "  \033[32m✔\033[0m  %-40s\n" "$name"
  else
    printf "  \033[31m✘\033[0m  %-40s (rc=%d)\n" "$name" "$rc"
  fi
}

case "${1:-}" in
  --list)
    list_suites "$groan_root"
    ;;

  --all)
    declare -a FAILED_SUITES=()
    index_count=0
    index_pass=0
    index_fail=0
    while IFS= read -r suite; do
      match_spec "$suite" || continue
      name=$(basename "$suite")
      name=${name%.spec.sh}
      name=${name%.test.sh}
      index_count=$((index_count + 1))
      echo "--- $suite ---"
      run_suite "$suite" summarised
      rc=$?
      if [[ $rc -ne 0 ]]; then
        FAILED_SUITES+=("$suite")
        print_index_line fail "$name" "$rc"
        index_fail=$((index_fail + 1))
      else
        print_index_line pass "$name" 0
        index_pass=$((index_pass + 1))
      fi
    done < <(list_suites "$groan_root")

    echo
    echo "═══════════════════════════════════════════"
    printf "  Ran %d suite" "$index_count"
    if [[ $index_count -ne 1 ]]; then printf "s"; fi
    printf ": \033[32m%d pass\033[0m, \033[31m%d fail\033[0m\n" "$index_pass" "$index_fail"
    echo "═══════════════════════════════════════════"

    if [[ ${#FAILED_SUITES[@]} -gt 0 ]]; then
      echo "Failed:"
      printf "  %s\n" "${FAILED_SUITES[@]}"
    fi
    exit "$index_fail"
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
    done < <(list_suites "$suite_dir")
    exit "$failed"
    ;;
esac


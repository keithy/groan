#!/usr/bin/env bash

# specs-tool self-test.
#
# Verifies the prereqs the runner needs and that the framework is
# wired up end-to-end: helper library import, --help reachable,
# --list discovers, --all runs without crashing.
#
# This is the suite specs-tool itself owns. Run via:
#   ./groan specs run specs-tool
#
# Note: --list and --all here are local flags handled by run.cmd.sh;
# they reach the sourced cmd.sh via $@ (bash's `source` doesn't
# reset positional parameters). They are NOT the framework's
# g_option--list / g_option--all (those fire only inside g_actions).

s_description="specs-tool prereqs and end-to-end wiring"
s_opts=" "
s_usage=""

${METADATAONLY:-false} && return

# Locate specs-tool's lib relative to this script. The script lives at
# specs-tool/specs/prereqs.spec.sh; lib is ../lib/bash-spec-2.sh.
this="${BASH_SOURCE[0]}"
here="$(cd -- "${this%/*}" 2>/dev/null && pwd -P)"

# Source specs-tool's vendored helper. Unlike other suites, this one
# runs INSIDE specs-tool itself, so we can hardcode the lib path
# without ambiguity.
source "${here}/../lib/bash-spec-2.sh"
rerun_in_clean_bash
source "$bash_spec"

# specs-tool's path (the sub-suite directory).
specs_tool_dir="${here%/*}"
groan_root_repo="${specs_tool_dir%/*}"

# Find the production groan framework.
groan="${groan_root_repo}/groan"
[[ -x "$groan" ]] || { echo "production groan not found at $groan" >&2; exit 1; }

describe "specs-tool prereqs" && {

  it "bash is on PATH" && {
    command -v bash >/dev/null
  }

  it "grep -E is on PATH" && {
    command -v grep >/dev/null
  }

  it "realpath is on PATH" && {
    command -v realpath >/dev/null
  }

  it "specs-tool/lib/bash-spec-2.sh is sourceable" && {
    [[ -f "${here}/../lib/bash-spec-2.sh" ]]
  }

  it "the bash-spec runner is reachable from specs-tool's lib" && {
    [[ -f "$bash_spec" ]]
  }

  it "starting non-interactive bash sourcing .bashrc/.bash_profile produces no output" && {
    tmp_home="$(mktemp -d /tmp/groan-spec-home-XXXXXX)"
    tmp_rc="${tmp_home}/.bashrc"
    tmp_prof="${tmp_home}/.bash_profile"

    HOME="$tmp_home" "$groan" setup self-install --alias mygroan --confirm >/dev/null 2>&1
    HOME="$tmp_home" "$groan" setup self-install --completion mygroan --confirm >/dev/null 2>&1

    out_rc="$(HOME="$tmp_home" bash --rcfile "$tmp_rc" -c "echo STDIN_CHECK" 2>&1)"
    out_prof="$(HOME="$tmp_home" bash --rcfile "$tmp_prof" -c "echo STDIN_CHECK" 2>&1)"

    rm -rf "$tmp_home"

    expect "$out_rc" to_be "STDIN_CHECK"
    expect "$out_prof" to_be "STDIN_CHECK"
  }
}

describe "specs-tool end-to-end" && {

  it "./groan specs prints usage under the dispatcher's crumb" && {
    capture out <( cd "$groan_root_repo" && "$groan" --theme=off specs 2>&1 )
    expect_array out to_contain 'commands:'
    expect_array out to_contain 'groan specs                    spec/test runner for installed tools (this list)'
    expect_array out to_contain 'groan specs list               list tools with spec/test suites'
    expect_array out to_contain "groan specs run                run a tool's spec/test suite"
  }

  it "./groan specs --help prints the help block" && {
    capture out <( cd "$groan_root_repo" && "$groan" --theme=off specs --help 2>&1 )
    expect_array out to_contain 'spec/test runner for installed tools'
    expect_array out to_contain 'options: '
    expect_array out to_contain '--all | --list-all    list all sub-commands'
  }

  it "./groan specs list discovers specs-tool's own suite" && {
    capture out <( cd "$groan_root_repo" && "$groan" --theme=off specs list 2>&1 )
    expect_array out to_contain '  specs-tool           specs/ (1 file)'
  }

  # NOTE: we deliberately do NOT test `./groan specs run specs-tool`
  # from inside specs-tool's own suite. That would recurse: the runner
  # would source prereqs.spec.sh, which would invoke the runner
  # again, ad infinitum. To exercise the runner end-to-end, run this
  # suite from outside: `./groan specs run specs-tool`.
  #
  # We do test the runner's CLI wiring (`list`, `run`, `--help`) so the
  # dispatcher path is exercised. `run --all` is verified manually.
}

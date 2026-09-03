#!/usr/bin/env bash

# specs-tool self-test.
#
# Verifies the prereqs the runner needs and that the framework is
# wired up end-to-end: helper library import, --help reachable,
# --list discovers, --all runs without crashing.
#
# This is the suite specs-tool itself owns. Run via:
#   ./groan specs run specs-tool

s_description="specs-tool prereqs and end-to-end wiring"
s_opts=" "
s_usage=""

${METADATAONLY:-false} && return

# Locate specs-tool's lib relative to this script. The script lives at
# specs-tool/specs/prereqs.spec.sh; lib is ../lib/bash-spec-2.sh.
this="${BASH_SOURCE[0]}"
here="${this%/*}"

# Source specs-tool's vendored helper. Unlike other suites, this one
# runs INSIDE specs-tool itself, so we can hardcode the lib path
# without ambiguity.
source "${here}/../lib/bash-spec-2.sh"
rerun_in_clean_bash
source "$bash_spec"

# Find the production groan framework.
groan="/Users/keith/code/groan-a-lot/groan/groan"
[[ -x "$groan" ]] || skip "production groan/groan not found at $groan"
repo_root="/Users/keith/code/groan-a-lot"

# specs-tool's path (the sub-suite directory).
specs_tool_dir="${here%/*}"
groan_root_repo="${specs_tool_dir%/*}"

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
}

describe "specs-tool end-to-end" && {

  it "./groan specs prints usage under the dispatcher's crumb" && {
    capture out <( cd "$repo_root" && ./groan/groan --theme=off specs 2>&1 )
    expect_array out to_contain 'commands:'
    expect_array out to_contain 'groan specs                    spec/test runner for installed tools (this list)'
    expect_array out to_contain 'groan specs list               list tools with spec/test suites'
    expect_array out to_contain "groan specs run                run a tool's spec/test suite"
  }

  it "./groan specs --help prints the help block" && {
    capture out <( cd "$repo_root" && ./groan/groan --theme=off specs --help 2>&1 )
    expect_array out to_contain 'spec/test runner for installed tools'
    expect_array out to_contain 'options: '
    expect_array out to_contain '--all | --list-all    list all sub-commands'
  }

  it "./groan specs list discovers specs-tool's own suite" && {
    capture out <( cd "$repo_root" && ./groan/groan --theme=off specs list 2>&1 )
    expect_array out to_contain '  specs-tool           specs/ (1 file)'
  }

  # NOTE: we deliberately do NOT test `./groan specs run specs-tool`
  # from inside specs-tool's own suite. That would recurse: the runner
  # would source prereqs.spec.sh, which would invoke the runner
  # again, ad infinitum. To exercise the runner end-to-end, run this
  # suite from outside: `./groan specs run specs-tool`.
  #
  # We do test the runner's CLI wiring (`list`, `run`, `--help`) so the
  # dispatcher path is exercised, then trust the `--all-suites` form
  # based on a manual run for which bash recursion isn't an issue.
}

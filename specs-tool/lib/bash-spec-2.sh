# specs-tool/lib/bash-spec-2.sh
#
# Vendored bootstrap helper for tests under specs-tool/specs and for
# any tool-specific spec suite under <tool>/specs that wants to use
# bash-spec.
#
# Source this at the top of a `*.spec.sh` test:
#
#   this="${BASH_SOURCE[0]}"
#   here="${this%/*}"
#   source "${here}/../../lib/bash-spec-2.sh"
#
# Provides:
#   bash_spec    path to the bash-spec runner (resolves relative to
#                this file so the suite can run anywhere).
#   rerun_in_clean_bash()
#                Re-exec the current script under a minimal env so
#                spec results aren't polluted by the caller's shell.
#
# This is a THIN wrapper around groan-specs/bash-spec/bash-spec.sh.
# We don't want to maintain a fork of bash-spec here; if specs-tool
# is moved or vendored, update the path below to point at wherever
# the runner lives.
#
# Resolution strategy (first hit wins):
#   1. $BASH_SPEC_PATH env var (if set, honour it)
#   2. ../groan-specs/bash-spec/bash-spec.sh relative to this file
#      (this is the canonical location in the groan-a-lot monorepo)
bash_spec="${BASH_SPEC_PATH:-}"
if [[ -z "$bash_spec" || ! -f "$bash_spec" ]]; then
  bash_spec="${BASH_SOURCE[0]%/*}/../../../groan-specs/bash-spec/bash-spec.sh"
fi
[[ -f "$bash_spec" ]] || {
  echo "specs-tool/lib/bash-spec-2.sh: cannot find bash-spec runner" >&2
  echo "  expected: $bash_spec" >&2
  echo "  either install groan-specs alongside specs-tool or set BASH_SPEC_PATH" >&2
  return 1 2>/dev/null || exit 1
}
export bash_spec

function rerun_in_clean_bash () {
  [[ -n "${_CLEAN_:-}" ]] && return 0

  local script="${this:-${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}}"
  exec env -i _CLEAN_=1 \
    PWD="$PWD" \
    PATH="$PATH:/usr/bin:/bin:/usr/local/bin" \
    HOME="$HOME" \
    LOUD="${LOUD:-true}" \
    VERBOSE="${VERBOSE:-false}" \
    INIT="${INIT:-false}" \
    FAILME="${FAILME:-false}" \
    bash "$script" "$@"
}

# specs-tool/lib/bash-spec-clean-env.sh
#
# Clean-env bootstrap for bash-spec test suites.
#
# Normal use: source bash-spec.sh directly.
# Clean-env use (this file): source THIS instead of bash-spec.sh when the
# caller's environment is polluted (AWS credentials, mise shims, stray
# variables) and you need the suite to run under a minimal env.
#
#   source "${here}/../lib/bash-spec-clean-env.sh"
#
# This file:
#   1. On first entry, re-execs the calling script under `env -i` with
#      only the variables bash-spec needs (PATH, HOME, LOUD, VERBOSE,
#      etc.) so the suite starts from a known-clean shell.
#   2. Once re-execed (guarded by ${_CLEAN_:-}), sources the actual
#      bash-spec.sh runner located alongside this file.
#
# Resolution for the runner (first hit wins):
#   1. $BASH_SPEC_PATH env var (if set, honour it)
#   2. Sibling bash-spec.sh (this file's directory) — the canonical
#      layout when groan runs standalone.
bash_spec="${BASH_SPEC_PATH:-}"
if [[ -z "$bash_spec" || ! -f "$bash_spec" ]]; then
  bash_spec="${BASH_SOURCE[0]%/*}/bash-spec.sh"
fi
[[ -f "$bash_spec" ]] || {
  echo "specs-tool/lib/bash-spec-clean-env.sh: cannot find bash-spec runner" >&2
  echo "  expected: $bash_spec" >&2
  echo "  either place bash-spec.sh next to this file or set BASH_SPEC_PATH" >&2
  return 1 2>/dev/null || exit 1
}
export bash_spec

# On first entry, re-exec the calling script under a clean env. On
# re-entry (after the exec), fall through and source the runner.
# BASH_SPEC_PATH is forwarded explicitly so callers can override the
# runner location without depending on the sibling-fallback heuristic.
if [[ -z "${_CLEAN_:-}" ]]; then
  script="${this:-${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}}"
  exec env -i _CLEAN_=1 \
    PWD="$PWD" \
    PATH="$PATH:/usr/bin:/bin:/usr/local/bin" \
    HOME="$HOME" \
    LOUD="${LOUD:-true}" \
    VERBOSE="${VERBOSE:-false}" \
    INIT="${INIT:-false}" \
    FAILME="${FAILME:-false}" \
    BASH_SPEC_PATH="${bash_spec}" \
    bash "$script" "$@"
fi

source "$bash_spec"

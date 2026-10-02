---
name: groan-framework
description: Guide to customising the groan CLI framework. Load when adding sub-commands to a groan-based tool, creating a sub-suite, customising themes/config, or debugging dispatch gotchas like `--config` being consumed by the framework before sub-commands see it. The framework is a single ~1500-line bash dispatcher; everything you need to customise lives in your repo's commands/ dir plus a config file.
---

# Groan framework

A `groan`-based CLI is a single bash dispatcher (~1500 lines) plus a
`<prog>.conf` and a `commands/` directory of sub-command scripts. You
customise it by writing `commands/<name>.cmd.sh` files; the framework
handles argv parsing, help rendering, completion, and `angel --list all`
menu generation for you.

The dispatcher is intentionally tiny: read the first 200 lines of
[`groan`](https://gitlab.com/groaning/groan) to understand how it works.
A worked example lives in
[`groan-dev`](https://gitlab.com/groaning/groan-dev) — clone it for a
full sub-suite (`groan setup`, `groan specs`) to learn from.

A reference example of a customise in production: the
[`angelbox`](https://gitlab.com/serve-kindness/angelbox) project hardlinks
the same dispatcher as `angel`, `bf`, `nixos`, and several sub-tools. Its
[`docs/COMMANDS.md`](https://gitlab.com/serve-kindness/angelbox/-/blob/main/docs/COMMANDS.md)
shows what a finished `groan --list all` reference looks like.

Naming convention (declared in the dispatcher header):

| Prefix | Scope |
| --- | --- |
| `g_*` | global (groan-level) |
| `c_*` | command level |
| `s_*` | script / sub-command level |
| `u_*` | utility function |
| `p_*` | print function |
| `_*` | private function |

## Conventions

- `set -euo pipefail; IFS=$'\n\t'; shopt -s nullglob; set -o allexport` is
  the dispatcher mode. Sub-commands inherit it; assume strict mode and use
  `${var+x}` (not `[[ -n $var ]]`) when `set -u` could trip you.
- Every sub-command script starts with `me "$BASH_SOURCE" #tradition` —
  sets `my_path`, `s_path`, `c_dir`, `g_dir`. Skipping it breaks help
  rendering and the breadcrumb var (`$breadcrumbs`).
- The metadata trio (`g_declare_options FLAGS`, `s_description=...`,
  `s_usage=...`, optional `s_opts=...`, `s_description_=...`) is what
  `<prog> --list all` reads. Run with `METADATAONLY=true` to declare them
  without executing the body. `s_description` can be multi-line —
  the first line is rendered for `--list` / `--list all`, the rest
  appears in `--help`. Semicolons (`;`) delimit description columns in
  rendered help.
- Help is rendered in three blocks: description, options, usage. Each
  has a main and a `_*` supplementary (e.g. `s_usage` and `s_usage_`).
- Use `g_readConfig "$c_dir/commands/<name>.conf"` if your sub-suite
  needs a per-tool config file.
- **`+XD` / `+bash-debug`** — `set -x` bash trace around the sub-command
  body. Use this when a single sub-command is misbehaving and you want
  every command echoed to stderr. Pair with `set +x` inside your
  sub-command to mute sections you don't care about:

  ```bash
  while [[ $# -gt 0 ]]; do
      local arg="$1"
      shift
      case "$arg" in
          ...
      esac
  done
  set +x   # messy - turn off +X for the rest of this body
  ...
  ```

  The dispatcher auto-runs `set -x` / `set +x` around the sub-command
  when `+XD` is set. You can also put `set -x` inline yourself when
  debugging just one branch:

  ```bash
  ... do quiet setup ...
  set -x
  ... noisy thing I want to trace ...
  set +x
  ... quiet cleanup ...
  ```

  Combine `+XD +GD` to see both groan's dispatcher trace and the bash
  command trace.

## Building a sub-command

Minimal template:

```bash
#!/usr/bin/env bash

me "$BASH_SOURCE" #tradition

s_description="<one-line summary for --list>"

$METADATAONLY && return

# body: do work
```

Add usage / options blocks as needed:

```bash
s_opts=\
"
--foo          | -F  do foo
--bar=<value>  | -B= bar's value
"
s_usage=\
"
$breadcrumbs                 ; do the default thing
$breadcrumbs --foo           ; do foo
$breadcrumbs --bar=VALUE     ; do x with VALUE
"
```

`$breadcrumbs` expands to the command name and parent dispatch path so
help reads consistently. Declare custom flags once via `g_declare_options
FOO BAR` so `+GD` debug output covers them.

For flag parsing inside the body, use the `while [[ $# -gt 0 ]]` wile
pattern (see `nixos-tool/commands/unlock.cmd.sh`). The framework has
already consumed `--help`, `--quiet`, `--verbose`, `--dry-run`,
`--confirm`, `--config=`, and `--theme=`; everything else falls through
to your body.

```bash
while [[ $# -gt 0 ]]; do
    local arg="$1"
    shift
    case "$arg" in
        --foo) FOO=true ;;
        --bar=*) BAR="${arg#--bar=}" ;;
        --*) : ;;     # ignore unknown flags
        *)   : ;;     # ignore positional args
    esac
done
```

## Building a project-template sub-command

The `setup new` pattern: a sub-command that scaffolds new files/directories
from templates. Templates live in `g_config_preset_locations` (defaults to
`${c_dir}` — the sub-tool's own dir), one `*.tmpl/` subdir per template.

Reference impl: [`groan-dev/groan/setup-tool/commands/new.cmd.sh`](https://gitlab.com/groaning/groan-dev/-/blob/main/groan/setup-tool/commands/new.cmd.sh).

```bash
# In mycmd: $MYTOOL/setup-tool/templates/set-<name>.sub.<tool>.cmd.sh
me "$BASH_SOURCE" #tradition
s_description="scaffold from a project template"
s_opts="
--list             list available templates ;
--template=<name>  select template ;
--go-ahead         allow populating an existing directory ;
"
$METADATAONLY && return

[[ -z ${g_config_preset_locations+x} ]] && g_config_preset_locations=("${c_dir:-}")

extra="\nAvailable templates:\n"
for presetDir in "${g_config_preset_locations[@]}"; do
    for found in "$presetDir/"*.tmpl; do
        title=""
        [[ -f "$found/README.md" ]] && title="$(grep -m 1 -i "^#" "$found/README.md")"
        extra="${extra} $(printf "%-17s - $title" "${found##*/}")\n"
    done
done

# parse args with the wile pattern above
# ... targetPath, TEMPLATE, etc.

# then: rsync "$presetDir/$TEMPLATE.tmpl/"/* "$targetPath/" (with --confirm gating)
```

Templates:

- Live under one of the directories in `g_config_preset_locations`. By
  default that's `${c_dir}` (the sub-tool's dir), so a typical layout
  is `$MYTOOL/<sub>-tool/`*`.tmpl/`* (one dir per template).
- Each template directory must have its own `README.md` whose first
  `#`-prefixed heading is the description shown in `--list` output.
- `mycmd setup new --list` enumerates whatever templates exist in those
  locations. Drop a new `*.tmpl/` directory in to add a template.

Sub-tool handover convention (matches
[`groan-dev/groan/setup-tool`](https://gitlab.com/groaning/groan-dev/-/tree/main/groan/setup-tool)):

- The sub-tool's commands go in `<sub>-tool/commands/`.
- Templates go in `<sub>-tool/`*`.tmpl/`* (one dir per template).
- `<sub>-tool/<sub>-tool.conf` declares `g_subcmd_locations` and
  `g_config_preset_locations`.

## Sub-suite dispatchers

Two files:

1. **Top-level shim** in the parent tool's `commands/`:

   ```bash
   # commands/<suite>.sub.<suite-tool>.cmd.sh
   me "$BASH_SOURCE" #tradition
   s_description="<suite> sub-tool"
   $METADATAONLY && return
   g_parseSubCmdScriptPath "$s_path"
   g_readConfig "$s_dest_path"
   g_nextDispatch
   ```

   The `.sub.X.` segment tells the dispatcher to forward the rest of argv
   into the sub-tool's main command.

2. **Sub-tool binary** (e.g. `mytool/<suite>-tool`) — a hardlink to the
   same `groan` dispatcher. Its own `<suite>-tool.conf` declares
   `g_subcmd_locations=( "${c_dir}/commands" )` so it searches the
   sub-suite's commands dir, not the parent's.

   ```bash
   # mytool/<suite>-tool.conf
   c_description="<suite> sub-tool"
   g_subcmd_locations=(
       "${c_dir}/commands"
   )
   ```

When the user runs `mytool <suite> <cmd>`, the dispatcher recognises
`<suite>` as a sub-dispatch, sources the shim, and re-dispatches into
`<suite>-tool <cmd>`. The arg list passes through unchanged.

Hardlink all entry points to the same `groan` script so behaviour stays
in sync:

```bash
ln -f path/to/groan mytool/mytool
ln -f path/to/groan mytool/<suite>-tool
```

The convention is: every entry point is the same dispatcher; the only
difference is the config file and the subcmd path.

## Config layering

The dispatcher reads `<prog>.conf` from these locations, in order, with
later layers overriding earlier:

1. **Code-defined defaults** — hardcoded in the dispatcher.
2. **Tool-defined defaults** — `<prog>.conf` next to the dispatcher.
3. **User** — `$HOME/.<prog>rc` or `$HOME/.config/<prog>/<prog>.conf`.

`<prog>.conf` is shell, not YAML. Use it to override
`g_subcmd_locations`, `g_config_file_locations`, `g_config_options`,
`g_config_preset_locations`, `g_types`. See `groan-dev/groan/groan.conf`
for the default shape.

## Themes

`--theme=N` sets `THEME=N`. `THEME=0` disables colour; `THEME=1` (default)
is bold/dim with colour escapes. Define your own theme by sourcing a
themes.sh before `s_opts` in your conf.

## Gotchas

- **`--config=<cfg>` is consumed by the framework before sub-commands
  see it.** The dispatcher parses `--config=` in its own argv loop and
  assigns `CONFIG=<cfg>` to the dispatcher shell's variable space.
  When the sub-command is sourced, `g_pathScriptMappingArgs` only
  forwards the remaining positional `$@`, NOT the original argv.
  Result: a sub-command doing `for arg in "$@"; case "$arg" in
  --config=*) ...;;` will never see `--config=`. It is already gone.
  Workarounds:
  - Read the framework's `CONFIG` variable directly via
    `${CONFIG:-default}`. The dispatcher exports it.
  - Use a different flag name for your sub-command's config (e.g.
    `--cfg-profile`) so the framework doesn't claim it.
  - Tell users to set env vars (`MYTOOL_CONFIG=...`) instead of using
    the flag, when a custom config name is impractical.

- **`set -o allexport`** means plain assignments in sourced files leak
  into the parent shell. Style constants (`bold`, `dim`, `NL`) spread
  everywhere; tolerated because they're inert, but avoid redefining
  globals in sub-commands.

- **`g_parseSubCmdScriptPath`** is what makes sub-suite dispatch work.
  Without it, `<tool> sub-suite <args>` runs `sub-suite.cmd.sh` in the
  parent's command context, not the sub-tool's.

- **`$METADATAONLY && return`** — without it, sub-commands run their
  full body during `<prog> --list all`. Heavy startup (e.g. `mise
  install`, `pkl eval`) blows up the menu command.

- **`$breadcrumbs`** is a relative path that assumes subcommands are in
  `commands/`. If your subcmd layout differs, define `s_path` manually
  before the `me` call (rarely needed).

- **`+debug` and `+D`** — note the `+` prefix, not `--`. Users debug
  the user, `+GD` enables groan debug. The dispatcher distinguishes the
  two by looking for the `+` character.

- **`g_readConfig` and set -u**: sub-suite configs declare legacy vars
  (`g_config_preset_locations`, etc.) because some sub-commands use
  the `${var+x}` idiom under strict mode. See `setup-tool.conf` in
  `groan-dev`.

- **macOS lacks `flock`** — when implementing lock files, use `mkdir`
  (atomic on POSIX) instead.

## Reading order

When extending the framework or debugging a dispatcher issue, read in
this order:

1. [`groan`](https://gitlab.com/groaning/groan/-/blob/main) (the dispatcher) — particularly:
   - top of file: argv parsing for the shared flags,
   - `g_readConfig`, `g_executeScriptPath`, `g_pathScriptMappingArgs`,
   - `g_parseSubCmdScriptPath` for sub-dispatch,
   - the `--list all` and `<prog> --help` rendering code (search for
     `g_onEXIT__`, `_g_bashrc_completion_`).
2. [`groan-dev/groan/groan.conf`](https://gitlab.com/groaning/groan-dev/-/blob/main/groan/groan.conf) —
   default config shape.
3. One sub-command example:
   [`groan-dev/groan/commands/setup.sub.setup-tool.cmd.sh`](https://gitlab.com/groaning/groan-dev/-/blob/main/groan/commands/setup.sub.setup-tool.cmd.sh).
4. One full sub-suite: [`groan-dev/groan/setup-tool/`](https://gitlab.com/groaning/groan-dev/-/tree/main/groan/setup-tool) —
   see how `setup-tool.conf` redefines `g_subcmd_locations` and how
   `setup-tool/commands/*.cmd.sh` use the `g_declare_options` /
   `for arg in "$@"` pattern.
5. A finished reference instance: [`angelbox`](https://gitlab.com/serve-kindness/angelbox)
   and its [`docs/COMMANDS.md`](https://gitlab.com/serve-kindness/angelbox/-/blob/main/docs/COMMANDS.md)
   — shows a real `--list all` rendered as user-facing reference.

The framework is intentionally tiny. Most "mysteries" of how a
groan-derived tool behaves resolve by reading the first 200 lines of
the dispatcher.
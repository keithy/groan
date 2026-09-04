The groan framework is a basis for building complex hierarchical CLI interfaces with bash and other languages,
and aspires to achieve this with some degree of elegance, through hierarchical composition.

[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE.md)
[![Beta Status](https://gitlab.com/keithy/groan-dev/badges/beta/pipeline.svg)](https://gitlab.com/keithy/groan-dev/-/commits/beta)
[![GitHub issues](https://img.shields.io/github/issues/keithy/groan.svg)](https://github.com/keithy/groan/issues)

# Groan

/ɡrəʊn/

_noun_
	
1. the noise that emits from programmers forced to code in bash. 

`Groan` is a simple extensible bash framework (similar to [sub](https://github.com/basecamp/sub))
for creating a suite of scripts that have similar command, sub-command usage style to git/bzr/hg/docker etc.

Clone this repository, and rename 'groan' to be the top level name of YOUR command.
Add your scripts (in any language) and help topics, to the `commands` folder. 

Your command can be nested within other commands, or you can compose your command from others. 
Pick and choose modules from the `commands/`, `setup-utility/`, and
`tests/` folders that you wish to include in your command.

## Commands with sub-commands and sub-sub-commands...

Roll your own gitlike command suites, complete with help-documentation help-topics.
Support for standard options like --debug, --quiet is also included.

## Clever Stuff

Groan is recursively merge-able/compose-able. Assemble a named suite of sub-command scripts in a folder, 
that folder may be made available alongside, or nested as sub-commands within another suite.

Sub-commands in one folder can act as dispatchers into another folder's command suite, following the
`<name>.sub.<target>.cmd.<entry>.sh` naming convention.

## How to fork and roll your own command

Fork **keithy/groan** to **yourrepo/yourcommand** then create your working branch with the name of your
new command. To contibute your command back submit a pull-request.

## History

This incarnation of groan was conceived in about 2009, in 2017 I used 'sub' extensively 
and then fed that experience back into groan (in 2018), rather than port existing groan
based projects. 

## Groan vs sub

* Is recursively composeable and mergeable
* Is simpler than sub
* Sub-commands provide usage and documentation
* Support for additional documentation topics/reporting
* Demonstrates simple implementation conventions and patterns (e.g. options handling)
* Adopts the informal [bash "strict" mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/) which considerably aids debugging.
* Supports dynamic Bash autocompletion (via `--completion` or `--install`).

## Features

* supports default option flags (--verbose --quiet --help --debug --dry-run --confirm --groan-debug)
* default means for platform determination
* finds sub-commands via a configurable search path (allows local overides)
* finds config files via a configurable search path
* reads a config file (to set environment vars) before running sub-commands
* sub-commands may be written in any shell or language
* sub-commands may have metadata for help
* sub-commands can run as source, exec, or eval
* help included provides:
	* `--list` — list sub-commands of the current level
	* `--all` — recursively list every sub-command in every reachable
	  sub-command suite, with descriptions

## Debug options

The framework has four debug levels, each enabling a different kind
of trace output. They can be combined.

* `-D` / `--debug` — user-level debug. Sets `DEBUG=true` and
  `VERBOSE=true`. Most sub-commands check this to print extra
  detail.
* `-DD` / `--ddebug` / `--deep-debug` — developer deep debug.
  For sub-command code that distinguishes user vs developer traces.
* `-GD` / `--groan-debug` — groan's own trace. Sets `GDEBUG=true`
  and turns on verbose mode. Logs the dispatcher scanning
  (`Scanning for test*.cmd.* in: ...`), the result of each match
  (`Found #1 : ... : ...`), and the path taken when sourcing
  sub-commands. Useful when a sub-command isn't being found.
* `-CD` / `--config-debug` — config-file trace. Sets `CDEBUG=true`
  and turns on verbose mode. Logs the config-file search path
  (`Custom1? $PWD/groan.conf`, `Config  < $PWD/config/other.conf`,
  etc.) so you can see which `.conf` files are considered and which
  one is sourced. Combine with `-GD` to see both at once.
* `-XD` / `--bash-debug` — `set -x` trace. Prints every command
  as bash executes it. Very noisy; use only when you need the full
  command trace.

## General Principles

Groan (sub)commands are called after having:

* processed and filtered out the standard set of flags.
    * --verbose -V
    * --debug -D
    * --quiet 
    * --dry-run    # enabled by default
    * --confirm    # disables --dry-run flag for destructive operations
    * --ddebug -DD # developer debug
* found and 'sourced' a config-file.
* found and 'sourced' metadata (if separate).

All subcommands support
* --origin
* --update
* --install
* --completion

## Bash Autocompletion

Groan includes built-in dynamic tab completion for Bash.

### Enabling Autocompletion

To output the completion script for your shell configuration:

```bash
eval "$(groan --completion)"
```

Or append it to your `~/.bashrc` / `~/.bash_profile`:

```bash
groan --completion >> ~/.bashrc
```

Running `groan --install` automatically registers alias and autocompletion bindings in `~/.bashrc`.

### How it Works

When `<TAB>` is pressed, Bash delegates completion to `groan` via an internal `-- ---AUTOCOMPLETE` flag:
* Dynamically resolves nested sub-commands and dispatcher suites (e.g. `groan setup <TAB>`).
* Completes flag options (e.g. `--config=`, `--theme=`, `--debug`).
* Generates completions for available config names when typing `--config=<TAB>`.

Groan looks for config files in a number of places. The set of
locations is set in the `<exe>.conf` file (or by overriding
`g_config_file_locations` directly).

```
	"$g_home/$c_file.conf"                       # --local
	"$HOME/.config/<context_name>/default.conf"  # --user
```

## Sub-Commands

Sub-commands are files in `commands/` whose names encode how the
framework should invoke them. The extension after the last `.` selects
the dispatch mode:

* `<name>.cmd.sh`     — `source` the file in the current shell
* `<name>.cmd.conf`   — `source` the file as a metadata-only conf (no body run)
* `<name>.cmd.exec`   — `exec` the file as a new process
* `<name>.cmd.su`     — `sudo` then run the file
* `<name>.cmd.ps1`    — run the file under PowerShell
* `<name>.cmd.<ext>`  — any other extension is `eval`'d; the file is
                        resolved via `realpath` and must live under
                        `g_subcmd_locations[]` for safety

Non-shell scripts can supply their help metadata via `<name>.cmd.conf`
without the file being executable.

#### Dispatcher aliases

A sub-command in one folder can alias to a sub-command suite in
another folder. The naming convention is:

```
<X>.sub.<Y>.cmd.<Z>.<ext>
```

Where `<X>` is the alias name, `<Y>` is the destination command suite,
and `<Z>` is the entry sub-command to pass to that suite. The framework
recognises `*.sub.*.cmd.*` as a dispatcher pattern and follows the
alias when `--all` recurses.

For example, `commands/nested.sub.nested.cmd.sh` in the parent suite
makes `groan nested` invoke `./nested/nested` with no argument.

#### Help topics

Help topics are user-facing documentation files that you can place anywhere
on `g_locations[]`. They are text files with the extension `.topic.txt` or
`.topic.md`; the basename (without `.topic.<ext>`) is the topic name.

#### Help Meta Data

Commands are implemented expecting that they may be run with the METADATAONLY flag, in which case they populate variables and exit prior to doing anything:

* `$s_description`
* `$s_usage`

### Exit option - environment

* `-EXIT=env`

prints out the environment variables (or evaluates a given expression) in the context of where scripts ran

### Subcommand - configure

A number of template conf files can be provided, the user can choose a file and a place to install it. Out of the box, local, user and global config options are provided

    ./groan configure --options
    Available options:
    1) local config  : /Users/coding/wip/groan.conf
    2) user config   : /Users/bob/.groan.conf
    3) global config : /Users/bob/.local/bin/groan/groan.conf
       
    Available templates:
        default.conf (preset)
        
    Install configuration with:
    
    ./groan config default.conf --install --local --confirm 
        
### Subcommand - self-install

    groan setup /usr/local/bin --link --confirm

## Sub-command aliasing

A dispatcher script named `<X>.sub.<Y>.cmd.<Z>.<ext>` aliases sub-command `<X>` to
the `<Y>` command suite, passing `<Z>` as the entry sub-command. Place such a
script in the parent's `commands/` folder; the framework recognises the
`*.sub.*.cmd.*` pattern and follows the dispatcher when recursing.

## Test Suite

The comprehensive test suite is here http://github.com/keithy/groan-a-lot using the `bash-spec` framework.

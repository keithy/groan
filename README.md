The groan framework is a basis for building complex hierarchical CLI interfaces with bash and other languages,
and aspires to achieve this with some degree of elegance, through hierarchical composition.

[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE.md)
[![Build Status](https://travis-ci.com/keithy/groan-dev.svg?branch=master)](https://travis-ci.com/keithy/groan-dev)
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
The help facilities are provided by the enclosed command `helper`, and the remote upload and execution capability
is provided by the command `sensible`. Pick and choose modules that you wish to include.

## Commands with sub-commands and sub-sub-commands...

Roll your own gitlike command suites, complete with help-documentation help-topics.
Support for standard options like --debug, --quiet is also included.

## Clever Stuff

Groan is recursively merge-able/compose-able. Assemble a named suite of sub-command scripts in a folder, 
that folder may be made available alongside, or nested as sub-commands within another suite.

Groan uses/demonstrates this internally to implement the help sub-command. 
The `groan help` sub-command of `groan` is implemented by the nested folder of commands `helper/commands`.
The mapping is implemented by the command: `help.sub.helper.cmd._dispatch.sh`

## How to fork and roll your own command

Fork **keithy/groan** to **yourrepo/yourcommand** then create your working branch with the name of your
new command. To contibute your command back submit a pull-request.

## History

This incarnation of groan was conceived in about 2009, in 2017 I used 'sub' extensively 
and then fed that experience back into groan (in 2018), rather than port existing groan
based projects. I also want to use groan as a base for incorporating "fish" based scripts
if I should ever develop any.

## Groan vs sub

* Is recursively composeable and mergeable
* Is simpler than sub
* Sub-commands provide usage and documentation
* Support for additional documentation topics/reporting
* Demonstrates simple implementation conventions and patterns (e.g. options handling)
* Adopts the informal [bash "strict" mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/) which considerably aids debugging.
* (does not yet support command completion.)

## Features

* supports default option flags (--verbose --quiet --help --debug --dry-run --confirm --ddebug)
* default means for platform determination
* finds sub-commands via a configurable search path (allows local overides)
* finds config files via a configurable search path
* reads a config file (to set environment vars) before running sub-commands
* sub-commands may be written in any shell or language
* sub-commands may have metadata for help
* sub-commands can run as source, exec, or eval
* help included provides:
	* list of help topics - `groan help topics` / `groan topics`
	* list of commands and their usage - `groan help commands` / `groan commands`
	* markdown viewer support
	
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

## Config Files

Groan looks for config files in a number of places. This can be configured in `groan.locations.sh`

```
	"$g_working_dir/$c_file.conf"  # --local
	"$HOME/.$c_file.conf"          # --user
	"$c_dir/$c_file.conf"          # --global )
```

## Sub-Commands

...follow the convention `commands/<c_sub_cmd>.sub.sh`

* `<name>.sub.sh` will directly source the shell file <name>.cmd.sh
* `<name>.sub.exec` will exec the <name>.cmd.exec
* `<name>.sub.su` will sudo the <name>.cmd.exec
* `<name>.sub.*` will eval the <name>.cmd.*
	* `<name>.sub.rb`
	* `<name>.sub.fish` ...etc

Non-shell scripts provide their help metadata via `<name>.meta.sh`

### Subcommand - help topics (provided by `helper`)

The help c_sub_cmd included provides:

* Display text file giving information on a topic e.g. `groan help topic test-topic`
	* `<topicname>.topic.txt` e.g. `test-topic.topic.txt`    
	* `<topicname>.topic.md`  e.g. `test-topic.topic.md`

#### Help Meta Data

Commands are implemented expecting that they may be run with the METADATAONLY flag, in which case they populate variables and exit prior to doing anything:

* `$command`
* `$s_description`
* `$s_usage`

### Subcommand - environment

The environment c_sub_cmd prints out the environment variables (or evaluates a given expression) in the context of where scripts will run, after applying the config file.

* `groan environment --eval "echo $PATH"`

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

### Subcommand - remote (provided by `sensible`)

  Expects to find remote host configuration has been provided via a `conf` file that can be loaded using `configure`. Example:

```
sensible_host_names=('test' 'atomic' 'rocky')
 
declare -Ag sensible_deploy sensible_tags sensible_install

sensible_install["_default_"]="/usr/local/bin"

sensible_deploy[test]='localhost:/tmp/sensible'
sensible_tags[test]='test'
sensible_install[test]='/tmp'

sensible_deploy[atomic]='keith@atomic.flat:/home/keith/base'
sensible_install[atomic]='/home/keith/bin'
sensible_tags[atomic]='server'
```
  
  * Remote deploy via: `groan remote deploy --tag=test --install --confirm`
  * Remote execute via: `groan remote exec --tag=all -- pwd`
  * Remote undeploy via: `groan remote undeploy --tag=all --confirm`

## Sub-command aliasing

The script `groan/commands/help.sub.helper.cmd._dispatch.sh` implements aliasing of one sub-command to another.
If you copy this script and rename to `assistant.sub.helper.cmd._dispatch.sh` then the new `assistant` command
will be handled by the enclosed `helper` command via `../helper/commands/_dispatch.sh`.

Aliasing can also be done, directly to another command e.g. `commands.sub.helper.cmd.commands.sub.sh`
and within the same suite. e.g. `crumbs.sub..cmd.breadcrumbs.sub.sh`

## Test Suite

The comprehensive test suite is here http://github.com/keithy/groan-dev using the `bash-spec` framework.

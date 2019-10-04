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

Clone this repository, and rename the files 'rename_me' to be the top level name of your command.
Add your scripts (in any language) and help topics, to the `sub-commands` folder. 

Your command can be nested within other commands, or you can compose your command from others. 
The help facilities are provided by the enclosed command `helper`, and the remote upload and execution capability
is provided by the command `sensible`.

## Commands with sub-commands and sub-sub-commands...

Roll your own gitlike command suites, complete with help-documentation help-topics.
Support for standard options like --debug, --quiet is also included.

## Clever Stuff

Groan is recursively merge-able/compose-able. Assemble a named suite of sub-command scripts in a folder, 
that folder may be made available alongside, or nested as sub-commands within another suite.

Groan uses/demonstrates this internally to implement the help sub-command. 
The `groan help` sub-command of `groan` is implemented by the nested command `helper`. 

In the folder hierarchy `yourcommand/groan/helper` there is a fully functioning suite of 
bash commands called `helper`, nested as a sub-command within another suite called `groan`, 
merged with another for you to customize called `rename_me`. 

## How to fork and roll your own command

Fork **keithy/groan** to **yourrepo/yourcommand** then create your working branch with the name of your
new command suite then you can pull-request your enhancements, and others can see what you are using it for.

Rename files and directories `rename_me`, `rename_me.locations.sh`

Your subcommands go into `sub-commands` folder.

Add another nested/merged command by adding the folder. For an example of the `help` sub-command calling
the nested `helper` command's own dispatcher for its sub-commands look at `help.sub.helper.cmd._dispatch.sh`

To use this feature copy the file as is and rename it to point to any other sub-sub-command.

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
* finds sub-commands via a configurable search path (allows local overides)
* finds config files via a configurable search path
* reads a config file (to set environment vars) before running sub-commands
* sub-commands may be written in any shell or language
* sub-commands can run as source, exec, or eval
* help subcommand included provides:
	* list of help topics - `groan help topics`
	* list of commands and their usage - `groan help commands` / `groan commands`
	* markdown viewer support
	
## General Principles

Groan subcommands are called after having:

* processed and filtered out the standard set of flags.
    * --verbose -V
    * --debug -D
    * --quiet 
    * --dry-run    # enabled by default
    * --confirm    # disables --dry-run flag for destructive operations
    * --ddebug -DD # developer debug
* attempted to work out what platform it is running on. 
* found and 'sourced' a config-file.

## Config Files

Groan looks for config files in a number of places. This is configured in `rename_me.locations.sh`

## Sub-Commands

...follow the convention `sub-commands/<subcommand>.sub.sh`

* `<name>.sub.sh` will source the subcommand
* `<name>.sub.exec` will exec the subcommand
* `<name>.sub.*` will eval the subcommand
	* `<name>.sub.rb`
	* `<name>.sub.fish` ...etc

Non-shell scripts provide their help metadata via `<name>.meta.sh`

### Subcommand - help topics (provided by `helper`)

The help subcommand included provides:

* Display text file giving information on a topic e.g. `groan help topic test-topic`
	* `<topicname>.topic.txt` e.g. `test-topic.topic.txt`    
	* `<topicname>.topic.md`  e.g. `test-topic.topic.md`

#### Help Meta Data

Commands are implemented expecting that they may be run with the METADATAONLY flag, in which case they populate variables and exit prior to doing anything:

* `$command`
* `$description`
* `$usage`

### Subcommand - environment

The environment subcommand prints out the environment variables (or evaluates a given expression) in the context of where scripts will run, after applying the config file.

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

    groan self-install /usr/local/bin --link --confirm

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
  
  * Remote deploy via: `rename_me remote deploy --tag=test --install --confirm`
  * Remote execute via: `rename_me remote exec --tag=all -- pwd`
  * Remote undeploy via: `rename_me remote undeploy --tag=all --confirm`

## Sub-command aliasing

The script `groan/groan.commands/help.sub.helper.cmd._dispatch.sh` implements aliasing of one sub-command to another.
If you copy this script and rename to `assistant.sub.helper.cmd._dispatch.sh` then the new `assistant` command
will be handled by the enclosed `helper` command via `../helper/helper.commands/_dispatch.sh`.

Aliasing can also be done, directly to another command e.g. `commands.sub.helper.cmd.commands.sub.sh`
and within the same suite. e.g. `crumbs.sub..cmd.breadcrumbs.sub.sh`

## Test Suite

The comprehensive test suite is here http://github.com/keithy/groan-dev using the `bash-spec` framework.

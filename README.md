# 🥊 mulle-bashfunctions, a collection of shell functions

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-bashfunctions.svg)

This is a shell function library used by a lot of mulle tools. It is
compatible with bash v3.2+ and zsh 5+. Use mulle-bashfunctions to develop more
featureful scripts.

### Features

* A common framework for initializing a script with subscripts
* Array and associative array for backwards compatibility
* Execution control, trace external commands without executing them
* Extensive major.minor.patch version support
* Logging with color or without
* Parsing of common command flags
* Support for parallel execution of multiple tasks
* Various file functions with an emphasis on safety
* Various string functions, like escaping, case conversion, searching
* Has lots of tests


Executable            | Description
----------------------|--------------------------------
`mulle-bash`          | Shell executor as a replacement for `#! /bin/sh`
`mulle-bashfunctions` | Find the location of the mulle-bashfunctions library


## Install

The command to install the latest mulle-bashfunctions into `/usr` with sudo
is:

``` sh
curl -L 'https://github.com/mulle-nat/mulle-bashfunctions/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-bashfunctions-latest' && sudo ./bin/installer /usr
```

### Packages

OS    | Command
------|------------------------------------
macos | `brew install mulle-kybernetik/software/mulle-bashfunctions`


## Usage

With `mulle-sde` installed add, you can get yourself a nice starter script:

``` bash
mulle-sde add my-script-name.sh
mulle-sde add --file-extension sh my-script-name # no .sh extension
```

Or starting from scratch, put as the first lines of your shell script:

``` bash
#! /usr/bin/env mulle-bash
# shellcheck shell=bash
```

This will start your script with the default `mulle-bashfunctions.sh`
preloaded. To enjoy the various logging and tracing capabilities, you would
add `options_technical_flags` and `options_setup_trace` to your argument
parsing, maybe somewhat like this:

```bash
   while [ $# -ne 0 ]
   do
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         # handle other flags here

         -*)
            fail "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   # handle non flag arguments here
```

With `mulle-bashfunction.sh` preloaded you have access to a basic selection
of libraries, namely:


Name                                        | Descriptions
--------------------------------------------|------------------
[compatibility](src/mulle-compatibility.sh) | abstraction of zsh and bash differences
[logging](src/mulle-logging.sh)             | log support with colorization, zero cost if unused
[exekutor](src/mulle-exekutor.sh)           | run external commands with logging and "dry-run"
[file](src/mulle-file.sh)                   | functions to manage files, directories, symlinks
[options](src/mulle-options.sh)             | default handling of commandline options and trace support
[path](src/mulle-path.sh)                   | functions dealing with file paths
[string](src/mulle-string.sh)               | a multitude of string functions


Use `include <name>` to get access to the functions not included in
`mulle-bashfunctions.sh` (but in `mulle-bashfunctions-all.sh`), namely:

Name                              | Descriptions
----------------------------------|------------------
[array](src/mulle-array.sh)       | maintain arrays as a string separated by linefeeds
[case](src/mulle-case.sh)         | perform camelCase conversions
[etc](src/mulle-etc.sh)           | maintain a writable `etc` folder, shadowed by read-only `share`
[parallel](src/mulle-parallel.sh) | execute parallel processes without swamping the machine
[url](src/mulle-url.sh)           | URL parser
[version](src/mulle-version.sh)   | semver version management major.minor.version


## Runtime environment

If run under **zsh**, `mulle-bashfunctions.sh` will `setopt sh_word_split`
and `setopt POSIX_ARGZERO`. 

* `pipefail` is set and expected to be kept.
* `extglob` is set and required for bash and zsh for a few functions.
* `expand_aliases` is set and required for use of the `.for .do .done` macros.
* `-u` or `+u` should work
* `-e` will not work (!)

Glob settings are unaffected and expected to be enabled by default.


## Conventions

`RVAL` is a global variable. It is used to pass return values from functions.
The RVAL value can be clobbered by **any** function. Functions that return RVAL
are prefixed with `r_` or `_r_` or somesuch.


## Develop

Do not edit the almagamated `mulle-bashfunctions*.sh` files, they are generated
by running `cmake .` in the project directory.


## Author

[Nat!](//www.mulle-kybernetik.com/weblog) for
[Mulle kybernetiK](//www.mulle-kybernetik.com) and
[Codeon GmbH](//www.codeon.de)

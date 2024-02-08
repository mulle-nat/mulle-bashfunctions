# 🥊 mulle-bashfunctions, a collection of shell functions

This is a shell function library used by a lot of mulle tools. It is
compatible with bash v3.2+ and zsh 5+. Use mulle-bashfunctions to develop more
featureful scripts that work on multiple platforms. This library has been
tested on **Debian**, **FreeBSD**, **macOS**, **Manjaro**, **MinGW**,
**NetBSD**, **OpenBSD**, **Solaris**, **Ubuntu**.

| Release Version                                       | Release Notes
|-------------------------------------------------------|--------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/mulle-nat/mulle-bashfunctions.svg?branch=release) [![Build Status](https://github.com/mulle-nat/mulle-bashfunctions/workflows/CI/badge.svg?branch=release)](//github.com/mulle-nat/mulle-bashfunctions/actions) | [RELEASENOTES](RELEASENOTES.md) |

## Executables

| Executable            | Description
|-----------------------|--------------------------------
| `mulle-bash`          | Shell executor as a replacement for `#! /bin/sh`
| `mulle-bashfunctions` | Include support, documentation and more


## API

Use mulle-bashfunctions for discovery and documentation about itself.

You can list all the functions in **mulle-bashfunctions** like
this:

``` sh
for i in `mulle-bashfunctions libraries`
do
    echo "### $i"
    mulle-bashfunctions functions "$i"
    echo
done
```

but you can also use `apropos` to discover functionality:

``` sh
mulle-bashfunctions apropos uppercase
```

Once you have found a function of interest, you can checkout its description
with


``` sh
mulle-bashfunctions man r_uppercase
```
and try it out with `eval` for functions printing to standard output,
or `r-eval`, for functions that return values in the `RVAL` global variable
(these functionss are prefixed with `r_`):


``` sh
$ mulle-bashfunctions r-eval r_uppercase xyz
XYZ
```


### Libraries

Your script running under `#! /usr/bin/env mulle-bash` will have
`mulle-bashfunction.sh` preloaded. So you have access to a basic selection
of libraries, namely:


| Name                                        | Descriptions                                        |
|---------------------------------------------|-----------------------------------------------------|
| [compatibility](src/mulle-compatibility.sh) | abstraction of zsh and bash differences             |
| [logging](src/mulle-logging.sh)             | log support with colorization, zero cost if unused  |
| [exekutor](src/mulle-exekutor.sh)           | run external commands with logging and "dry-run"    |
| [file](src/mulle-file.sh)                   | functions to manage files, directories, symlinks    |
| [options](src/mulle-options.sh)             | default handling of commandline options and trace support |
| [path](src/mulle-path.sh)                   | functions dealing with file paths                   |
| [string](src/mulle-string.sh)               | a multitude of string functions                     |


Use `include "<name>"` to get access to the functions not included in
`mulle-bashfunctions.sh` namely:

| Name                              | Descriptions                                                    |
|-----------------------------------|-----------------------------------------------------------------|
| [array](src/mulle-array.sh)       | maintain arrays as a string separated by linefeeds              |
| [case](src/mulle-case.sh)         | perform camelCase conversions                                   |
| [etc](src/mulle-etc.sh)           | maintain a writable `etc` folder, shadowed by read-only `share` |
| [parallel](src/mulle-parallel.sh) | execute parallel processes without swamping the machine         |
| [url](src/mulle-url.sh)           | URL parser                                                      |
| [version](src/mulle-version.sh)   | semver version management major.minor.version                   |


### Example

This example loads some additional functionality into a mulle-bashfunctions
script and executes it:


``` sh
#! /usr/bin/env mulle-bash


include "case"

r_smart_downcase_identifier "${1:-EO.Foundation}"
printf "%s\n" "${RVAL}"
```


## Usage

```
Usage:
   mulle-bashfunctions [command]

   mulle-bashfunctions main purpose is to help load the library functions
   into an interactive shell. The library functions are almalgamated in a
   file called "mulle-bashfunctions.sh". There are variants though (none,
   minimal, all) with different sizes.

   But mulle-bashfunctions can also

   * embed "mulle-bashfunctions.sh" into another shell script
   * show the path to "mulle-bashfunctions.sh"
   * locate the "mulle-bashfunctions.sh" install path for a desired variant
   * show documentation for any of the defined functions
   * list the available libraries, which you can "include"
   * run an arbitrary mulle-bashfunction with eval and r-eval

Examples:
   Load "mulle-bashfunctions-all.sh" into the current interactive shell:

      eval `mulle-bashfunctions load all`

Commands:
   apropos <f>    : search for a function by keywords
   embed          : embed mulle-bashfunctions into a script
   env            : environment needed for "mulle-bashfunctions.sh"
   eval <cmd>     : evaluate cmd inside of mulle-bashfunctions
   functions      : list defined functions
   hostname       : show system hostname used by mulle-bashfunctions
   libraries      : list available libraries
   load [variant] : use  eval `mulle-bashfunctions load`  to load
   man <function> : show documention for function, if available
   path [variant] : path to "mulle-bashfunctions.sh"
   r-eval <cmd>   : evaluate cmd inside of mulle-bashfunctions and print RVAL
   username       : show username used by mulle-bashfunctions
   uname          : show system short name used by mulle-bashfunctions
   version        : print currently used version
   versions       : list installed versions

```



### How to write single-file mulle-bash scripts

1. Say `mulle-sde add my-script.sh` to create a mulle-bash script skeleton.
2. ... actually write the script ...
3. Say `mulle-bashfunction embed < my-script-sh` to create a standalone script.

The resulting script will run with `#! /bin/sh` and does not need a
mulle-bashfunctions installation.


### Runtime environment

If run under **zsh**, `mulle-bashfunctions.sh` will `setopt sh_word_split`
and `setopt POSIX_ARGZERO` and will also `set -o GLOB_SUBST`.

* `pipefail` is set and expected to be kept.
* `extglob` is set and required for bash and zsh for a few functions.
* `expand_aliases` is set and required for use of the `.for .do .done` macros.
* `-u` or `+u` should work
* `-e` will not work (!)
* `posix` is turned off

Glob settings are unaffected and expected to be enabled by default.

### Conventions

`RVAL` is a global variable. It is used to pass return values from functions.
The RVAL value can be clobbered by **any** function. Functions that return RVAL
are prefixed with `r_` or `_r_` or some such. Functions that return multiple
values are currently prefixed with `__`. This may change to `g_` in the
future.


### Develop

Do not edit the amalgamated `mulle-bashfunctions*.sh` files, they are generated
by running `cmake .` in the project directory.
Check out the small pamphlet [Modern Bash (Zsh) Scripting](https://www.mulle-kybernetik.com/modern-bash-scripting)
by yours truly, for some background information on the techniques being used.








## Install

The command to install the latest mulle-bashfunctions into `/usr/local` (with **sudo**) is:

``` bash
curl -L 'https://github.com/mulle-nat/mulle-bashfunctions/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-bashfunctions-latest' && sudo ./bin/installer /usr/local
```

### Packages

| OS    | Command                            | Comment
|-------|------------------------------------|-------------------------
| macos | `brew install mulle-kybernetik/mulle-bashfunctions` | 
| linux | `apt install mulle-bashfunctions` | See [here](https://github.com/mulle-sde/mulle-sde-developer#debian-mulle-kybernetik-repository) for apt repository


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK



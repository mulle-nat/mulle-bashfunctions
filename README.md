# 🥊 mulle-bashfunctions, a collection of shell functions

This is a shell function library used by a lot of mulle tools. It is
compatible with bash v3.2+ and zsh 5+. Use mulle-bashfunctions to develop more
featureful scripts that work on multiple platforms. This library has been
tested on **Debian**, **FreeBSD**, **macOS**, **Manjaro**, **MinGW**,
**NetBSD**, **OpenBSD**, **Solaris**, **Ubuntu**.

| Release Version                                       | Release Notes
|-------------------------------------------------------|--------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/mulle-nat/mulle-bashfunctions.svg?branch=release) [![Build Status](https://github.com/mulle-nat/mulle-bashfunctions/workflows/CI/badge.svg?branch=release)](//github.com/mulle-nat/mulle-bashfunctions/actions)| [RELEASENOTES](RELEASENOTES.md) |

## Executables

| Executable            | Description
|-----------------------|--------------------------------
| `mulle-bash`          | Shell executor as a replacement for `#! /bin/sh`
| `mulle-bashfunctions` | Include support, documentation and more


## API

With `mulle-bashfunction.sh` preloaded you have access to a basic selection
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
`mulle-bashfunctions.sh` (but in `mulle-bashfunctions-all.sh`), namely:

| Name                              | Descriptions                                                    |
|-----------------------------------|-----------------------------------------------------------------|
| [array](src/mulle-array.sh)       | maintain arrays as a string separated by linefeeds              |
| [case](src/mulle-case.sh)         | perform camelCase conversions                                   |
| [etc](src/mulle-etc.sh)           | maintain a writable `etc` folder, shadowed by read-only `share` |
| [parallel](src/mulle-parallel.sh) | execute parallel processes without swamping the machine         |
| [url](src/mulle-url.sh)           | URL parser                                                      |
| [version](src/mulle-version.sh)   | semver version management major.minor.version                   |




### Runtime environment

If run under **zsh**, `mulle-bashfunctions.sh` will `setopt sh_word_split`
and `setopt POSIX_ARGZERO` and will also `set -o GLOB_SUBST`.

* `pipefail` is set and expected to be kept.
* `extglob` is set and required for bash and zsh for a few functions.
* `expand_aliases` is set and required for use of the `.for .do .done` macros.
* `-u` or `+u` should work
* `-e` will not work (!)

Glob settings are unaffected and expected to be enabled by default.

### Conventions

`RVAL` is a global variable. It is used to pass return values from functions.
The RVAL value can be clobbered by **any** function. Functions that return RVAL
are prefixed with `r_` or `_r_` or somesuch. Functions that return multiple
values are currently prefixed with `__`. This may change to `g_` in the
future.


### Develop

Do not edit the almagamated `mulle-bashfunctions*.sh` files, they are generated
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



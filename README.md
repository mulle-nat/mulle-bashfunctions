# 🥊 mulle-bashfunctions, a collection of bash functions

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-bashfunctions.svg)


This is a bash function library used by a lot of mulle tools. It is
compatible with bash v3.2, because that is the baseline available on macos.

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

It's not well documented, so you probably are just here, because it's a
prerequisite for another mulle tool.

Executable                | Description
--------------------------|--------------------------------
`mulle-bashfunctions-env` | Find the location of the mulle-bashfunctions library


Use `mulle-bashfunctions-env --version 3` to find the place of the scripts that
provide version 3 compatibility.


## Install

Install into `/usr` with sudo:

```
curl -L 'https://github.com/mulle-nat/mulle-bashfunctions/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-bashfunctions-latest' && sudo ./installer /usr
```

### Packages

OS          | Command
------------|------------------------------------
macos       | `brew install mulle-kybernetik/software/mulle-bashfunctions`


## Conventions

`RVAL` is a global variable. It is used to pass return values from functions.
The RVAL value can be clobbered by **any** function. Functions that return RVAL
are prefixed with `r_` or `_r_` or somesuch.


## Usage

In your program:


```
MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env libexec-dir`"
. "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
```
Now you can call the functions provided by the library.


#### Quick start with mulle-sde

You can get a functional template shell script with mulle-sde:

```
# must have .sh extension initially
mulle-sde add --vendor mulle-nat my-script.sh
```


## Author

[Nat!](//www.mulle-kybernetik.com/weblog) for
[Mulle kybernetiK](//www.mulle-kybernetik.com) and
[Codeon GmbH](//www.codeon.de)

# 🥊 mulle-bashfunctions, a collection of bash functions

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-bashfunctions.svg)


This is a bash function library used and shared by a lot of mulle tools.
It's not documented, so you probably are just here, because it's a prerequisite
for another mulle tool.

Executable                | Description
--------------------------|--------------------------------
`mulle-bashfunctions-env` | Find the location of the mulle-bashfunctions library


Use `mulle-bashfunctions-env --version 2` to find the place of the scripts that
provide version 2 compatibility.


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
MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env libexec-dir 2> /dev/null`"
[ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && \
   echo "mulle-bashfunctions are not installed" >&2 && \
   exit 1

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

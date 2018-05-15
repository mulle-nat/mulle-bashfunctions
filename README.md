# 🥊 mulle-bashfunctions, a collection of bash functions

![Last version](https://img.shields.io/github/tag/{{PUBLISHER}}/mulle-bashfunctions.svg)


This is a bash function library used and shared by a lot of mulle tools.
It's not documented, so you probably are just here, because it's a prerequisite
for another mulle tool.


## Install

OS          | Command
------------|------------------------------------
macos       | `brew install mulle-kybernetik/software/mulle-bashfunctions`
other       | `curl -L https://github.com/mulle-nat/mulle-bashfunctions/archive/latest.tar.gz | tar xfz - && cd mulle-bashfunctions-latest && ./install`



Executable                | Description
--------------------------|--------------------------------
`mulle-bashfunctions-env` | Find the location of the mulle-bashfunctions library


Use `mulle-bashfunctions-env --version 1` to find the place of the scripts that provide version 1 compatibility.


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


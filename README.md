# 🥊 mulle-bashfunctions, a collection of bash functions

![Last version](https://img.shields.io/github/tag/{{PUBLISHER}}/mulle-bashfunctions.svg)


Use `mulle-bashfunctions --version 1` to find the place of the scripts that
provide version 1 compatibility.


## Install

OS          | Command
------------|------------------------------------
macos       | `brew install mulle-kybernetik/software/mulle-bashfunctions`
other       | ./install.sh


## Usage

In your program:


```
MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path 2> /dev/null`"
[ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && \
   echo "mulle-bashfunctions-env not installed" >&2 && \
   exit 1

. "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
```

Now you can call the functions provided by the library.


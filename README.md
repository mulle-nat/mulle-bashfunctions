[comment]: <> (DO NOT EDIT THIS FILE. EDIT THE TEMPLATE "templates/README.md.scion")
# mulle-bashfunctions, a collection of bash functions

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-bashfunctions.svg)


Use `mulle-bashfunctions --version 1` to find the place of the scripts that
provide version 1 compatability.


Install it with `brew install mulle-nat/software/mulle-bashfunctions` or
`apt-get install mulle-bashfunctions`.


## Usage

In your program


MULLE_LIBEXEC_PATH="`mulle-bashfunctions-env library-path 1`" || exit 1

. mulle-bashfunctions.sh || exit 1

#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
[ ! -z "${MULLE_INIT_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-init.sh" >&2

[ -z "${MULLE_STRING_SH}" ] && echo "mulle-string.sh must be included before mulle-init.sh" 2>&1 && exit 1


MULLE_INIT_SH="included"


# result in _linkpath global
_resolve_symlinks()
{
   if _linkpath="`readlink "$1"`"
   then
      case "${_linkpath}" in
         /*)
            _resolve_symlinks "${_linkpath}"
         ;;
         *)
            local _directory

            _fast_dirname "$1"
            _resolve_symlinks "${_directory}/${_linkpath}"
         ;;
      esac
   else
      _linkpath="$1"
   fi
}


# return _libexecdir
#
# executablepath: will be $0
# subdir: will be mulle-bashfunctions/${VERSION}
# matchfile: the file to match agains
#
# Written this way, so it can get reused
#
_get_libexec_dir()
{
   local executablepath="$1"
   local subdir="$2"
   local matchfile="$3"

   local exedirpath
   local prefix

   case "${executablepath}" in
      \.*|/*|~*)
      ;;

      *)
         executablepath="`command -v "${executablepath}"`"
      ;;
   esac

   local _linkpath

   _resolve_symlinks "${executablepath}"
   executablepath="${_linkpath}"

   local _directory

   _fast_dirname "${executablepath}"
   exedirpath="${_directory}"

   _fast_dirname "${exedirpath}"
   prefix="${_directory}"


   # now setup the global variable

   _libexec_dir="${prefix}/libexec/${subdir}"

   if [ ! -f "${_libexec_dir}/${matchfile}" ]
   then
      _libexec_dir="${exedirpath}/src"
   fi

   case "$_libexec_dir" in
      /*|~*)
      ;;

      .)
         _libexec_dir="$PWD"
      ;;

      *)
         _libexec_dir="$PWD/${_libexec_dir}"
      ;;
   esac

   if [ ! -f "${_libexec_dir}/${matchfile}" ]
   then
      unset _libexec_dir
      echo "$0 fatal error: Could not find \"${subdir}\" libexec ($PWD)" >&2
      exit 1
   fi
}

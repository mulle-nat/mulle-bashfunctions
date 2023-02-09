# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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
if ! [ ${MULLE_INIT_SH+x} ]
then
MULLE_INIT_SH='included'

[ -z "${MULLE_STRING_SH}" ] && _fatal "mulle-string.sh must be included before mulle-init.sh"


#
# r_dirname <file>
#
#    Shell version of the `dirname` command. Just a lot faster in usage,
#    because no external process is spawned.
#
function r_dirname()
{
   RVAL="$1"

   while :
   do
      case "${RVAL}" in
         /)
            return
         ;;

         */)
            RVAL="${RVAL%?}"
            continue
         ;;
      esac
      break
   done

   local last

   last="${RVAL##*/}"
   RVAL="${RVAL%${last}}"

   while :
   do
      case "${RVAL}" in
         /)
           return
         ;;

         */)
            RVAL="${RVAL%?}"
         ;;

         *)
            RVAL="${RVAL:-.}"
            return
         ;;
      esac
   done
}


#
# r_prepend_path_if_relative <path> <file>
#
#    Prepend <path> to <file> if <file> is not an absolute path.
#
r_prepend_path_if_relative()
{
   #
   # stolen from:
   # http://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
   # ----
   #
   case "$2" in
      /*)
         RVAL="$2"
      ;;

      *)
         RVAL="$1/$2"
      ;;
   esac
}


#
# r_resolve_symlinks <file>
#
#    Find the actual file <file> is pointing at. This function does not
#    canonicalize but it will resolve multiple symlinks. The returned filepath
#    can still contain symlinks though, but not at the last position.
#    e.g. /usr/dir-symlink/file-symlink -> /usr/dir-symlink/file
#
function r_resolve_symlinks()
{
   local filepath

   RVAL="$1"

   if filepath="`readlink "${RVAL}"`"
   then
      r_dirname "${RVAL}"
      r_prepend_path_if_relative "${RVAL}" "${filepath}"
      r_resolve_symlinks "${RVAL}"
   fi
}


#
# r_get_libexec_dir <executablepath> <subdir> <matchfile>
#
#    Find the libexec dir of a mulle-bashfunctions script.
#    executablepath: will be $0
#    subdir: will be  ${MULLE_EXECUTABLE}
#    matchfile: a file to match against, to verify the directory
#
function r_get_libexec_dir()
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

   r_resolve_symlinks "${executablepath}"
   executablepath="${RVAL}"

   # retarded debian does symlink /bin -> /usr/bin
   # the installer notices and places libexec into /usr/libexec
   # so we need the real "bin" here at excessive cost
   #
   r_dirname "${executablepath}"
   exedirpath="`( cd "${RVAL}" && pwd -P ) 2>/dev/null `"

   r_dirname "${exedirpath}"
   prefix="${RVAL}"

   # now setup the global variable
   local is_present

   RVAL="${prefix}/${MULLE_BASHFUNCTIONS_LIBEXEC_DIRNAME:-libexec}/${subdir}"
   if [ ! -f "${RVAL}/${matchfile}" ]
   then
      RVAL="${exedirpath}/src"
   else
      is_present="${RVAL}/${matchfile}"
   fi

   case "$RVAL" in
      /*|~*)
      ;;

      .)
         RVAL="$PWD"
      ;;

      *)
         RVAL="$PWD/${RVAL}"
      ;;
   esac

   # small speed up on slow WSL
   if [ "${is_present}" = "${RVAL}/${matchfile}" ]
   then
      return 0
   fi

   if [ ! -f "${RVAL}/${matchfile}" ]
   then
      printf "%s\n" "$0 fatal error: Could not find \"${subdir}\" libexec (${PWD#"${MULLE_USER_PWD}/"})" >&2
      exit 1
   fi
}


#
# r_escaped_eval_arguments ...
#
#    All arguments are escaped to prevent unwanted extension in an eval.
#
function r_escaped_eval_arguments()
{
   local arg
   local args
   local sep

   args=""
   for arg in "$@"
   do
      printf -v args "%s%s%q" "${args}" "${sep}" "${arg}"
      sep=" "
   done

   RVAL="${args}"
}


#
# call_with_flags <function> <flags> ...
#
#    Call a <function> with with <flags> interposed before the remaining
#    arguments.
#
call_with_flags()
{
   local functionname="$1"; shift
   local flags="$1"; [ $# -ne 0 ] && shift

   if [ -z "${flags}" ]
   then
      ${functionname} "$@"
      return $?
   fi

   r_escaped_eval_arguments "$@"
   eval "'${functionname}'" "${flags}" "${RVAL}"
}

fi
:

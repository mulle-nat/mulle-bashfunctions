#! /usr/bin/env bash
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
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
[ ! -z "${MULLE_FILE_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-file.sh" >&2

[ -z "${MULLE_BASHGLOBAL_SH}" ] && echo "mulle-bashglobal.sh must be included before mulle-file.sh" 2>&1 && exit 1
[ -z "${MULLE_PATH_SH}" ]       && echo "mulle-path.sh must be included before mulle-file.sh" 2>&1 && exit 1
[ -z "${MULLE_EXEKUTOR_SH}" ]   && echo "mulle-exekutor.sh must be included before mulle-file.sh" 2>&1 && exit 1


MULLE_FILE_SH="included"


# ####################################################################
#                        Files and Directories
# ####################################################################
#
mkdir_if_missing()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      return 0
   fi

   log_fluff "Creating directory \"$1\" (${PWD#${MULLE_USER_PWD}/})"

   local rval

   exekutor mkdir -p "$1"
   rval="$?"

   if [ "${rval}" -eq 0 ]
   then
      return 0
   fi

   if [ -L "$1" ]
   then
      r_resolve_symlinks "$1"
      if [ ! -d "${RVAL}" ]
      then
         fail "failed to create directory \"$1\" as a symlink is there"
      fi
      return 0
   fi

   if [ -f "$1" ]
   then
      fail "failed to create directory \"$1\" because a file is there"
   fi
   fail "failed to create directory \"$1\" from $PWD ($rval)"
}


r_mkdir_parent_if_missing()
{
   local dstdir="$1"

   r_dirname "${dstdir}"
   case "${RVAL}" in
      ""|\.)
      ;;

      *)
         mkdir_if_missing "${RVAL}"
         return $?
      ;;
   esac

   return 1
}


# need this still for mulle-objc-lista
mkdir_parent_if_missing()
{
   r_mkdir_parent_if_missing "$@"
}


dir_is_empty()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ ! -d "$1" ]
   then
      return 2
   fi

   local empty

   empty="`ls -A "$1" 2> /dev/null`"
   [ -z "$empty" ]
}


rmdir_safer()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      r_assert_sane_path "$1"
      exekutor chmod -R ugo+wX "${RVAL}" >&2 || fail "Failed to make \"${RVAL}\" writable"
      exekutor rm -rf "${RVAL}"  >&2 || fail "failed to remove \"${RVAL}\""
   fi
}


rmdir_if_empty()
{
   [ -z "$1" ] && internal_fail "empty path"

   if dir_is_empty "$1"
   then
      exekutor rmdir "$1"  >&2 || fail "failed to remove $1"
   fi
}


_create_file_if_missing()
{
   local filepath="$1" ; shift

   [ -z "${filepath}" ] && internal_fail "empty path"

   if [ -f "${filepath}" ]
   then
      return
   fi

   local directory

   r_dirname "${filepath}"
   directory="${RVAL}"
   if [ ! -z "${directory}" ]
   then
      mkdir_if_missing "${directory}"
   fi

   log_fluff "Creating \"${filepath}\""
   if [ ! -z "$*" ]
   then
      redirect_exekutor "${filepath}" printf "%s\n" "$*" || fail "failed to create \"{filepath}\""
   else
      exekutor touch "${filepath}"  || fail "failed to create \"${filepath}\""
   fi
}


merge_line_into_file()
{
  local line="$1"
  local filepath="$2"

  if fgrep -s -q -x "${line}" "${filepath}" 2> /dev/null
  then
     return
  fi
  redirect_append_exekutor "${filepath}" printf "%s\n" "${line}"
}


create_file_if_missing()
{
   _create_file_if_missing "$1" "# intentionally blank file"
}


_remove_file_if_present()
{
   [ -z "$1" ] && internal_fail "empty path"

   # we don't want to test before hand if the file exists, because that's
   # slow. If we don't use the -f flag, then we might get stuck on a prompt
   # though. We don't want an error message, so -f is also fine. 
   # Unfortunately, we can't find out then if file existed.
   #
   if ! exekutor rm -f "$1" 2> /dev/null
   then
      # oughta be superflous on macOS but gives error codes...
      exekutor chmod u+w "$1"  || fail "Failed to make $1 writable"
      exekutor rm -f "$1"      || fail "failed to remove \"$1\""
   fi
   return 0
}


remove_file_if_present()
{
   # -e or -f does not pick out symlinks on macOS, we need the test for the
   # fluff. So this is even super slow.
   if [ -e "$1"  -o -L "$1" ] && _remove_file_if_present "$1"
   then
      log_fluff "Removed \"${1#${PWD}/}\" (${PWD#${MULLE_USER_PWD}/})"
      return 0
   fi
   return 1
}


#
# mktemp is really slow sometimes, so we prefer uuidgen
#
_make_tmp_in_dir_mktemp()
{
   local tmpdir="$1"
   local name="$2"
   local filetype="$3"

   case "${filetype}" in
      *d*)
         TMPDIR="${tmpdir}" exekutor mktemp -d "${name}-XXXXXXXX"
      ;;

      *)
         TMPDIR="${tmpdir}" exekutor mktemp "${name}-XXXXXXXX"
      ;;
   esac
}


_r_make_tmp_in_dir_uuidgen()
{
   local UUIDGEN="$1"; shift

   local tmpdir="$1"
   local name="$2"
   local filetype="$3"

   local uuid
   local fluke

   local MKDIR
   local TOUCH

   MKDIR="$(command -v mkdir)"
   TOUCH="$(command -v touch)"

   [ -z "${MKDIR}" ] && fail "No \"mkdir\" found in PATH ($PATH)"
   [ -z "${TOUCH}" ] && fail "No \"touch\" found in PATH ($PATH)"

   fluke=0
   RVAL=''

   while :
   do
      uuid="`"${UUIDGEN}"`" || internal_fail "uuidgen failed"
      RVAL="${tmpdir}/${name}-${uuid:0:8}"

      case "${filetype}" in
         *d*)
            exekutor "${MKDIR}" "${RVAL}" 2> /dev/null && return 0
         ;;

         *)
            exekutor "${TOUCH}" "${RVAL}" 2> /dev/null && return 0
         ;;
      esac

      if [ ! -e "${RVAL}" ]
      then
         fluke=$((fluke + 1 ))
         if [ "${fluke}" -lt 3 ]
         then
            fail "Could not (even repeatedly) create \"${RVAL}\" (${filetype:-f})"
         fi
      fi
   done
}


_r_make_tmp_in_dir()
{
   local tmpdir="$1"
   local name="$2"
   local filetype="$3"

   mkdir_if_missing "${tmpdir}"

   [ ! -w "${tmpdir}" ] && fail "${tmpdir} does not exist or is not writable"

   name="${name:-${MULLE_EXECUTABLE_NAME}}"
   name="${name:-mulle}"

   local UUIDGEN

   UUIDGEN="`command -v "uuidgen"`"
   if [ ! -z "${UUIDGEN}" ]
   then
      _r_make_tmp_in_dir_uuidgen "${UUIDGEN}" "${tmpdir}" "${name}" "${filetype}"
      return $?
   fi

   RVAL="`_make_tmp_in_dir_mktemp "${tmpdir}" "${name}" "${filetype}"`"
   return $?
}


r_make_tmp()
{
   local name="$1"
   local filetype="$2"

   local tmpdir

   tmpdir=
   case "${MULLE_UNAME}" in
      darwin)
         # don't like the standard tmpdir, use /tmp
      ;;

      *)
         # remove trailing '/'
         r_filepath_cleaned "${TMPDIR}"
         tmpdir="${RVAL}"
      ;;
   esac
   tmpdir="${tmpdir:-/tmp}"

   _r_make_tmp_in_dir "${tmpdir}" "${name}" "${filetype}"
}


r_make_tmp_file()
{
   r_make_tmp "$1" "f"
}

r_make_tmp_directory()
{
   r_make_tmp "$1" "d"
}


# ####################################################################
#                        Symbolic Links
# ####################################################################
#

r_resolve_all_path_symlinks()
{
   local filepath="$1"

   local resolved

   r_resolve_symlinks "${filepath}"
   resolved="${RVAL}"

   local filename
   local directory
   local resolved

   r_dirname "${resolved}"
   directory="${RVAL}"

   case "${directory}" in
      ''|'/')
         RVAL="${resolved}"
      ;;

      *)
         r_basename "${resolved}"
         filename="${RVAL}"
         r_resolve_all_path_symlinks "${directory}"
         r_filepath_concat "${RVAL}" "${filename}"
      ;;
   esac
}


#
# canonicalizes existing paths
# fails for files / directories that do not exist
#
r_realpath()
{
   [ -e "$1" ] || fail "only use r_realpath on existing files ($1)"

   r_resolve_symlinks "$1"
   r_canonicalize_path "${RVAL}"
}

#
# the target of the symlink must exist
#
create_symlink()
{
   local url="$1"       # URL of the clone
   local stashdir="$2"  # stashdir of this clone (absolute or relative to $PWD)
   local absolute="$3"

   [ -e "${url}" ]        || fail "${C_RESET}${C_BOLD}${url}${C_ERROR} does not exist (${PWD#${MULLE_USER_PWD}/})"
   [ ! -z "${absolute}" ] || fail "absolute must be YES or NO"

   r_absolutepath "${url}"
   r_realpath "${RVAL}"
   url="${RVAL}"        # resolve symlinks

   # need to do this otherwise the symlink fails

   local directory
   # local srcname
   # r_basename "${url}"
   # srcname="${RVAL}"
   r_dirname "${stashdir}"
   directory="${RVAL}"

   mkdir_if_missing "${directory}"
   r_realpath "${directory}"
   directory="${RVAL}"  # resolve symlinks

   #
   # relative paths look nicer, but could fail in more complicated
   # settings, when you symlink something, and that repo has symlinks
   # itself
   #
   if [ "${absolute}" = 'NO' ]
   then
      r_symlink_relpath "${url}" "${directory}"
      url="${RVAL}"
   fi

   local oldlink

   if [ -L "${oldlink}" ]
   then
      oldlink="`readlink "${stashdir}"`"
   fi

   if [ -z "${oldlink}" -o "${oldlink}" != "${url}" ]
   then
      exekutor ln -s -f "${url}" "${stashdir}" >&2 || \
         fail "failed to setup symlink \"${stashdir}\" (to \"${url}\")"
   fi
}


# ####################################################################
#                        File stat
# ####################################################################
#
#
modification_timestamp()
{
   case "${MULLE_UNAME}" in
      linux|mingw)
         stat --printf "%Y\n" "$1"
      ;;

      * )
         stat -f "%m" "$1"
      ;;
   esac
}


# http://askubuntu.com/questions/152001/how-can-i-get-octal-file-permissions-from-command-line
lso()
{
   ls -aldG "$@" | \
   awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print }' | \
   awk '{print $1}'
}


file_is_binary()
{
   local result

   result="`file -b --mime-encoding "$1"`"
   [ "${result}" = "binary" ]
}


# ####################################################################
#                        Directory stat
# ####################################################################

#
# this does not check for hidden files, ignores directories
# optionally give filetype f or d as second agument
#
dir_has_files()
{
   local dirpath="$1"; shift

   local flags

   case "$1" in
      f)
         flags="-type f"
         shift
      ;;

      d)
         flags="-type d"
         shift
      ;;
   esac

   local empty

   empty="`rexekutor find "${dirpath}" -xdev \
                                       -mindepth 1 \
                                       -maxdepth 1 \
                                       -name "[a-zA-Z0-9_-]*" \
                                       ${flags} \
                                       "$@" \
                                       -print 2> /dev/null`"
   [ ! -z "$empty" ]
}


dirs_contain_same_files()
{
   log_entry "dirs_contain_same_files" "$@"

   local etcdir="$1"
   local sharedir="$2"

   if [ ! -d "${etcdir}" -o ! -e "${etcdir}" ]
   then
      internal_fail "Both directories \"${etcdir}\" and \"${sharedir}\" need to exist"
   fi

   # remove any trailing slashes
   etcdir="${etcdir%%/}"
   sharedir="${sharedir%%/}"

   local etcfile
   local sharefile
   local filename 

   IFS=$'\n'; shell_disable_glob
   for sharefile in `find ${sharedir}  \! -type d -print`
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      filename="${sharefile#${sharedir}/}"
      etcfile="${etcdir}/${filename}"

      if ! diff -q -b "${etcfile}" "${sharefile}" > /dev/null
      then
         return 2
      fi
   done

   IFS=$'\n'; shell_disable_glob

   for etcfile in `find ${etcdir} \! -type d -print`
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      filename="${etcfile#${etcdir}/}"
      sharefile="${sharedir}/${filename}"

      if [ ! -e "${sharefile}" ]
      then
         return 2
      fi
   done

   IFS="${DEFAULT_IFS}"; shell_enable_glob

   return 0
}


# ####################################################################
#                         Inplace sed (that works)
# ####################################################################

#
# inplace sed for darwin/freebsd is broken, if there is a 'q' command.
#
# e.g. echo "1" > a ; sed -i.bak -e '/1/d;q' a
#
# So we have to do a lot here
#
# eval_sed()
# {
#    while [ $# -ne 0 ]
#    do
#       r_escaped_shell_string "$1"
#       r_concat "${args}" "${RVAL}"
#       args="${RVAL}"
#       shift
#    done
#
#    eval 'sed' "${args}"
# }


inplace_sed()
{
   local tmpfile
   local args
   local filename
#   local permissions

   local rval 

   case "${MULLE_UNAME}" in
      darwin|freebsd)
         # exekutor sed -i '' "$@"

         while [ $# -ne 1 ]
         do
            r_escaped_shell_string "$1"
            r_concat "${args}" "${RVAL}"
            args="${RVAL}"
            shift
         done

         filename="$1"

         if [ ! -w "${filename}" ]
         then
            if [ ! -e "${filename}" ]
            then
               fail "\"${filename}\" does not exist"
            fi
            fail "\"${filename}\" is not writable"
         fi

#         permissions="`lso "${filename}"`"

         r_make_tmp
         tmpfile="${RVAL}"

         redirect_eval_exekutor "${tmpfile}" 'sed' "${args}" "'${filename}'"
         rval=$?
         if [ $rval -eq 0 ]
         then
#         exekutor chmod "${permissions}" "${tmpfile}"
         # move gives permission errors, this keeps everything OK
            exekutor cp "${tmpfile}" "${filename}"
         fi
         _remove_file_if_present "${tmpfile}" # don't fluff log :)
      ;;

      *)
         exekutor sed -i'' "$@"
         rval=$?
      ;;
   esac

   return ${rval}
}


:

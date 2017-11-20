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
[ ! -z "${MULLE_FILE_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = "YES" ] && \
   echo "double inclusion of mulle-file.sh" >&2

[ -z "${MULLE_PATH_SH}" ] && echo "mulle-path.sh must be included before mulle-file.sh" 2>&1 && exit 1


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

   log_fluff "Creating directory \"$1\" ($PWD)"

   local rval

   exekutor mkdir -p "$1"
   rval="$?"

   if [ "${rval}" -eq 0 ]
   then
      return 0
   fi

   if [ -L "$1" ]
   then
      local resolve

      resolve="`resolve_symlinks "$1"`"
      if [ ! -d "${resolve}" ]
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


mkdir_parent_if_missing()
{
   local dstdir="$1"

   local parent

   parent="`dirname -- "${dstdir}"`"
   case "${parent}" in
      ""|"\.")
      ;;

      *)
         mkdir_if_missing "${parent}" || exit 1
         echo "${parent}"
      ;;
   esac
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
   [ "$empty" = "" ]
}


rmdir_safer()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      assert_sane_path "$1"
      exekutor chmod -R u+w "$1"  >&2 || fail "Failed to make $1 writable"
      exekutor rm -rf "$1"  >&2 || fail "failed to remove $1"
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
   local path="$1" ; shift

   [ -z "${path}" ] && internal_fail "empty path"

   if [ -f "${path}" ]
   then
      return
   fi

   local directory

   directory="`dirname "${path}"`"
   if [ ! -z "${directory}" ]
   then
      mkdir_if_missing "${directory}"
   fi

   log_fluff "Creating \"${path}\""
   if [ ! -z "$*" ]
   then
      redirect_exekutor "${path}" echo "$*" || fail "failed to create \"{path}\""
   else
      exekutor touch "${path}"  || fail "failed to create \"${path}\""
   fi
}


merge_line_into_file()
{
  local path="$1"
  local line="$2"

  if fgrep -s -q -x "${name}" "${path}" 2> /dev/null
  then
     return
  fi
  redirect_append_exekutor "${path}" echo "${line}"
}


create_file_if_missing()
{
  _create_file_if_missing "$1" "# intentionally blank file"
}


remove_file_if_present()
{
   [ -z "$1" ] && internal_fail "empty path"

   if ! exekutor rm -f "$1" > /dev/null >&2
   then
      if [ -e "$1" ]
      then
         exekutor chmod u+w "$1"  >&2 || fail "Failed to make $1 writable"
         exekutor rm -f "$1"  >&2     || fail "failed to remove \"$1\""
      fi
   fi
   log_fluff "Removed \"$1\" ($PWD)"
}


#
# mktemp is really slow sometimes, so we use uuidgen
#
_make_tmp()
{
   local name="${1:-mulle_tmp}"
   local type="${2}"

   case "${UNAME}" in
      darwin|freebsd)
         exekutor mktemp ${type} "/tmp/${name}.`uuidgen`"
      ;;

      *)
         exekutor mktemp ${type} -t "${name}.`uuidgen`"
      ;;
   esac
}


make_tmp_file()
{
   _make_tmp "$1"
}


make_tmp_directory()
{
   _make_tmp "$1" "-d"
}


# ####################################################################
#                        Symbolic Links
# ####################################################################
#

#
# stolen from:
# http://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
# ----
#
_prepend_path_if_relative()
{
   case "$2" in
      /*)
         echo "$2"
      ;;

      *)
         echo "$1/$2"
      ;;
   esac
}


resolve_symlinks()
{
   local dir_context
   local path

   path="`readlink "$1"`"
   if [ $? -eq 0 ]
   then
      dir_context=`dirname -- "$1"`
      resolve_symlinks "`_prepend_path_if_relative "$dir_context" "$path"`"
   else
      echo "$1"
   fi
}

#
# canonicalizes existing paths
# fails for files / directories that do not exist
#
realpath()
{
   [ -e "$1" ] || fail "only use realpath on existing files ($1)"

   canonicalize_path "`resolve_symlinks "$1"`"
}

#
# the target of the symlink must exist
#
create_symlink()
{
   local url="$1"       # URL of the clone
   local stashdir="$2"  # stashdir of this clone (absolute or relative to $PWD)
   local absolute="$3"

   local srcname
   local directory

   [ -e "${url}" ]        || fail "${C_RESET}${C_BOLD}${url}${C_ERROR} does not exist ($PWD)"
   [ ! -z "${absolute}" ] || fail "absolute must be YES or NO"

   url="`absolutepath "${url}"`"
   url="`realpath "${url}"`"  # resolve symlinks

   # need to do this otherwise the symlink fails

   srcname="`basename -- ${url}`"
   directory="`dirname -- "${stashdir}"`"

   mkdir_if_missing "${directory}"
   directory="`realpath "${directory}"`"  # resolve symlinks

   #
   # relative paths look nicer, but could fail in more complicated
   # settings, when you symlink something, and that repo has symlinks
   # itself
   #
   if [ "${absolute}" = "NO" ]
   then
      url="`symlink_relpath "${url}" "${directory}"`"
   fi

   log_info "Symlinking ${C_MAGENTA}${C_BOLD}${srcname}${C_INFO} as \"${url}\" in \"${directory}\" ..."
   exekutor ln -s -f "${url}" "${stashdir}"  >&2 || fail "failed to setup symlink \"${stashdir}\" (to \"${url}\")"
}


# ####################################################################
#                        File stat
# ####################################################################
#
#
modification_timestamp()
{
   case "${UNAME}" in
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
   local result

   empty="`find "${dirpath}" -xdev -mindepth 1 -maxdepth 1 -name "[a-zA-Z0-9_-]*" ${flags} "$@" -print 2> /dev/null`"
   [ ! -z "$empty" ]
}


write_protect_directory()
{
   if [ -d "$1" ]
   then
      log_verbose "Write-protecting ${C_RESET_BOLD}$1${C_VERBOSE} to avoid spurious header edits"
      exekutor chmod -R a-w "$1"
   fi
}

:

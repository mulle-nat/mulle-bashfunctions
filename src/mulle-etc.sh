#! /usr/bin/env bash
#
#   Copyright (c) 2021 Nat! - Mulle kybernetiK
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
[ ! -z "${MULLE_ETC_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-etc.sh" >&2

MULLE_ETC_SH="included"


# functions to maintain .mulle/etc and .mulle/share folders
# share folders are periodically updated by upgrades and etc folders 
# contain user edits. The unchanged files are symlinked, so that only the
# etc folder is used, but the unchanged contents are still upgradable
#
etc_prepare_for_write_of_file()
{
   log_entry "etc_prepare_for_write_of_file" "$@"

   local filename="$1"

   if [ -L "${filename}" ]
   then
      exekutor rm "${filename}"
   fi
}


etc_make_file_from_symlinked_file()
{
   log_entry "etc_make_file_from_symlinked_file" "$@"

   local dstfile="$1"

   if [ ! -L "${dstfile}" ]
   then
      return 1
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      flags="-v"
   fi

   local targetfile

   targetfile="`readlink "${dstfile}"`"
   exekutor rm "${dstfile}"

   local directory
   local filename

   r_dirname "${dstfile}"
   directory="${RVAL}"
   r_basename "${dstfile}"
   filename="${RVAL}"
   (
      cd "${directory}" || exit 1

      if [ ! -f "${targetfile}" ]
      then
         log_fluff "Stale link encountered"
         return 0
      fi

      exekutor cp ${flags} "${targetfile}" "${filename}" || exit 1
      exekutor chmod ug+w "${filename}"
   ) || fail "Could not copy \"${targetfile}\" to \"${dstfile}\""
}


etc_symlink_or_copy_file()
{
   log_entry "etc_symlink_or_copy_file" "$@"

   local srcfile="$1"
   local dstdir="$2"
   local filename="$3"

   [ -f "${srcfile}" ] || internal_fail "\"${srcfile}\" does not exist or not a file"
   [ -d "${dstdir}" ]  || internal_fail "\"${dstdir}\" does not exist or not a directory"

   local dstfile

   if [ -z "${filename}" ]
   then
   	r_basename "${srcfile}"
   	filename="${RVAL}"
	fi

   r_filepath_concat "${dstdir}" "${filename}"
   dstfile="${RVAL}"

   if [ -e "${dstfile}" ]
   then
      fail "\"${dstfile}\" already exists"
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      flags="-v"
   fi

   case "${MULLE_UNAME}" in
      mingw)
         exekutor cp ${flags} "${srcfile}" "${dstfile}"
         exekutor chmod ug+w "${dstfile}"
         return $?
      ;;
   esac

   local linkrel

   r_relative_path_between "${srcfile}" "${dstdir}"
   linkrel="${RVAL}"

   exekutor ln -s ${flags} "${linkrel}" "${dstfile}"
}


etc_setup_from_share_if_needed()
{
   log_entry "etc_setup_from_share_if_needed" "$@"

   local etc="$1"
   local share="$2"

   if [ -d "${etc}" ]
   then
      log_fluff "etc folder already setup"
      return
   fi

   # always create etc now
   mkdir_if_missing "${etc}"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      flags="-v"
   fi

   local file
   local filename

   #
   # use per default symlinks and change to file on edit (makes it
   # easier to upgrade unedited files
   #
   shopt -s nullglob
   for filename in "${share}"/*
   do
      shopt -u nullglob
      etc_symlink_or_copy_file "${filename}" "${etc}"
   done
   shopt -u nullglob
}



#
# walk through etc symlinks, cull those that point to knowwhere
# replace files with symlinks, whose content is identical to share
#
etc_repair_files()
{
   log_entry "etc_repair_files" "$@"

   local dstdir="$1"
   local srcdir="$2"
   local glob="$3"
   local add="$4"

   srcdir="${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}"
   dstdir="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}"

   if [ ! -d "${dstdir}" ]
   then
      log_verbose "Nothing to repair, as \"${dstdir}\" does not exist yet"
      return
   fi

   local filename
   local dstfile
   local srcfile
   local can_remove_etc

   can_remove_etc='YES'

   #
   # go through etc, throw out symlinks that point to nowhere
   # create symlinks for files that are identical in share and throw old
   # files away
   #
   shopt -s nullglob
   for dstfile in "${dstdir}"/* # dstdir is etc
   do
      shopt -u nullglob

      r_basename "${dstfile}"
      filename="${RVAL}"
      srcfile="${srcdir}/${filename}"

      if [ -L "${dstfile}" ]
      then
         if ! ( cd "${dstdir}" && [ -f "`readlink "${filename}"`" ] )
         then
            globtest="${glob}${filename#${glob}}"   # hack for patternfile 
            if [ ! -z "${glob}" ] && [ -f "${srcdir}"/${globtest} ]
            then
               log_verbose "\"${filename}\" moved to ${globtest}: relink"
               exekutor rm "${dstfile}"
               etc_symlink_or_copy_file "${srcdir}/"${globtest} "${dstdir}"
            else
               log_verbose "\"${filename}\" no longer exists: remove"
               exekutor rm "${dstfile}"
            fi
         else
            log_fluff "\"${filename}\" is a healthy symlink: keep"
         fi
      else
         if [ -f "${srcfile}" ]
         then
            if diff -q -b "${dstfile}" "${srcfile}" > /dev/null
            then
               log_verbose "\"${filename}\" has no user edits: replace with symlink"
               exekutor rm "${dstfile}"
               etc_symlink_or_copy_file "${srcfile}" "${dstdir}"
            else
               log_fluff "\"${filename}\" contains edits: keep"
               can_remove_etc='NO'
            fi
         else
            log_fluff "\"${filename}\" is an addition: keep"
            can_remove_etc='NO'
         fi
      fi
   done

   #
   # go through share, symlink everything that is not in etc
   #
   shopt -s nullglob
   for srcfile in "${srcdir}"/*
   do
      shopt -u nullglob

      r_basename "${srcfile}"
      filename="${RVAL}"
      dstfile="${dstdir}/${filename}"

      if [ ! -e "${dstfile}" ]
      then
         if [ "${add}" = 'YES' ]
         then
            log_verbose "\"${filename}\" is missing: recreate"
            etc_symlink_or_copy_file "${srcfile}" "${dstdir}" 
         else
            log_info "\"${filename}\" is not used. Use \`repair --add\` to add it."
            can_remove_etc='NO'
         fi
      fi
   done
   shopt -u nullglob

   if [ "${can_remove_etc}" = 'YES' ]
   then
      log_info "\"${dstdir#${MULLE_USER_PWD}/}\" contains no user changes so use \"share\" again"
      rmdir_safer "${dstdir}"
      rmdir_if_empty "${srcdir}"
   fi
}

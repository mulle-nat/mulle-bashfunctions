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
   local symlink="$4"

   [ -f "${srcfile}" ] || internal_fail "\"${srcfile}\" does not exist or is not a file"
   [ -d "${dstdir}" ]  || internal_fail "\"${dstdir}\" does not exist or is not a directory"

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

   r_mkdir_parent_if_missing "${dstfile}"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      flags="-v"
   fi

   if [ -z "${symlink}" ]
   then
      case "${MULLE_UNAME}" in
         mingw)
            symlink="NO"
         ;;

         *)
            symlink="YES"
         ;;
      esac
   fi

   if [ "${symlink}" = 'YES' ]
   then
      local linkrel

      r_relative_path_between "${srcfile}" "${dstdir}"
      linkrel="${RVAL}"

      exekutor ln -s ${flags} "${linkrel}" "${dstfile}"
      return $?
   fi

   exekutor cp ${flags} "${srcfile}" "${dstfile}" &&
   exekutor chmod ug+w "${dstfile}"
}


etc_setup_from_share_if_needed()
{
   log_entry "etc_setup_from_share_if_needed" "$@"

   local etc="$1"
   local share="$2"
   local symlink="$3"

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

   local filename
   local base

   #
   # use per default symlinks and change to file on edit (makes it
   # easier to upgrade unedited files
   #
   IFS=$'\n'; set -f
   for filename in `find "${share}" ! -type d -print`
   do
      IFS="${DEFAULT_IFS}"; set +f
      r_basename "${filename}"
      etc_symlink_or_copy_file "${filename}" \
                               "${etc}" \
                               "${RVAL}" \
                               "${symlink}"
   done
   IFS="${DEFAULT_IFS}"; set +f
}


etc_remove_if_possible()
{
   log_entry "etc_remove_if_possible" "$@"

   local etc="$1"
   local share="$2"

   if [ ! -d "${etc}" ]
   then
      return
   fi

   if dirs_contain_same_files "${etc}" "${share}"
   then
      rmdir_safer "${etc}"
   fi
}


#
# walk through etc symlinks, cull those that point to knowwhere
# replace files with symlinks, whose content is identical to share
#
etc_repair_files()
{
   log_entry "etc_repair_files" "$@"

   local srcdir="$1" # share
   local dstdir="$2" # etc

   local glob="$3"
   local add="$4"
   local symlink="$5"

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

   dstdir="${dstdir%%/}"
   srcdir="${srcdir%%/}"

   #
   # go through etc, throw out symlinks that point to nowhere
   # create symlinks for files that are identical in share and throw old
   # files away
   #
   IFS=$'\n'; set -f
   for dstfile in `find "${dstdir}" ! -type d -print` # dstdir is etc
   do
      IFS="${DEFAULT_IFS}"; set +f

      filename="${dstfile#${dstdir}/}"
      srcfile="${srcdir}/${filename}"

      if [ -L "${dstfile}" ]
      then
         if ! ( cd "${dstdir}" && [ -f "`readlink "${filename}"`" ] )
         then
            # hack for patternfile only works for flat structure probably
            globtest="${glob}${filename#${glob}}"
            if [ ! -z "${glob}" ] && [ -f "${srcdir}"/${globtest} ]
            then
               log_verbose "\"${filename}\" moved to ${globtest}: relink"
               remove_file_if_present "${dstfile}"
               etc_symlink_or_copy_file "${srcdir}/"${globtest} \
                                        "${dstdir}" \
                                        "" \
                                        "${symlink}"
            else
               log_verbose "\"${filename}\" no longer exists: remove"
               remove_file_if_present "${dstfile}"
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
               remove_file_if_present "${dstfile}"
               etc_symlink_or_copy_file "${srcfile}" \
                                        "${dstdir}" \
                                        "${filename}" \
                                        "${symlink}"
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
   # Go through share, symlink everything that is not in etc. This is
   # may make files that have been deleted reappear though. So you explicitly
   # allow this with "add"
   #
   IFS=$'\n'; set -f
   for srcfile in `find "${srcdir}" ! -type d -print` # dstdir is etc
   do
      IFS="${DEFAULT_IFS}"; set +f

      filename="${srcfile#${srcdir}/}"
      dstfile="${dstdir}/${filename}"

      if [ ! -e "${dstfile}" ]
      then
         if [ "${add}" = 'YES' ]
         then
            log_verbose "\"${filename}\" is missing: recreate"
            etc_symlink_or_copy_file "${srcfile}" \
                                     "${dstdir}" \
                                     "${filename}" \
                                     "${symlink}"
         else
            log_info "\"${filename}\" is new but not used. Use \`repair --add\` to add it."
            can_remove_etc='NO'
         fi
      fi
   done
   IFS="${DEFAULT_IFS}"; set +f

   if [ "${can_remove_etc}" = 'YES' ]
   then
      log_info "\"${dstdir#${MULLE_USER_PWD}/}\" contains no user changes so use \"share\" again"
      rmdir_safer "${dstdir}"
      rmdir_if_empty "${srcdir}"
   fi
}


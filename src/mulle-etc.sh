# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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
if ! [ ${MULLE_ETC_SH+x} ]
then
MULLE_ETC_SH="included"


# functions to maintain .mulle/etc and .mulle/share folders
# share folders are periodically updated by upgrades and etc folders
# contain user edits. The unchanged files are symlinked, so that only the
# etc folder is used, but the unchanged contents are still upgradable
#



#
# etc_make_file_from_symlinked_file <dstfile>
#
#    Turn a symlink into a file with the contents of the symlink destination.
#
function etc_make_file_from_symlinked_file()
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
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   log_verbose "Turn symlink \"${dstfile}\" into a file"

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
      rexekutor cd "${directory}" || exit 1

      if [ ! -f "${targetfile}" ]
      then
         log_fluff "Stale link encountered"
         return 0
      fi

      exekutor cp ${flags} "${targetfile}" "${filename}" || exit 1
      exekutor chmod ug+w "${filename}"
   ) || fail "Could not copy \"${targetfile}\" to \"${dstfile}\""
}



#
# etc_prepare_for_write_of_file <filename>
#
#    Turns <filename> from a symlink into a file, otherwise doesn't.
#    Ensures that parent directory exists
#
function etc_prepare_for_write_of_file()
{
   log_entry "etc_prepare_for_write_of_file" "$@"

   local filename="$1"

   r_mkdir_parent_if_missing "${filename}"

   etc_make_file_from_symlinked_file "${filename}"
}



#
# etc_make_symlink_if_possible <filename>
#
#    Turns <filename> into a symlink, if the contents are the
#    same as those on the share file.
#
# Returns 0 : did make symlink
#         1 : symlinking error
#         2 : share file does not exist
#         3 : contents differ
#         4 : already a symlink
#
function etc_make_symlink_if_possible()
{
   log_entry "etc_make_symlink_if_possible" "$@"

   local dstfile="$1"
   local sharedir="$2"
   local symlink="$3"

   if [ -z "${sharedir}" ]
   then
      return 2
   fi

   if [ -L "${dstfile}" ]
   then
      return 4
   fi

   local srcfile
   local filename

   r_basename "${dstfile}"
   filename="${RVAL}"

   r_filepath_concat "${sharedir}" "${filename}"
   srcfile="${RVAL}"

   if [ ! -e "${srcfile}" ]
   then
      return 2
   fi

   local DIFF

   if ! DIFF="`command -v diff`"
   then
      fail "diff command not installed"
   fi

   local dstdir

   r_dirname "${dstfile}"
   dstdir="${RVAL}"

   if ! "${DIFF}" -b "${dstfile}" "${srcfile}" > /dev/null
   then
      return 3
   fi

   log_verbose "\"${dstfile}\" has no user edits: replace with symlink"

   remove_file_if_present "${dstfile}"
   etc_symlink_or_copy_file "${srcfile}" \
                            "${dstdir}" \
                            "${filename}" \
                            "${symlink}"
   return $?
}


#
# etc_symlink_or_copy_file <srcfile> <dstdir> [filename] [symlink]
#
#    Copy or symlink a <srcfile> to directory <dstdir>. You may choose a
#    a different <filename> for the destination.
#    You can force the use of symlinks, with "YES" for <symlink>. Use "NO" for
#    copy, or leave empty for the default actions (which is to use symlinks,
#    if available on the platform)
#
#    If the destination exists, this function does returns with 1.
#
function etc_symlink_or_copy_file()
{
   log_entry "etc_symlink_or_copy_file" "$@"

   local srcfile="$1"
   local dstdir="$2"
   local filename="$3"
   local symlink="$4"

   [ -f "${srcfile}" ] || _internal_fail "\"${srcfile}\" does not exist or is not a file"
   [ -d "${dstdir}" ]  || _internal_fail "\"${dstdir}\" does not exist or is not a directory"

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
      log_error "\"${dstfile}\" already exists"
      return 1
   fi

   r_mkdir_parent_if_missing "${dstfile}"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   if [ -z "${symlink}" ]
   then
      case "${MULLE_UNAME}" in
         'mingw'|'msys')
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


#
# etc_setup_from_share_if_needed <etc> <share> [symlink]
#
#    Setup an <etc> directory from <share>. This will by done by coping or
#    by generating symlinks in <etc>.
#    You can force the use of symlinks, with "YES" for <symlink>. Use "NO" for
#    copy, or leave empty for the default actions (which is to use symlinks,
#    if available on the platform)
#
function etc_setup_from_share_if_needed()
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
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   local filename

   #
   # use per default symlinks and change to file on edit (makes it
   # easier to upgrade unedited files
   #
   if [ -d "${share}" ] # sometimes it's not there, but find complains
   then
      .foreachline filename in `find "${share}" ! -type d -print`
      .do
         r_basename "${filename}"
         etc_symlink_or_copy_file "${filename}" \
                                  "${etc}" \
                                  "${RVAL}" \
                                  "${symlink}"
      .done
   fi
}


#
# etc_remove_if_possible <etc> <share>
#
#    Remove <etc> directory, if it's contents are identical to <share>
#
function etc_remove_if_possible()
{
   log_entry "etc_remove_if_possible" "$@"

   [ $# -eq 2 ] || _internal_fail "API error"

   local etcdir="$1"
   local sharedir="$2"

   if [ ! -d "${etcdir}" ]
   then
      return
   fi

   if dirs_contain_same_files "${etcdir}" "${sharedir}"
   then
      rmdir_safer "${etcdir}"
   fi
}


#
# etc_repair_files <share> <etc> [glob] [add] [symlink]
#
#    Walk through etc symlinks, cull those that point to knowhere.
#    Replace files with symlinks, whose content is identical to those in share.
#    On platforms with no symlinks, the files will be copied.
#
#    glob    : set to non-empty to perform a glob test
#    add     : set to "YES" to add new files to <etc>
#    symlink : set to "NO", "YES or "" (default)
#
function etc_repair_files()
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

   local DIFF

   if ! DIFF="`command -v diff`"
   then
      fail "diff command not installed"
   fi

   #
   # go through etc, throw out symlinks that point to nowhere
   # create symlinks for files that are identical in share and throw old
   # files away
   #
   .foreachline dstfile in `find "${dstdir}" ! -type d -print` # dstdir is etc
   .do
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
            if "${DIFF}" -b "${dstfile}" "${srcfile}" > /dev/null
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
   .done

   #
   # Go through share, symlink everything that is not in etc. This is
   # may make files that have been deleted reappear though. So you explicitly
   # allow this with "add"
   #
   .foreachline srcfile in `find "${srcdir}" ! -type d -print` # dstdir is etc
   .do
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
   .done

   if [ "${can_remove_etc}" = 'YES' ]
   then
      log_info "\"${dstdir#"${MULLE_USER_PWD}/"}\" contains no user changes so use \"share\" again"
      rmdir_safer "${dstdir}"
      rmdir_if_empty "${srcdir}"
   fi
}

fi
:
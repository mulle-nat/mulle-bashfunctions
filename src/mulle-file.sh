# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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
if ! [ ${MULLE_FILE_SH+x} ]
then
MULLE_FILE_SH='included'

[ -z "${MULLE_BASHGLOBAL_SH}" ] && _fatal "mulle-bashglobal.sh must be included before mulle-file.sh"
[ -z "${MULLE_PATH_SH}" ]       && _fatal "mulle-path.sh must be included before mulle-file.sh"
[ -z "${MULLE_EXEKUTOR_SH}" ]   && _fatal "mulle-exekutor.sh must be included before mulle-file.sh"


# ####################################################################
#                        Files and Directories
# ####################################################################
#

#
# mkdir_if_missing <directory>
#
#    Create <directory>, if not already there. If this can't be done, because
#    of permissions maybe or because there is a file under this name there,
#    mkdir_if_missing will print an error and exit!
#
function mkdir_if_missing()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if [ -d "$1" ]
   then
      return 0
   fi

   local rval

   exekutor mkdir -p "$1"
   rval="$?"

   if [ "${rval}" -eq 0 ]
   then
      log_fluff "Created directory \"$1\" (${PWD#"${MULLE_USER_PWD}/"})"
      return 0
   fi

   if [ -L "$1" ]
   then
      r_resolve_symlinks "$1"
      if [ ! -d "${RVAL}" ]
      then
         fail "failed to create directory \"$1\" as a symlink to a file is there"
      fi
      return 0
   fi

   if [ -f "$1" ]
   then
      fail "failed to create directory \"$1\" because a file is there"
   fi
   fail "failed to create directory \"$1\" from $PWD ($rval)"
}


#
# r_mkdir_parent_if_missing <filename>
#
#    Ensure that <directory> is there to write to <filename>.
#    If this can't be done, r_mkdir_parent_if_missing will print an error and
#    exit!
#
#    Returns the name of the directory in all cases.
#    Returns 1 if the directory need not be created.
#
function r_mkdir_parent_if_missing()
{
   local filename="$1"

   local dirname

   r_dirname "${filename}"
   dirname="${RVAL}"

   case "${dirname}" in
      ""|\.)
         return 1
      ;;
   esac

   mkdir_if_missing "${dirname}"
   RVAL="${dirname}"
   return 0
}


#
# dir_is_empty <directory>
#
#    Returns 0 if there are no files in <directory>
#
function dir_is_empty()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if [ ! -d "$1" ]
   then
      return 2
   fi

   local empty

   empty="`ls -A "$1" 2> /dev/null`"
   [ -z "$empty" ]
}


#
# rmdir_safer <directory>
#
#    Tries valiantly to remove directory. If the directory isn't there, that's
#    no problem. r_assert_sane_path is used to check, that the user isn't
#    accidentally deleting some system path.
#
rmdir_safer()
{
   [ -z "$1" ] && _internal_fail "empty path"

   # solaris can't do it so catch this relatively cheaply early on
   [ $"PWD" = "${directory}" ] && fail "Refuse to remove PWD"

   if [ -d "$1" ]
   then
      r_assert_sane_path "$1"

      case "${MULLE_UNAME}" in
         'android'|'sunos')
            exekutor chmod -R ugo+wX "${RVAL}" 2> /dev/null
         ;;
         *)
            exekutor chmod -R ugo+wX "${RVAL}"  || fail "Failed to make \"${RVAL}\" writable"
         ;;
      esac
      exekutor rm -rf "${RVAL}"  >&2 || fail "failed to remove \"${RVAL}\""
   fi
}


#
# rmdir_if_empty <directory>
#
#    Remove <director> if it is unsed. Exits on failure.
#
rmdir_if_empty()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if dir_is_empty "$1"
   then
      exekutor rmdir "$1"  >&2 || fail "failed to remove $1"
   fi
}


_create_file_if_missing()
{
   local filepath="$1" ; shift

   [ -z "${filepath}" ] && _internal_fail "empty path"

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


#
# create_file_if_missing <filename>
#
#    Create a file, if none exists already. Will create directories as needed.
#    Will exit on failure. The file will contain the string
#    '# intentionally blank file'
#
function create_file_if_missing()
{
   _create_file_if_missing "$1" "# intentionally blank file"
}


#
# merge_line_into_file <line> <file>
#
#    Add <line> to <file>, if that line isn't present yet in file.
#
function merge_line_into_file()
{
  local line="$1"
  local filepath="$2"

  if grep -F -q -x "${line}" "${filepath}" > /dev/null 2>&1
  then
     return
  fi
  redirect_append_exekutor "${filepath}" printf "%s\n" "${line}"
}


_remove_file_if_present()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   # we don't want to test before hand if the file exists, because that's
   # slow. If we don't use the -f flag, then we might get stuck on a prompt
   # though. We don't want an error message, so -f is also fine. 
   # Unfortunately, we can't find out then if file existed.
   #
   if ! rm -f "$1" 2> /dev/null
   then
      # oughta be superflous on macOS but gives error codes...
      # and sun gives warnings for symlinks
      case "${MULLE_UNAME}" in
         'sunos')
            exekutor chmod u+w "$1" 2> /dev/null
         ;;
         *)
            exekutor chmod u+w "$1"  || fail "Failed to make $1 writable"
         ;;
      esac
      exekutor rm -f "$1"      || fail "failed to remove \"$1\""
   else
      # print this a little later, because of /dev/null
      exekutor_trace "exekutor_print" rm -f "$1"
   fi
   return 0
}


#
# remove_file_if_present <file>
#
#    Valiantly attempt to remove <file> if present. Exit on failure.
#    Returns 1 if the file didn't exist.
#
remove_file_if_present()
{
   # -e or -f does not pick out symlinks on macOS, we need the test for the
   # fluff. So this is even super slow.
   if [ -e "$1"  -o -L "$1" ] && _remove_file_if_present "$1"
   then
      log_fluff "Removed \"${1#${PWD}/}\" (${PWD#"${MULLE_USER_PWD}/"})"
      return 0
   fi
   return 1
}


r_uuidgen()
{
   # https://www.bsdhowto.ch/uuid.html
   local i

   local -a v

   #
   # this zsh trouble (actually hit me)
   # https://superuser.com/questions/1210435/different-behavior-of-random-in-zsh-and-bash-functions
   #
   if [ ${ZSH_VERSION+x} ]
   then
      if [ -e "/dev/urandom" ]
      then
         RANDOM="`od -vAn -N4 -t u4 < /dev/urandom`"
      else
         if [ -e "/dev/random" ]
         then
            RANDOM="`od -vAn -N4 -t u4 < /dev/random`"
         else
            sleep 1 # need something unique between two calls
            RANDOM="`date +%s`"
         fi
      fi
   fi

   # start with one for zsh :(
   for i in 1 2 3 4 5 6 7 8
   do
      v[$i]=$(($RANDOM+$RANDOM))
   done
   v[4]=$((${v[4]}|16384))
   v[4]=$((${v[4]}&20479))
   v[5]=$((${v[5]}|32768))
   v[5]=$((${v[5]}&49151))
   printf -v RVAL "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" \
                  ${v[1]} ${v[2]} ${v[3]} ${v[4]} \
                  ${v[5]} ${v[6]} ${v[7]} ${v[8]}
}


#
# mktemp is really slow sometimes, so we prefer uuidgen
#
_make_tmp_in_dir_mktemp()
{
   local tmpdir="$1"
   local name="$2"
   local filetype="$3"
   local extension="$4"

   case "${filetype}" in
      *d*)
         TMPDIR="${tmpdir}" exekutor mktemp -d "${name}-XXXXXXXX${extension}"
      ;;

      *)
         TMPDIR="${tmpdir}" exekutor mktemp "${name}-XXXXXXXX${extension}"
      ;;
   esac
}


_r_make_tmp_in_dir_uuidgen()
{
   local UUIDGEN="$1"; shift

   local tmpdir="$1"
   local name="$2"
   local filetype="${3:-f}"
   local extension="$4"

   local MKDIR
   local TOUCH

   MKDIR="$(command -v mkdir)"
   TOUCH="$(command -v touch)"

   [ -z "${MKDIR}" ] && fail "No \"mkdir\" found in PATH ($PATH)"
   [ -z "${TOUCH}" ] && fail "No \"touch\" found in PATH ($PATH)"

   # algorithm hinges on the fact that uuid is well globally
   # unique, so don't shorten it.
   local uuid
   local fluke

   fluke=0
   RVAL=''

   while :
   do
      if [ -z "${UUIDGEN}" ]
      then
         r_uuidgen
         uuid="${RVAL}"
      else
         uuid="`${UUIDGEN}`" || fail "uuidgen failed"
      fi

      RVAL="${tmpdir}/${name}-${uuid}${extension}"

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
         if [ "${fluke}" -gt 20 ]
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
   local filetype="${3:-f}"

   mkdir_if_missing "${tmpdir}"

   [ ! -w "${tmpdir}" ] && fail "${tmpdir} does not exist or is not writable"

   name="${name:-${MULLE_EXECUTABLE_NAME}}"
   name="${name:-mulle}"

   if [ ! -z "${extension}" ]
   then
      extension=".${extension}"
   fi 

   _r_make_tmp_in_dir_uuidgen "" "${tmpdir}" "${name}" "${filetype}" "${extension}"
   return $?
}


#
# r_make_tmp <name> <filetype>
#
#    Create a temporary file, or dirctory if <filetype> is "d".
#    You can leave name empty, in which case the name of the script will
#    be used.
#
#    Exits on failure.
#
function r_make_tmp()
{
   local name="$1"
   local filetype="${2:-f}"
   local extension="$3"

   local tmpdir

   tmpdir=
   case "${MULLE_UNAME}" in
      darwin)
         # don't like the standard tmpdir, use /tmp
      ;;

      *)
         # remove trailing '/'
         tmpdir="${TMP:-${TMPDIR:-${TMP_DIR:-}}}"
         r_filepath_cleaned "${tmpdir}"
         tmpdir="${RVAL}"
      ;;
   esac
   tmpdir="${tmpdir:-/tmp}"

   _r_make_tmp_in_dir "${tmpdir}" "${name}" "${filetype}" "${extension}"
}


#
# r_make_tmp_file <name>
#
#    Create a temporary file.
#    You can leave name empty, in which case the name of the script will
#    be used.
#
#    Exits on failure.
#
function r_make_tmp_file()
{
   r_make_tmp "$1" "f" "$2"
}


#
# r_make_tmp_directory <name>
#
#    Create a temporary directory.
#    You can leave name empty, in which case the name of the script will
#    be used.
#
#    Exits on failure.
#
function r_make_tmp_directory()
{
   r_make_tmp "$1" "d" "$2"
}


# ####################################################################
#                        Symbolic Links
# ####################################################################
#

#
# r_resolve_all_path_symlinks <filepath>
#
#    Resolve all symlinks in filepath. The end result is supposed to be the
#    canonical location on the filesystem.
#
function r_resolve_all_path_symlinks()
{
   local filepath="$1"

   local resolved

   r_resolve_symlinks "${filepath}"
   resolved="${RVAL}"

   local filename
   local directory

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



_r_canonicalize_dir_path()
{
   RVAL="`
   (
     cd "$1" 2>/dev/null &&
     pwd -P
   )`"
}


_r_canonicalize_file_path()
{
   local component
   local directory

   r_basename "$1"
   component="${RVAL}"
   r_dirname "$1"
   directory="${RVAL}"

   if ! _r_canonicalize_dir_path "${directory}"
   then
      return 1
   fi

   RVAL="${RVAL}/${component}"
   return 0
}


#
# r_canonicalize_path <path>
#
#    Get the canonical path for path, which means all symlinks are resolved.
#
#    /tmp/foo.sh.xx -> /var/tmp/foo.sh.xx
#
function r_canonicalize_path()
{
   [ -z "$1" ] && _internal_fail "empty path"

   r_resolve_symlinks "$1"
   if [ -d "${RVAL}" ]
   then
      _r_canonicalize_dir_path "${RVAL}"
   else
      _r_canonicalize_file_path "${RVAL}"
   fi
}


#
# r_physicalpath <filepath>
#
#    Find the physicalpath for <filepath>, which can be a directory, a file
#    or symlink.
#
function r_physicalpath()
{
   if [ -d "$1" ]
   then
      RVAL="`( cd "$1" && pwd -P ) 2>/dev/null `"
      return $?
   fi

   local dir
   local file

   r_dirname "$1"
   dir="${RVAL}"

   r_basename "$1"
   file="${RVAL}"

   if ! r_physicalpath "${dir}"
   then
      RVAL=
      return 1
   fi

   r_filepath_concat "${RVAL}" "${file}"
}


#
# r_realpath <filepath>
#
#    Resolve all symlinks in filepath. The end result is supposed to be the
#    canonical location on the filesystem.
#    Thid function fails for files / directories that do not exist though.
#
function r_realpath()
{
   [ -e "$1" ] || fail "only use r_realpath on existing files ($1)"

   r_resolve_symlinks "$1"
   r_canonicalize_path "${RVAL}"
}

#
# create_symlink <source> <symlink> [absolute]
#
#    Create a <symlink> link to <source>. Set [absolute] to YES, to get
#    an absolute symlink (e.g. /usr/local/foo) instead of a relative
#    symlink (e.g. ../../usr/local/foo)
#
function create_symlink()
{
   local source="$1"       # URL of the clone
   local symlink="$2"      # symlink of this clone (absolute or relative to $PWD)
   local absolute="${3:-NO}"

   [ -e "${source}" ]     || fail "${C_RESET}${C_BOLD}${source}${C_ERROR} does not exist (${PWD#"${MULLE_USER_PWD}/"})"
   [ ! -z "${absolute}" ] || fail "absolute must be YES or NO"

   # doesn't work if mkdir isn't made
   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   r_absolutepath "${source}"
   r_realpath "${RVAL}"
   source="${RVAL}"        # resolve symlinks

   # need to do this otherwise the symlink fails

   local directory
   # local srcname
   # r_basename "${source}"
   # srcname="${RVAL}"
   r_dirname "${symlink}"
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
      r_symlink_relpath "${source}" "${directory}"
      source="${RVAL}"
   fi

   local oldlink

   oldlink=""
   if [ -L "${symlink}" ]
   then
      oldlink="`readlink "${symlink}"`"
   fi

   if [ -z "${oldlink}" -o "${oldlink}" != "${source}" ]
   then
      exekutor ln -s -f "${source}" "${symlink}" >&2 || \
         fail "failed to setup symlink \"${symlink}\" (to \"${source}\")"
   fi
}


# ####################################################################
#                        File stat
# ####################################################################
#
#

#
# modification_timestamp <file>
#
#    Get the modification time of the file. Output to stdout.
#
function modification_timestamp()
{
   case "${MULLE_UNAME}" in
      macos|*bsd|dragonfly)
         stat -f "%m" "$1"
      ;;

      *)
         stat --printf "%Y\n" "$1"
      ;;
   esac
}


#
# lso <file>
#
#    Get the octal permission code (e.g. 755) of one or multiple files.
#
#    Uses `awk`
#
function lso()
{
# http://askubuntu.com/questions/152001/how-can-i-get-octal-file-permissions-from-command-line
   ls -ald "$@" | \
   awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print }' | \
   awk '{print $1}'
}



#
# file_is_binary <file>
#
#    Check if the file is considered "binary" by the system.
#    Returns 0 if binary.
#
function file_is_binary()
{
   local result

   # simple little heurisic
   case "${MULLE_UNAME}" in
      sunos)
         result="`file "$1"`"
         case "${result}" in
            *\ text*|*\ script|*\ document)
               return 1
            ;;
         esac
         return 0
      ;;
   esac

   result="`file -b --mime-encoding "$1"`"
   [ "${result}" = "binary" ]
}


#
# file_size_in_bytes <file>
#
#    Get the file size. Output to stdout.
#
function file_size_in_bytes()
{
   if [ ! -f "$1" ]
   then
      return 1
   fi

   case "${MULLE_UNAME}" in
      darwin|*bsd|dragonfly)
         stat -f '%z' "$1"
      ;;

      *)
         stat -c '%s' -- "$1"
      ;;
   esac
}


# ####################################################################
#                        Directory stat
# ####################################################################

#
# dir_has_files <directory> <filetype>
#
#    This does not check for hidden files, ignores directories
#    optionally given <filetype> "f" or "d" or "l" as the second argument.
#    Only one filetype is allowed (dir_list_files can take multiple).
#
function dir_has_files()
{
   local dirpath="$1"; shift

   case "${MULLE_UNAME}" in
      sunos)
         local lines

         if ! lines="`( rexekutor cd "${dirpath}" && rexekutor ls -1 ) 2> /dev/null `"
         then
            return 1
         fi

         local line

         .foreachline line in ${lines}
         .do
            case "${line}" in
               '.'|'..')
                  .continue
               ;;

               *)
                  case "$1" in
                     f)
                        [ ! -f "${dirpath}/${line}" ] && .continue
                     ;;

                     d)
                        [ ! -d "${dirpath}/${line}" ] && .continue
                     ;;

                     l)
                        [ ! -L "${dirpath}/${line}" ] && .continue
                     ;;
                  esac

                  return 0
               ;;
            esac
         .done
         return 1
      ;;
   esac

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

      l)
         flags="-type l"
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


#
# dir_list_files <directory> [pattern] [filetypes]
#
#    Lists file in <directory> (or directories as <directory> may contain
#    wildcards) line by line.
#    <directory> may contain white space but no tabs. filetypes may be "f" for
#    files or "d" for directories or "l" for symlinks. It can be a combination
#    of these filetypes.
#    Expects glob to be enabled. Resets IFS to default.
#    Leave pattern empty for '*'
#
function dir_list_files()
{
   local directory="$1"
   local pattern="${2:-*}"
   local flagchars="${3:-}"

   [ ! -z "${directory}" ] || _internal_fail "directory is empty"

   log_debug "flagchars=${flagchars}"

   case "${MULLE_UNAME}" in
      sunos)
         local line
         local dirpath
         local lines

         for dirpath in ${directory}
         do
            lines="`( cd "${dirpath}"; ls -1 ) 2> /dev/null`"

            .foreachline line in ${lines}
            .do
               case "${line}" in
                  '.'|'..')
                     .continue
                  ;;

                  *)
                     if [[ $line != ${pattern} ]]
                     then
                        continue
                     fi

                     local match 
                     
                     match='YES'
                     if [ ! -z "${flagchars}" ]
                     then
                        match='NO'
                     fi

                     case "${flagchars}" in
                        *f*)
                           [ -f "${dirpath}/${line}" ] && match='YES'
                        ;;
                     esac
                     case "${flagchars}" in
                        *d*)
                           [ -d "${dirpath}/${line}" ] && match='YES'
                        ;;
                     esac
                     case "${flagchars}" in
                        *l*)
                           [ ! -L "${dirpath}/${line}" ] && match='YES'
                        ;;
                     esac

                     if [ "${match}" = 'NO' ]
                     then
                        .continue
                     fi
                  ;;
               esac
               printf "%s\n" "${dirpath}/${line}"
            .done
         done

         IFS=' '$'\t'$'\n'
         return
      ;;
   esac


   local flags

   if [ ! -z "${flagchars}" ]
   then
      case "${flagchars}" in
         *f*)
            flags="-type f"
         ;;
      esac
      case "${flagchars}" in
         *d*)
            r_concat "${flags}" "-type d" " -o "
            flags="${RVAL}"
         ;;
      esac
      case "${flagchars}" in
         *l*)
            r_concat "${flags}" "-type l"  " -o "
            flags="${RVAL}"
         ;;
      esac

      flags="\\( ${flags} \\)"
   fi

   # need to eval for zsh
   IFS=$'\n'
   eval_rexekutor find ${directory} -xdev \
                                    -mindepth 1 \
                                    -maxdepth 1 \
                                    -name "'${pattern:-*}'" \
                                    ${flags} \
                                    -print  | sort -n
   IFS=' '$'\t'$'\n'
}


#
# dirs_contain_same_files <dir1> <dir2>
#
#    Check if both directories contain the same files. Return 0 if so, return 2
#    of not so. This command actually checks the contents of the files, not
#    just the filenames.
#
function dirs_contain_same_files()
{
   log_entry "dirs_contain_same_files" "$@"

   local etcdir="$1"
   local sharedir="$2"

   if [ ! -d "${etcdir}" -o ! -e "${etcdir}" ]
   then
      _internal_fail "Both directories \"${etcdir}\" and \"${sharedir}\" need to exist"
   fi

   # remove any trailing slashes
   etcdir="${etcdir%%/}"
   sharedir="${sharedir%%/}"

   local DIFF

   if ! DIFF="`command -v diff`"
   then
      fail "diff command not installed"
   fi

   local etcfile
   local sharefile
   local filename 

   .foreachline sharefile in `find ${sharedir} \! -type d -print`
   .do
      filename="${sharefile#${sharedir}/}"
      etcfile="${etcdir}/${filename}"

      # ignore actual text and "missing file" errors
      if ! "${DIFF}" -b "${etcfile}" "${sharefile}" > /dev/null 2>&1
      then
         return 2
      fi
   .done

   .foreachline etcfile in `find ${etcdir} \! -type d -print`
   .do
      filename="${etcfile#${etcdir}/}"
      sharefile="${sharedir}/${filename}"

      if [ ! -e "${sharefile}" ]
      then
         return 2
      fi
   .done

   return 0
}


# ####################################################################
#                         Inplace sed (that works)
# ####################################################################

# inplace_sed <file> ...
#
#    This command runs a sed command on a specific <file>. The <file> is then
#    replaced with the output of the command.
#
#    Basically it's the same as `sed -i.bak ...`, but it's tricky on various
#    platforms and incompatible seds. So use inplace_sed for portability.
#
function inplace_sed()
{
   local tmpfile
   local args
   local filename
#   local permissions

   local rval 

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

   case "${MULLE_UNAME}" in
      darwin|*bsd|sun*|dragonfly)
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

fi
:

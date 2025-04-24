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
if ! [ ${MULLE_PATH_SH+x} ]
then
MULLE_PATH_SH='included'

[ -z "${MULLE_STRING_SH}" ] && _fatal "mulle-string.sh must be included before mulle-path.sh"


# RESET
# NOCOLOR
#
#    Assortment of various string functions that deal with filepaths.
#    None of these functions actually touch the filesystem.
#
#    Functions prefixed "r_" return the result in the global variable RVAL.
#    The return value 0 indicates success.
#
# TITLE INTRO
# COLOR


#
# r_filepath_cleaned <filepath>
#
#    r_filepath_cleaned makes somewhat prettier filenames, removing
#    superfluous "." and trailing '/'. It's fairly cheap though.
#    DO NOT USE ON URLs
#
function r_filepath_cleaned()
{
   RVAL="$1"

   [ -z "${RVAL}" ] && return

   local old

   old=''

   # remove excess //, also inside components
   # remove excess /./, also inside components
   while [ "${RVAL}" != "${old}" ]
   do
      old="${RVAL}"
      RVAL="${RVAL//\/.\///}"
      RVAL="${RVAL//\/\///}"
   done

   if [ -z "${RVAL}" ]
   then
      RVAL="${1:0:1}"
   fi
}


#
# r_filepath_concat <component> ...
#
#    r_filepath_concat concatenates filepaths components to produce a single
#    filepath.
#    .e.g.  "foo" "bar"  ->  foo/bar
#           "/"  "/foo" "." "bar"  ->  /foo/bar
#
r_filepath_concat()
{
   local i
   local s
   local sep
   local fallback

   s=""
   fallback=""

   for i in "$@"
   do
      sep="/"

      r_filepath_cleaned "${i}"
      i="${RVAL}"

      case "$i" in
         "")
            continue
         ;;

         "."|"./")
            if [ -z "${fallback}" ]
            then
               fallback="./"
            fi
            continue
         ;;
      esac

      case "$i" in
         "/"|"/.")
            if [ -z "${fallback}" ]
            then
               fallback="/"
            fi
            continue
         ;;
      esac

      if [ -z "${s}" ]
      then
         s="${fallback}$i"
      else
         case "${i}" in
            /*)
               s="${s}${i}"
            ;;

            *)
               s="${s}/${i}"
            ;;
         esac
      fi
   done

   if [ ! -z "${s}" ]
   then
      r_filepath_cleaned "${s}"
   else
      RVAL="${fallback:0:1}" # / make ./ . again
   fi
}


# ####################################################################
#                             Path handling
# ####################################################################


#
# r_basename <filename>
#
#    In functionality identical to "basename", but much faster than calling
#    the external commands
#
#
#    /tmp/foo.sh -> foo.sh
#
function r_basename()
{
   local filename="$1"

   while :
   do
      case "${filename}" in
         /)
           RVAL="/"
           return
         ;;

         */)
            filename="${filename%?}"
         ;;

         *)
            RVAL="${filename##*/}"
            return
         ;;
      esac
   done
}


#
# r_dirname <filename>
#
#    In functionality identical to "dirname", but much faster than calling
#    the external commands
#
#    /tmp/foo.sh -> /tmp
#
function r_dirname()
{
   local filename="$1"

   local last

   while :
   do
      case "${filename}" in
         /)
            RVAL="${filename}"
            return
         ;;

         */)
            filename="${filename%?}"
            continue
         ;;
      esac
      break
   done

   # need to escape filename here as it may contain wildcards
   printf -v last '%q' "${filename##*/}"
   RVAL="${filename%${last}}"

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
# r_path_depth <filepath>
#
#    Computes the depth of <filepath>
#    Return values are
#     0 = ""
#     1 = /
#     2 = /tmp
#     3 = /tmp/bar
#     3 = /tmp/bar/
#     4 = /tmp/bar/foo
#     ...
#
function r_path_depth()
{
   local name="$1"

   local depth

   depth=0

   if [ ! -z "${name}" ]
   then
      depth=1

      while [ "$name" != "." -a "${name}" != '/' ]
      do
         r_dirname "${name}"
         name="${RVAL}"

         depth=$((depth + 1))
      done
   fi
   RVAL="${depth}"
}


#
# r_extensionless_basename <s>
#
#    Extracts filename from <s> and cut off the last extension only
#
#    /tmp/foo.sh.xxx -> foo.sh
#
function r_extensionless_basename()
{
   r_basename "$@"

   RVAL="${RVAL%.*}"
}


#
# r_extensionless_filename <s>
#
#    Cut off the last extension from <s>
#
#    /tmp/foo.sh.xx -> /tmp/foo.sh
#
function r_extensionless_filename()
{
   RVAL="${1%.*}"
}


#
# r_path_extension <s>
#
#    Retrieve the last extension from <s>
#
#    /tmp/foo.sh.xx -> "xx"
#
function r_path_extension()
{
   r_basename "$@"
   case "${RVAL}" in
      *.*)
        RVAL="${RVAL##*.}"
        return
      ;;
   esac

   RVAL=""
}



# ----
# stolen from: https://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
# because the python dependency irked me.
#
# There must be no ".." or "." in the paths.
#
__r_relative_path_between()
{
    RVAL=''
    [ $# -ge 1 ] && [ $# -le 2 ] || return 1

    current="${2:+"$1"}"
    target="${2:-"$1"}"

    [ "$target" != . ] || target=/

    target="/${target##/}"
    [ "$current" != . ] || current=/

    current="${current:="/"}"
    current="/${current##/}"
    appendix="${target##/}"
    relative=''

    while appendix="${target#"$current"/}"
        [ "$current" != '/' ] && [ "$appendix" = "$target" ]; do
        if [ "$current" = "$appendix" ]; then
            relative="${relative:-.}"
            RVAL="${relative#/}"
            return 0
        fi
        current="${current%/*}"
        relative="$relative${relative:+/}.."
    done

    RVAL="$relative${relative:+${appendix:+/}}${appendix#/}"
}


_r_relative_path_between()
{
   local a
   local b

   if [ "${MULLE_TRACE_PATHS_FLIP_X:-}" = 'YES' ]
   then
      set +x
   fi

   # remove relative components and './' it upsets the code

   r_simplified_path "$1"
   a="${RVAL}"
   r_simplified_path "$2"
   b="${RVAL}"

#   a="`printf "%s\n" "$1" | sed -e 's|/$||g'`"
#   b="`printf "%s\n" "$2" | sed -e 's|/$||g'`"

   [ -z "${a}" ] && _internal_fail "Empty path (\$1)"
   [ -z "${b}" ] && _internal_fail "Empty path (\$2)"

   __r_relative_path_between "${b}" "${a}"   # flip args (historic)

   if [ "${MULLE_TRACE_PATHS_FLIP_X:-}" = 'YES' ]
   then
      set -x
   fi
}

#
# r_relative_path_between <to> <from>
#
#    <to> is the directory/file, that we want to access relative from root
#    <from> is the directory we want to access <to> from. To belabor this
#    <from> can not be a file.
#
#    The routine can not deal with ../ and ./, but is a bit faster than
#    symlink_relpath.
#
#    ex.   /usr/include /usr,  -> include
#    ex.   /usr/include /  -> /usr/include
#
#
function r_relative_path_between()
{
   local a="$1"
   local b="$2"

   # the function can't do mixed paths

   case "${a}" in
      "")
         _internal_fail "First path is empty"
      ;;

      ../*|*/..|*/../*|..)
         _internal_fail "Path \"${a}\" mustn't contain .."
      ;;

      ./*|*/.|*/./*|.)
         _internal_fail "Filename \"${a}\" mustn't contain component \".\""
      ;;


      /*)
         case "${b}" in
            "")
               _internal_fail "Second path is empty"
            ;;

            ../*|*/..|*/../*|..)
               _internal_fail "Filename \"${b}\" mustn't contain \"..\""
            ;;

            ./*|*/.|*/./*|.)
               _internal_fail "Filename \"${b}\" mustn't contain \".\""
            ;;


            /*)
            ;;

            *)
               _internal_fail "Mixing absolute filename \"${a}\" and relative filename \"${b}\""
            ;;
         esac
      ;;

      *)
         case "${b}" in
            "")
               _internal_fail "Second path is empty"
            ;;

            ../*|*/..|*/../*|..)
               _internal_fail "Filename \"${b}\" mustn't contain component \"..\"/"
            ;;

            ./*|*/.|*/./*|.)
               _internal_fail "Filename \"${b}\" mustn't contain component \".\""
            ;;

            /*)
               _internal_fail "Mixing relative filename \"${a}\" and absolute filename \"${b}\""
            ;;

            *)
            ;;
         esac
      ;;
   esac

   _r_relative_path_between "${a}" "${b}"
}


#
# r_compute_relative <s>
#
#    Compute number of ".." needed to return from <path> to root. Returns
#    this as a string.
#    e.g.  cd "a/b/c" -> cd ../../..
#
function r_compute_relative()
{
   local name="${1:-}"

   local relative
   local depth

   r_path_depth "${name}"
   depth="${RVAL}"

   if [ "${depth}" -gt 1 ]
   then
      relative=".."
      while [ "$depth" -gt 2 ]
      do
         relative="${relative}/.."
         depth=$((depth - 1))
      done
   fi

#   if [ -z "$relative" ]
#   then
#      relative="."
#   fi

   RVAL="${relative}"
}


#
# is_absolutepath <filepath>
#
#    Returns 0 if <filepath> is an absolute path.
#    e.g. "/foo" -> 0  "./x" -> 1
#
function is_absolutepath()
{
   case "${1}" in
      /*|~*)
        return 0
      ;;

      *)
        return 1
      ;;
   esac
}


#
# is_relativepath <filepath>
#
#    Returns 0 if <filepath> is a relative path.
#    e.g. "/foo" -> 1  "./x" -> 0
#
function is_relativepath()
{
   case "${1}" in
      ""|/*|~*)
        return 1
      ;;

      *)
        return 0
      ;;
   esac
}


#
# r_absolutepath <filepath> [pwd]
#
#    Creates an absolute filepath from <filepath> The current directory may
#    be passed as [pwd]. Otherwise the result from `pwd` is used. If <filepath>
#    is already absolute, no changes happen.
#
#    e.g. "/foo" -> 1  "./x" -> 0
#
function r_absolutepath()
{
   local filepath="$1"
   local working="$2"

   case "${filepath}" in
      "")
        RVAL=''
        return 1
      ;;

      /*|~*)
        RVAL="${filepath}"
        return 0
      ;;
   esac
   
   working="${working:-`pwd`}"
   if ! is_absolutepath "${working}"
   then
      fail "working directory \"${working}\" must be an absolute path"
   fi

   RVAL="${working%%/}/${filepath}"
}


#
# r_simplified_absolutepath <filepath> [pwd]
#
#    Like r_absolutepath but the resultant path is then simplified with
#    r_simplified_path.
#
function r_simplified_absolutepath()
{
   r_absolutepath "$@"
   r_simplified_path "${RVAL}"
}

#
# r_symlink_relpath <file> <directory>
#
#    Imagine you are in a working <directory>
#    This function gives the relative path you need to create a symlink
#    that points to <file>.
#
function r_symlink_relpath()
{
   local a
   local b

   # _relative_path_between will simplify
   r_absolutepath "$1"
   a="$RVAL"

   r_absolutepath "$2"
   b="$RVAL"

   _r_relative_path_between "${a}" "${b}"
}



#
# _r_simplified_path() works on paths that may or may not exist
# it makes prettier relative or absolute paths
# you can't have | in your path though
#
_r_simplified_path()
{
   local filepath="$1"

   [ -z "${filepath}" ] && fail "empty path given"

   local i
   local last
   local result
   local remove_empty

   result=""
   last=""
   remove_empty='NO'  # remove trailing slashes

   .foreachpathcomponent i in ${filepath}
   .do
      case "$i" in
         \.)
           remove_empty='YES'
           .continue
         ;;

         \.\.)
           # remove /..
           remove_empty='YES'

           if [ "${last}" = "|" ]
           then
              .continue
           fi

           if [ ! -z "${last}" -a "${last}" != ".." ]
           then
              r_remove_last_line "${result}"
              result="${RVAL}"
              r_get_last_line "${result}"
              last="${RVAL}"
              .continue
           fi
         ;;

         ~*)
            fail "Can't deal with ~ filepaths"
         ;;

         "")
            if [ "${remove_empty}" = 'NO' ]
            then
               last='|'
               result='|'
            fi
            .continue
         ;;
      esac

      remove_empty='YES'

      last="${i}"

      r_add_line "${result}" "${i}"
      result="${RVAL}"
   .done


   if [ -z "${result}" ]
   then
      RVAL="."
      return
   fi

   if [ "${result}" = '|' ]
   then
      RVAL="/"
      return
   fi

   RVAL="${result//\|/}"
   RVAL="${RVAL//$'\n'//}"
   RVAL="${RVAL%/}"
}


#
# r_simplified_path <filepath>
#
#    r_simplified_path makes prettier relative or absolute paths.
#    This function works also on filepaths that do not exist.
#    r_simplified_path performs better, if there are no relative components.
#    Caveat: you can't have | in your <filepath>.
#
function r_simplified_path()
{
   #
   # quick check if there is something to simplify
   # because this isn't fast at all
   #
   case "${1}" in
      ""|".")
         RVAL="."
      ;;

      */|*\.\.*|*\./*|*/\.)
         if [ "${MULLE_TRACE_PATHS_FLIP_X:-}" = 'YES' ]
         then
            set +x
         fi

         _r_simplified_path "$@"

         if [ "${MULLE_TRACE_PATHS_FLIP_X:-}" = 'YES' ]
         then
            set -x
         fi
      ;;

      *)
         RVAL="$1"
      ;;
   esac
}


#
# r_assert_sane_path <filepath>
#
#    Use to check a filepath before possible deletion. Will not accept the
#    following filepaths and fail:
#    . .. ~ ${HOME}
#    anything starting with '$'
#    anyfile path whose depth is <= 2, so /usr/local is bad but /usr/local/etc
#    would be okay. /tmp is an exception though.
#
function r_assert_sane_path()
{
   r_simplified_path "$1"

   case "${RVAL}" in
      \$*|~|"${HOME}"|..|.)
         fail "refuse unsafe path \"$1\""
      ;;

      /tmp/*)
      ;;

      ""|/*)
         local filepath

         filepath="${RVAL}"
         r_path_depth "${filepath}"
         if [ "${RVAL}" -le 2 ]
         then
            fail "Refuse suspicious path \"$1\""
         fi
         RVAL="${filepath}"
      ;;

      *)
         if [ "${RVAL}" = "${HOME}" ]
         then
            fail "refuse unsafe path \"$1\""
         fi
      ;;
   esac
}

#
# filepath_contains_filepath <filepath> <other>
#
#    Check if <other> is identical to <filepath> or a plausible file or 
#    subdirectory. This is just string matching! No filesystem checks
#
filepath_contains_filepath()
{
    local filepath="${1%/}"  # Path to check, remove trailing slash
    local other="${2%/}"  # Directory path, remove trailing slash
    
    r_simplified_path "${filepath}"
    filepath="${RVAL}"

    r_simplified_path "${other}"
    RVAL=${RVAL}

    case "${filepath}" in 
      .)
         if is_absolutepath "${other}"
         then 
            return 1
         fi
         return 0
      ;;
    esac

    case "${other}" in
         # Case 1: Strings are identical
         ${filepath})
             return 0
         ;;
         # Case 2: string1 is a subdirectory or file inside other
         ${filepath}/*)
             return 0
         ;;
         # Not a match
         *)
             return 1
         ;;
    esac
}

fi
:

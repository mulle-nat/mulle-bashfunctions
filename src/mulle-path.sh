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
MULLE_PATH_SH="included"

[ -z "${MULLE_STRING_SH}" ] && _fatal "mulle-string.sh must be included before mulle-path.sh"



# ####################################################################
#                             Path handling
# ####################################################################
# 0 = ""
# 1 = /
# 2 = /tmp
# ...
#
r_path_depth()
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
# cuts off last extension only
#
r_extensionless_basename()
{
   r_basename "$@"

   RVAL="${RVAL%.*}"
}


r_extensionless_filename()
{
   RVAL="${RVAL%.*}"
}


r_path_extension()
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


r_canonicalize_path()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if [ -d "$1" ]
   then
      _r_canonicalize_dir_path "$1"
   else
      _r_canonicalize_file_path "$1"
   fi
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
# $1 is the directory/file, that we want to access relative from root
# $2 is the root
#
# ex.   /usr/include /usr,  -> include
# ex.   /usr/include /  -> /usr/include
#
# the routine can not deal with ../ and ./
# but is a bit faster than symlink_relpath
#
r_relative_path_between()
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
# compute number of .. needed to return from path
# e.g.  cd "a/b/c" -> cd ../../..
#
r_compute_relative()
{
   local name="${1:-}"

   local depth
   local relative

   relative=""
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



# TODO: zsh can do this easier
r_physicalpath()
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


# this old form function is used quite a lot still
physicalpath()
{
   if ! r_physicalpath "$@"
   then
      return 1
   fi
   printf "%s\n" "${RVAL}"
}


is_absolutepath()
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


is_relativepath()
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


r_absolutepath()
{
  local directory="$1"
  local working="${2:-${PWD}}"

   case "${directory}" in
      "")
        RVAL=''
      ;;

      /*|~*)
        RVAL="${directory}"
      ;;

      *)
        RVAL="${working}/${directory}"
      ;;
   esac
}


r_simplified_absolutepath()
{
  local directory="$1"
  local working="${2:-${PWD}}"

   case "${1}" in
      "")
        RVAL=''
      ;;

      /*|~*)
        r_simplified_path "${directory}"
      ;;

      *)
        r_simplified_path "${working}/${directory}"
      ;;
   esac
}


#
# Imagine you are in a working directory `dirname b`
# This function gives the relpath you need
# if you were to create symlink 'b' pointing to 'a'
#
r_symlink_relpath()
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

   RVAL="`tr -d '|' <<< "${result}" | tr '\012' '/'`"
   RVAL="${RVAL%/}"
}


#
# works also on filepaths that do not exist
# r_simplified_path is faster, if there are no relative components
#
r_simplified_path()
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
# consider . .. ~ or absolute paths as unsafe
# anything starting with a $ is probably also bad
# this just catches some obvious problems, not all
#
assert_sane_subdir_path()
{
   r_simplified_path "$1"

   case "${RVAL}"  in
      "")
         fail "refuse empty subdirectory \"$1\""
         exit 1
      ;;

      \$*|~|..|.|/*)
         fail "refuse unsafe subdirectory path \"$1\""
      ;;
   esac
}


r_assert_sane_path()
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

fi
:

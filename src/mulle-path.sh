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
[ ! -z "${MULLE_PATH_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-path.sh" >&2

[ -z "${MULLE_STRING_SH}" ] && echo "mulle-string.sh must be included before mulle-path.sh" 2>&1 && exit 1


MULLE_PATH_SH="included"


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

         depth=$(($depth + 1))
      done
   fi
   RVAL="$depth"
}


path_depth()
{
   r_path_depth "$@"
   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


#
# cuts off last extension only
#
r_extensionless_basename()
{
   r_basename "$@"

   RVAL="${RVAL%.*}"
}


extensionless_basename()
{
   r_extensionless_basename "$@"
   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


r_path_extension()
{
   r_basename "$@"

   case "${RVAL}" in
      *.*)
        RVAL="${RVAL##*.}"
      ;;

      *)
         RVAL=""
      ;;
   esac
}


path_extension()
{
   r_path_extension "$@"
   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


_canonicalize_dir_path()
{
   (
      cd "$1" 2>/dev/null &&
      pwd -P
   )  || return 1
}


_canonicalize_file_path()
{
   local component
   local directory

   r_basename "$1"
   component="${RVAL}"
   r_dirname "$1"
   directory="${RVAL}"

   (
     cd "${directory}" 2>/dev/null &&
     echo "`pwd -P`/${component}"
   ) || return 1
}


canonicalize_path()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      _canonicalize_dir_path "$1"
   else
      _canonicalize_file_path "$1"
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

   if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
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

   [ -z "${a}" ] && internal_fail "Empty path (\$1)"
   [ -z "${b}" ] && internal_fail "Empty path (\$2)"

   __r_relative_path_between "${b}" "${a}"   # flip args (historic)

   if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
   then
      set -x
   fi
}


_relative_path_between()
{
   _r_relative_path_between "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
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
         internal_fail "First path is empty"
      ;;

      ../*|*/..|*/../*|..)
         internal_fail "Path \"${a}\" mustn't contain .."
      ;;

      ./*|*/.|*/./*|.)
         internal_fail "Filename \"${a}\" mustn't contain component \".\""
      ;;


      /*)
         case "${b}" in
            "")
               internal_fail "Second path is empty"
            ;;

            ../*|*/..|*/../*|..)
               internal_fail "Filename \"${b}\" mustn't contain \"..\""
            ;;

            ./*|*/.|*/./*|.)
               internal_fail "Filename \"${b}\" mustn't contain \".\""
            ;;


            /*)
            ;;

            *)
               internal_fail "Mixing absolute filename \"${a}\" and relative filename \"${b}\""
            ;;
         esac
      ;;

      *)
         case "${b}" in
            "")
               internal_fail "Second path is empty"
            ;;

            ../*|*/..|*/../*|..)
               internal_fail "Filename \"${b}\" mustn't contain component \"..\"/"
            ;;

            ./*|*/.|*/./*|.)
               internal_fail "Filename \"${b}\" mustn't contain component \".\""
            ;;

            /*)
               internal_fail "Mixing relative filename \"${a}\" and absolute filename \"${b}\""
            ;;

            *)
            ;;
         esac
      ;;
   esac

   _r_relative_path_between "${a}" "${b}"
}


relative_path_between()
{
   r_relative_path_between "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


#
# compute number of .. needed to return from path
# e.g.  cd "a/b/c" -> cd ../../..
#
r_compute_relative()
{
   local name="$1"

   local depth
   local relative

   r_path_depth "${name}"
   depth="${RVAL}"

   if [ "${depth}" -gt 1 ]
   then
      relative=".."
      while [ "$depth" -gt 2 ]
      do
         relative="${relative}/.."
         depth=$(($depth - 1))
      done
   fi

#   if [ -z "$relative" ]
#   then
#      relative="."
#   fi

   RVAL="${relative}"
}


compute_relative()
{
   r_compute_relative "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


# symlink helper
#
# this cds into a physical directory, so that .. is relative to it
# e.g. cd a/b/c might  end up being a/c, so .. is 'a'
# if you just go a/b/c then .. is b
#
cd_physical()
{
   cd "$1" || fail "cd_physical: \"$1\" is not reachable from \"${PWD}\""
   cd "`pwd -P`" # resolve symlinks and go there (changes PWD)
}


physicalpath()
{
   if [ -d "$1" ]
   then
      ( cd "$1" && pwd -P ) 2>/dev/null
      return $?
   fi

   local dir
   local file

   r_dirname "$1"
   dir="${RVAL}"
   r_basename "$1"
   file="${RVAL}"

   ( cd "$1" && concat "`pwd -P`" "${file}" ) 2>/dev/null
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


absolutepath()
{
   r_absolutepath "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
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


simplified_absolutepath()
{
   r_simplified_absolutepath "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
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


symlink_relpath()
{
   r_symlink_relpath "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


_simplify_components()
{
   local i
   local result

   [ -z "${MULLE_ARRAY_SH}" ] && . mulle-array.sh

   result= # voodoo linux fix ?
   IFS=$'\n'
   set -o noglob
   for i in $*
   do
      IFS="${DEFAULT_IFS}"

      set +o noglob
      case "${i}" in
         # ./foo -> foo
         ./)
         ;;

         # bar/.. -> ""
         ../)
            if [ -z "${result}" ]
            then
               result="`array_add "${result}" "../"`"
            else
               if [ "${result}" != "/" ]
               then
                  result="`array_remove_last "${result}"`"
               fi
               # /.. -> /
            fi
         ;;


         # foo/ -> foo
         "/")
            if [ -z "${result}" ]
            then
               result="${i}"
            fi
         ;;

         *)
            result="`array_add "${result}" "${i}"`"
         ;;
      esac
   done
   set +o noglob

   IFS="${DEFAULT_IFS}"

   printf "%s\n" "${result}"
}


_path_from_components()
{
   local components

   components="$1"

   local i
   local composedpath  # renamed this from path, fixes crazy bug on linux ?

   IFS=$'\n'
   set -o noglob
   for i in $components
   do
      composedpath="${composedpath}${i}"
   done

   IFS="${DEFAULT_IFS}"
   set +o noglob

   if [ -z "${composedpath}" ]
   then
      echo "."
   else
      printf "%s\n" "${composedpath}" | sed 's|^\(..*\)/$|\1|'
   fi
}


#
# _simplified_path() works on paths that may or may not exist
# it makes prettier relative or absolute paths
# you can't have | in your path though
#
_simplified_path()
{
   local filepath="$1"

   [ -z "${filepath}" ] && fail "empty path given"

   local i
   local last
   local result
   local remove_empty

#   log_printf "${C_INFO}%b${C_RESET}\n" "$filepath"

   remove_empty='NO'  # remove trailing slashes

   IFS="/"
   set -o noglob
   for i in ${filepath}
   do
#      log_printf "${C_FLUFF}%b${C_RESET}\n" "$i"
      set +o noglob
      case "$i" in
         \.)
           remove_empty='YES'
           continue
         ;;

         \.\.)
           # remove /..
           remove_empty='YES'

           if [ "${last}" = "|" ]
           then
              continue
           fi

           if [ ! -z "${last}" -a "${last}" != ".." ]
           then
              result="$(sed '$d' <<< "${result}")"
              last="$(sed -n '$p' <<< "${result}")"
              continue
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
            continue
         ;;
      esac

      remove_empty='YES'

      last="${i}"
      if [ -z "${result}" ]
      then
         result="${i}"
      else
         result="${result}
${i}"
      fi
   done

   IFS="${DEFAULT_IFS}"
   set +o noglob

   if [ -z "${result}" ]
   then
      echo "."
      return
   fi

   if [ "${result}" = '|' ]
   then
      echo "/"
      return
   fi

   printf "%s" "${result}" | "${TR:-tr}" -d '|' | "${TR:-tr}" '\012' '/'
   echo
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
         if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
         then
            set +x
         fi

         RVAL="`_simplified_path "$@"`"

         if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
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
# works also on filepaths that do not exist
#
simplified_path()
{
   #
   # quick check if there is something to simplify
   # because this isn't fast at all
   #
   case "${1}" in
      ""|".")
         echo "."
      ;;

      */|*\.\.*|*\./*|*/\.)
         if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
         then
            set +x
         fi

         _simplified_path "$@"

         if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
         then
            set -x
         fi
      ;;

      *)
         printf "%s\n" "$1"
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


assert_sane_path()
{
   r_simplified_path "$1"

   case "${RVAL}" in
      \$*|~|${HOME}|..|.)
         log_error "refuse unsafe path \"$1\""
         exit 1
      ;;

      /tmp/*)
      ;;

      ""|/*)
         local filepath

         filepath="${RVAL}"
         r_path_depth "${filepath}"
         if [ "${RVAL}" -le 2 ]
         then
            log_error "refuse suspicious path \"$1\""
            exit 1
         fi
         RVAL="${filepath}"
      ;;
   esac
}

:

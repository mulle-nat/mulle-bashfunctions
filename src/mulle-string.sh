#! /usr/bin/env bash
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
[ ! -z "${MULLE_STRING_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-string.sh" >&2

MULLE_STRING_SH="included"


# ####################################################################
#                            Concatenation
# ####################################################################
#
r_concat()
{
   local separator="${3:- }"

   if [ -z "${1}" ]
   then
      RVAL="${2}"
   else
      if [ -z "${2}" ]
      then
         RVAL="${1}"
      else
         RVAL="${1}${separator}${2}"
      fi
   fi
}


concat()
{
   local RVAL

   r_concat "$@"
   echo "$RVAL"
}


r_remove_prefix()
{
   local old

   RVAL="$1"
   old=''

   while [ "${RVAL}" != "${old}" ]
   do
      old="$RVAL"
      RVAL="${RVAL#$2}"
   done
}


r_remove_suffix()
{
   local old

   RVAL="$1"
   old=''

   while [ "${RVAL}" != "${old}" ]
   do
      old="$RVAL"
      RVAL="${RVAL%$2}"
   done
}


r_remove_duplicate()
{
   local old
   local s

   RVAL="$1"
   old=''

   s="$2"
   case "$s" in
      */*)
        s="${s//\//\/\/}"
      ;;
   esac

   while [ "${RVAL}" != "${old}" ]
   do
      old="${RVAL}"
      RVAL="${RVAL//$s$s/$s}"
   done
}


r_remove_ugly()
{
   local separator="${2:- }"

   r_remove_prefix "$1" "${separator}"
   r_remove_suffix "${RVAL}" "${separator}"
   r_remove_duplicate "${RVAL}" "${separator}"
}


#
# this is "cross-platform" because the paths on MINGW are converted to
# '/' already
#

# use for PATHs
r_colon_concat()
{
   r_concat "$1" "$2" ":"
   r_remove_ugly "${RVAL}" ":"
}

# use for lists w/o empty elements
r_comma_concat()
{
   r_concat "$1" "$2" ","
   r_remove_ugly "${RVAL}" ","
}

# use for CSV
r_semicolon_concat()
{
   r_concat "$1" "$2" ";"
   r_remove_suffix "${RVAL}" ";"
}

# use for filepaths
r_slash_concat()
{
   r_concat "$1" "$2" "/"
   r_remove_duplicate "${RVAL}" "/"
}


# use for building sentences, where space is a separator and
# not indenting or styling
r_space_concat()
{
   concat_no_double_separator "$1" "$2" | string_remove_ugly_separators
}


colon_concat()
{
   local RVAL

   r_colon_concat "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


# use for lists w/o empty elements
comma_concat()
{
   local RVAL

   r_comma_concat "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


# use for CSV
semicolon_concat()
{
   local RVAL

   r_semicolon_concat "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


# use for filepaths
slash_concat()
{
   local RVAL

   r_slash_concat "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


add_cmake_path_if_exists()
{
   local line="$1"
   local path="$2"

   if [ ! -e "${path}" ]
   then
      echo "${line}"
   else
      semicolon_concat "$@"
   fi
}


add_cmake_path()
{
   semicolon_concat "$@"
}


r_add_line()
{
   local lines="$1"
   local line="$2"

   if [ -z "${lines}" ]
   then
      RVAL="${line}"
   else
      if [ -z "${line}" ]
      then
         RVAL="${lines}"
      else
         RVAL="${lines}
${line}"
      fi
   fi
}


add_line()
{
   local RVAL

   r_add_line "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


r_add_unique_line()
{
   local lines="$1"
   local line="$2"

   if [ -z "${line}" ]
   then
      RVAL="${lines}"
      return
   fi

   if [ -z "${lines}" ]
   then
      RVAL="${line}"
      return
   fi

   if fgrep -x -q -e "${line}" <<< "${lines}"
   then
      RVAL="${lines}"
      return
   fi

   RVAL="${lines}
${line}"
}


r_add_unique_lines()
{
   local lines="$1"
   local addlines="$2"

   RVAL="${lines}"

   IFS="
"; set -f
   for line in ${addlines}
   do
      IFS="${DEFAULT_IFS}"; set +f

      r_add_unique_line "${RVAL}" "${line}"
   done
   IFS="${DEFAULT_IFS}"; set +f
}


#
# makes somewhat prettier filenames, removing superflous "."
# and trailing '/'
# DO NOT USE ON URLs
#
r_filepath_cleaned()
{
   local old

   RVAL="$1"
   [ -z "${RVAL}" ] && return
   old=''

   # remove excess //, also inside components
   while [ "${RVAL}" != "${old}" ]
   do
      old="${RVAL}"
      RVAL="${RVAL%/}"
      RVAL="${RVAL//\/\//\/}"
   done

   [ -z "${RVAL}" ] && RVAL="/"
}


filepath_cleaned()
{
   local RVAL

   r_filepath_cleaned "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


r_filepath_concat()
{
   local i
   local s
   local sep
   local fallback

   fallback=

   set -o noglob
   for i in "$@"
   do
      set +o noglob
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
               fallback="."
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
   set +o noglob

   if [ ! -z "${s}" ]
   then
      RVAL="${s}"
   else
      RVAL="${fallback}"
   fi
}


filepath_concat()
{
   local RVAL

   r_filepath_concat "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


# ####################################################################
#                            Strings
# ####################################################################
#
is_yes()
{
   local s

   case "$1" in
      [yY][eE][sS]|Y|1)
         return 0
      ;;
      [nN][oO]|[nN]|0|"")
         return 1
      ;;

      *)
         return 255
      ;;
   esac
}


# ####################################################################
#                            Escaping
# ####################################################################
#

escape_linefeeds()
{
   local text

   text="${text//\|/\\\|}"
   /bin/echo -n "${text}" | tr '\012' '|'
}


_unescape_linefeeds()
{
   tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
}


unescape_linefeeds()
{
   echo "$@" | tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
}


# this is heaps faster than the sed code
r_escaped_grep_pattern()
{
   local s="$1"

   s="${s//\\/\\\\}"
   s="${s//\[/\\[}"
   s="${s//\]/\\]}"
   s="${s//\//\\/}"
   s="${s//\$/\\$}"
   s="${s//\*/\\*}"
   s="${s//\./\\.}"
   s="${s//\^/\\^}"
   s="${s//\|/\\|}"

   RVAL="$s"
}


escaped_grep_pattern()
{
   local RVAL

   r_escaped_grep_pattern "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


r_escaped_sed_pattern()
{
   local s="$1"

   s="${s//\\/\\\\}"
   s="${s//\[/\\[}"
   s="${s//\]/\\]}"
   s="${s//\//\\/}"
   s="${s//\$/\\$}"
   s="${s//\*/\\*}"
   s="${s//\./\\.}"
   s="${s//\^/\\^}"

   RVAL="$s"
}


escaped_sed_pattern()
{
   local RVAL

   r_escaped_sed_pattern "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


r_escaped_spaces()
{
   RVAL="${1// /\\ }"
}


escaped_spaces()
{
   local RVAL

   r_escaped_spaces "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


r_escaped_doublequotes()
{
   RVAL="${1//\\/\\\\}"
}


escaped_doublequotes()
{
   local RVAL

   r_escaped_doublequotes "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}

# MEMO: use printf "%q" dot shell escaping
r_escaped_shellstring()
{
   printf -v RVAL '%q' "$1"
}


escaped_shellstring()
{
   local RVAL

   r_escaped_shellstring "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


# ####################################################################
#                          Prefix / Suffix
# ####################################################################
#
string_has_prefix()
{
  [ "${1#$2}" != "$1" ]
}


string_remove_prefix()
{
   echo "${1#$2}"
}


string_has_suffix()
{
  [ "${1%$2}" != "$1" ]
}


string_remove_suffix()
{
   echo "${1%$2}"
}


# ####################################################################
#                            Expansion
# ####################################################################
#
#
# expands ${LOGNAME} and ${LOGNAME:-foo} but does not use eval
#
expand_environment_variables()
{
    local string="$1"

    local key
    local value
    local prefix
    local suffix
    local next
    local rval=0

    key="`echo "${string}" | sed -n 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\2/p'`"
    if [ ! -z "${key}" ]
    then
       prefix="`sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\1/' <<< "${string}" `"
       suffix="`sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\3/' <<< "${string}" `"
       value="`eval echo \$\{${key}\}`"
       if [ -z "${value}" ]
       then
          rval=1
       fi

       next="${prefix}${value}${suffix}"
       if [ "${next}" != "${string}" ]
       then
          expand_environment_variables "${prefix}${value}${suffix}"
          if [ $? -eq 0 ]
          then
              return $rval
          fi
          return 1
       fi
    fi

    echo "${string}"
    return $rval
}


#
# it's in string because it doesn't do FS calls
# or use environment variables
#

# much faster than calling "basename"
r_fast_basename()
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


r_fast_dirname()
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

   last="${filename##*/}"
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


fast_basename()
{
   local RVAL

   r_fast_basename "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


fast_dirname()
{
   local RVAL

   r_fast_dirname "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"
}


# old function
_fast_basename()
{
   local RVAL

   r_fast_basename "$@"
   _component="${RVAL}"
}


# old function
_fast_dirname()
{
   local RVAL

   r_fast_dirname "$@"
   _directory="${RVAL}"
}


:

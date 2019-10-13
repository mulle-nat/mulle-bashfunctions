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

# no seperator
r_append()
{
   RVAL="${1}${2}"
}


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
   r_concat "$@"
   printf "%s\n" "$RVAL"
}


# https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
r_trim_whitespace()
{
   RVAL="$*"
   RVAL="${RVAL#"${RVAL%%[![:space:]]*}"}"
   RVAL="${RVAL%"${RVAL##*[![:space:]]}"}"
}


#
# works for a "common" set of separators
#
r_remove_ugly()
{
   local s="$1"
   local separator="${2:- }"

   local escaped
   local dualescaped
   local replacement

   printf -v escaped '%q' "${separator}"

   dualescaped="${escaped//\//\/\/}"
   replacement="${separator}"
   case "${separator}" in
      */*)
         replacement="${escaped}"
      ;;
   esac

   local old

   RVAL="${s}"
   old=''
   while [ "${RVAL}" != "${old}" ]
   do
      old="${RVAL}"
      RVAL="${RVAL##[${separator}]}"
      RVAL="${RVAL%%[${separator}]}"
      RVAL="${RVAL//${dualescaped}${dualescaped}/${replacement}}"
   done
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

# remove a value from a list
r_list_remove()
{
   local sep="${3:- }"

   RVAL="${sep}$1${sep}//${sep}$2${sep}/}"
   RVAL="${RVAL##${sep}}"
   RVAL="${RVAL%%${sep}}"
}


r_colon_remove()
{
   r_list_remove "$1" "$2" ":"
}


r_comma_remove()
{
   r_list_remove "$1" "$2" ","
}


# use for building sentences, where space is a separator and
# not indenting or styling
r_space_concat()
{
   concat_no_double_separator "$1" "$2" | string_remove_ugly_separators
}


colon_concat()
{
   r_colon_concat "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


# use for lists w/o empty elements
comma_concat()
{
   r_comma_concat "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


# use for CSV
semicolon_concat()
{
   r_semicolon_concat "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


# use for filepaths
slash_concat()
{
   r_slash_concat "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


add_cmake_path_if_exists()
{
   local line="$1"
   local path="$2"

   if [ ! -e "${path}" ]
   then
      printf "%s\n" "${line}"
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
   r_add_line "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


r_remove_line()
{
   local lines="$1"
   local search="$2"

   local line

   local delim

   RVAL=
   set -o noglob ; IFS=$'\n'
   for line in ${lines}
   do
      if [ "${line}" != "${search}" ]
      then
         RVAL="${RVAL}${delim}${line}"
         delim=$'\n'
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob
}


# can't have linefeeds as delimiter
find_item()
{
   local line="$1"
   local search="$2"
   local delimiter="${3:-,}"

   local clear

   shopt -q extglob
   clear=$?

   rval=1
   shopt -s extglob
   case "${delim}${line}${delim}" in
      *"${delim}${search}${delim}"*)
         rval=0
      ;;
   esac
   [ $clear -ne 0 ] && shopt -u extglob

   return $rval
}


#
# this is faster than calling fgrep externally
# this is faster than while read line <<< lines
# this is faster than for line in lines
#
find_line()
{
   local lines="$1"
   local search="$2"

   local escaped_lines
   local pattern
   local rval

# ensure leading and trailing linefeed for matching and $'' escaping
   printf -v escaped_lines "%q" "
${lines}
"

# add a linefeed here to get also $'' escaping
   printf -v pattern "%q%s" "${search}
"
   # remove $'
   pattern="${pattern:2}"
   # remove \n'
   pattern="${pattern%???}"

   local clear

   # keep extglob state
   shopt -q extglob
   clear=$?

   rval=1
   shopt -s extglob
   case "${escaped_lines}" in
      *"\\n${pattern}\\n"*)
         rval=0
      ;;
   esac
   [ $clear -ne 0 ] && shopt -u extglob

   return $rval
}


#
# this removes any previous occurrence, its very costly
#
r_add_unique_line()
{
   local lines="$1"
   local line="$2"

   if [ -z "${line}" -o -z "${lines}" ]
   then
      RVAL="${lines}${line}"
      return
   fi

   if find_line "${lines}" "${line}"
   then
      RVAL="${lines}"
      return
   fi

   RVAL="${lines}
${line}"
}


#
# for very many lines use
# `sed -n '1!G;h;$p' <<< "${lines}"`"
#
r_reverse_lines()
{
   local lines="$1"

   local line
   local delim

   RVAL=
   set -o noglob ; IFS=$'\n'
   for line in ${lines}
   do
      RVAL="${line}${delim}${RVAL}"
      delim=$'\n'
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob
}


#
# makes somewhat prettier filenames, removing superflous "."
# and trailing '/'
# DO NOT USE ON URLs
#
r_filepath_cleaned()
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

   [ -z "${RVAL}" ] && RVAL="${1:0:1}"
}


filepath_cleaned()
{
   r_filepath_cleaned "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
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
   set +o noglob

   if [ ! -z "${s}" ]
   then
      r_filepath_cleaned "${s}"
   else
      RVAL="${fallback:0:1}" # / make ./ . again
   fi
}


filepath_concat()
{
   r_filepath_concat "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


r_upper_firstchar()
{
   case "${BASH_VERSION}" in
      [0123]*)
         RVAL="`printf "${1:0:1}" | tr '[:lower:]' '[:upper:]'`"
         RVAL="${RVAL}${$1:1}"
      ;;

      *)
         RVAL="${1^}"
      ;;
   esac
}


r_capitalize()
{
   r_lowercase "$@"
   r_upper_firstchar "${RVAL}"
}



r_uppercase()
{
   case "${BASH_VERSION}" in
      [0123]*)
         RVAL="`printf "$1" | tr '[:lower:]' '[:upper:]'`"
      ;;

      *)
        RVAL="${1^^}"
      ;;
   esac
}


r_lowercase()
{
   case "${BASH_VERSION}" in
      [0123]*)
         RVAL="`printf "$1" | tr '[:upper:]' '[:lower:]'`"
      ;;

      *)
         RVAL="${1,,}"
      ;;
   esac
}


r_identifier()
{
   # works in bash 3.2
   RVAL="${1//[^a-zA-Z0-9]/_}"
   case "${RVAL}" in
      [0-9]*)
         RVAL="_${RVAL}"
      ;;
   esac
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
   printf "%s\n" "$@" | tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
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
   r_escaped_grep_pattern "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


# assumed that / is used like in sed -e 's/x/y/'
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


# assumed that / is used like in sed -e 's/x/y/'
r_escaped_sed_replacement()
{
   local s="$1"

   s="${s//\\/\\\\}"
   s="${s//\//\\/}"
   s="${s//&/\\&}"

   RVAL="$s"
}


escaped_sed_pattern()
{
   r_escaped_sed_pattern "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


r_escaped_spaces()
{
   RVAL="${1// /\\ }"
}


escaped_spaces()
{
   r_escaped_spaces "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


r_escaped_backslashes()
{
   RVAL="${1//\\/\\\\}"
}


escaped_backslashes()
{
   r_escaped_backslashes "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


r_escaped_singlequotes()
{
   local quote="'"

   RVAL="${*//${quote}/${quote}\"${quote}\"${quote}}"
}


r_escaped_doublequotes()
{
   RVAL="${*//\\/\\\\}"
   RVAL="${RVAL//\"/\\\"}"
}


r_escaped_shell_string()
{
   printf -v RVAL '%q' "$*"
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
   printf "%s\n" "${1#$2}"
}


string_has_suffix()
{
  [ "${1%$2}" != "$1" ]
}


string_remove_suffix()
{
   printf "%s\n" "${1%$2}"
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

    key="`printf "%s\n" "${string}" | sed -n 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\2/p'`"
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

    printf "%s\n" "${string}"
    return $rval
}


#
# it's in string because it doesn't do FS calls
# or use environment variables
#

# much faster than calling "basename"
r_basename()
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


# old name -> fast_basename -> r_fast_basename -> r_basename
r_fast_basename()
{
   r_basename "$@"
}


r_dirname()
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

r_fast_dirname()
{
   r_dirname "$@"
}


fast_basename()
{
   r_fast_basename "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


fast_dirname()
{
   r_fast_dirname "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


# old function
_fast_basename()
{
   r_fast_basename "$@"
   _component="${RVAL}"
}


# old function
_fast_dirname()
{
   r_fast_dirname "$@"
   _directory="${RVAL}"
}


:

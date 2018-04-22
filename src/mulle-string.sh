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
[ ! -z "${MULLE_STRING_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = "YES" ] && \
   echo "double inclusion of mulle-string.sh" >&2

MULLE_STRING_SH="included"


# ####################################################################
#                            Concatenation
# ####################################################################
#
concat()
{
   local separator="${3:- }"

   if [ -z "${1}" ]
   then
      echo "${2}"
   else
      if [ -z "${2}" ]
      then
         echo "${1}"
      else
         echo "${1}${separator}${2}"
      fi
   fi
}


_string_remove_leading_separators()
{
   local escaped="$1"

   sed "s/^${escaped}\(.*\)$/\1/g"
}



_string_remove_trailing_separators()
{
   local escaped="$1"

   sed -e "s/^\(.*\)${escaped}$/\1/g"
}



_string_remove_duplicate_separators()
{
   local escaped="$1"

   local previous
   local next

   next="`cat`"

   while [ ! -z "${next}" ]
   do
      previous="${next}"
      next="$(sed -e "s/${escaped}${escaped}/${escaped}/g" <<< "${previous}")"

      if [ "${next}" = "${previous}" ]
      then
         break
      fi
   done

   if [ ! -z "${next}" ]
   then
      echo "${next}"
   fi
}


_string_remove_only_separators()
{
   local escaped="$1"

   sed -e "/^${escaped}*$/d"
}


_string_remove_ugly_separators()
{
   local escaped="$1"

   # remove leading
   # remove doubles
   # remove duplicates
   # remove lonelys

   _string_remove_leading_separators "${escaped}"   | \
   _string_remove_trailing_separators "${escaped}"  | \
   _string_remove_duplicate_separators "${escaped}" | \
   _string_remove_only_separators "${escaped}"
}


string_remove_leading_separators()
{
   local separator="${1:- }"

   _string_remove_leading_separators "$(escaped_sed_pattern "${separator}")"
}


string_remove_trailing_separators()
{
   local separator="${1:- }"

   _string_remove_trailing_separators "$(escaped_sed_pattern "${separator}")"
}


string_remove_only_separators()
{
   local separator="${1:- }"

   _string_remove_only_separators "$(escaped_sed_pattern "${separator}")"
}


string_remove_duplicate_separators()
{
   local separator="${1:- }"

   _string_remove_duplicate_separators "$(escaped_sed_pattern "${separator}")"
}


string_remove_ugly_separators()
{
   local separator="${1:- }"

   _string_remove_ugly_separators "$(escaped_sed_pattern "${separator}")"
}


#
# this is "cross-platform" because the paths on MINGW are converted to
# '/' already
#

# use for PATHs
colon_concat()
{
   concat "$1" "$2" ":" | string_remove_ugly_separators ':'
}

# use for lists w/o empty elements
comma_concat()
{
   concat "$1" "$2" "," | string_remove_ugly_separators ","
}

# use for CSV
semicolon_concat()
{
   concat "$1" "$2" ";" | string_remove_trailing_separators ";"
}

# use for filepaths
slash_concat()
{
   concat "$1" "$2" "/" | string_remove_duplicate_separators "/"
}

# use for building sentences, where space is a separator and
# not indenting or styling
space_concat()
{
   concat_no_double_separator "$1" "$2" | string_remove_ugly_separators
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


add_line()
{
   local lines="$1"
   local line="$2"

   if [ -z "${lines}" ]
   then
      echo "${line}"
   else
      if [ -z "${line}" ]
      then
         echo "${lines}"
      else
         echo "${lines}
${line}"
      fi
   fi
}


inplace_sed()
{
   case "${MULLE_UNAME}" in
      darwin)
         exekutor sed -i '' "$@"
      ;;

      *)
         exekutor sed -i'' "$@"
      ;;
   esac
}

#
# makes somewhat prettier filenames, removing superflous "."
# and trailing '/'
# DO NOT USE ON URLs
#
filepath_cleaned()
{
   local filename="$1"

   # remove excess //, also inside components
   case "${filename}" in
      *"//"*)
         filename="`sed 's|//|/|g' <<< "${filename}"`"
      ;;
   esac

   # remove trailing /
   case "${filename}" in
      *"/")
         filename="`sed 's|\(.\)/$|\1|g' <<< "${filename}"`"
      ;;
   esac

   echo "${filename}"
}


filepath_concat()
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

      i="`filepath_cleaned "${i}" `"

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
      echo "${s}"
   else
      echo "${fallback}"
   fi
}

# ####################################################################
#                            Strings
# ####################################################################
#
is_yes()
{
   local s

   s=`echo "$1" | tr '[:lower:]' '[:upper:]'`
   case "${s}" in
      YES|Y|1)
         return 0
      ;;
      NO|N|0|"")
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

   text="`echo "$@" | sed -e 's/|/\\|/g'`"
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


escaped_grep_pattern()
{
   sed -e 's/[]\/$*.^|[]/\\&/g' <<< "${1}"
}


escaped_sed_pattern()
{
   # escaping the pipe is bad with sed
   sed -e 's/[]\/$*.^[]/\\&/g' <<< "${1}"
}


escaped_spaces()
{
   sed 's/ /\\ /g' <<< "${1}"
}


escaped_doublequotes()
{
   sed 's/"/\\"/g' <<< "${1}"
}

# for shell
escaped_singlequotes()
{
   sed "s/'/'\"'\"'/g" <<< "${1}"
}


# ####################################################################
#                          Prefix / Suffix
# ####################################################################
#
string_has_prefix()
{
  local string="$1"
  local prefix="$2"

  prefix="`escaped_grep_pattern "${prefix}"`"
  egrep -s -q "^${prefix}" <<< "${string}"
}


string_remove_prefix()
{
  local string="$1"
  local prefix="$2"

  prefix="`escaped_sed_pattern "${prefix}"`"
  sed -e "s/^${prefix}//" <<< "${string}"
}


string_has_suffix()
{
  local string="$1"
  local suffix="$2"

  suffix="`escaped_grep_pattern "${suffix}"`"
  egrep -s -q "${suffix}\$" <<< "${string}"
}


string_remove_suffix()
{
  local string="$1"
  local suffix="$2"

  suffix="`escaped_sed_pattern "${suffix}"`"
  sed -e -"s/${suffix}\$//" <<< "${string}"
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
       prefix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\1/'`"
       suffix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\3/'`"
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
_fast_basename()
{
   local filename="$1"

   while :
   do
      case "${filename}" in
         /)
           _component="/"
           return
         ;;

         */)
            filename="${filename%?}"
         ;;

         *)
            _component="${filename##*/}"
            return
         ;;
      esac
   done
}


_fast_dirname()
{
   local filename="$1"

   local last

   while :
   do
      case "${filename}" in
         /)
            _directory="${filename}"
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
   _directory="${filename%${last}}"

   while :
   do
      case "${_directory}" in
         /)
           return
         ;;

         */)
            _directory="${_directory%?}"
         ;;

         *)
            _directory="${_directory:-.}"
            return
         ;;
      esac
   done
}


fast_basename()
{
   local _component

   _fast_basename "$@"
   echo "${_component}"
}


fast_dirname()
{
   local _directory

   _fast_dirname "$@"
   echo "${_directory}"
}


:

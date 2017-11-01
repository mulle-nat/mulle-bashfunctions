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
[ ! -z "${MULLE_STRING_SH}" ] && echo "double inclusion of mulle-string.sh" >&2 && exit 1

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
      if [ -z "${2}" -o "${2}" = "${separator}" ]
      then
         echo "${1}"
      else
         echo "${1}${separator}${2}"
      fi
   fi
}

#
# this is "cross-platform" because the paths on MINGW are converted to
# '/' already
#
slash_concat()
{
   concat "$1" "$2" "/"
}


semicolon_concat()
{
   concat "$1" "$2" ";"
}


colon_concat()
{
   concat "$1" "$2" ":"
}


space_concat()
{
   concat "$1" "$2" " "
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


#
# makes somewhat prettier filenames, removing superflous "."
# and trailing '/'
#
filepath_concat()
{
   local i
   local s
   local sep

   for i in "$@"
   do
      sep="/"
      case "$i" in
         ""|"."|"./")
           continue
         ;;

         "/.")
           sep=""
           i=""
         ;;

         "/*")
            sep=""
         ;;

         "*/")
            i="`sed 's|/$||/g' <<< "$i"`"
         ;;
      esac

      if [ -z "${s}" ]
      then
         s="$i"
      else
         s="${s}/${i}"
      fi
   done

   echo "${s}"
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
         fail "$2 should contain YES or NO (or be empty)"
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


escaped_sed_pattern()
{
   sed -e 's/[]\/$*.^|[]/\\&/g' <<< "${1}"
}


# ####################################################################
#                            Expansion
# ####################################################################
#
#
# expands ${LOGNAME} and ${LOGNAME:-foo}
#
expand_environment_variables()
{
    local string="$1"

    local key
    local value
    local prefix
    local suffix
    local next

    key="`echo "${string}" | sed -n 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\2/p'`"
    if [ ! -z "${key}" ]
    then
       prefix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\1/'`"
       suffix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\3/'`"
       value="`eval echo \$\{${key}\}`"
       if [ -z "${value}" ]
       then
          log_verbose "${key} expanded to empty string ($1)"
       fi

       next="${prefix}${value}${suffix}"
       if [ "${next}" != "${string}" ]
       then
          expand_environment_variables "${prefix}${value}${suffix}"
          return
       fi
    fi

    echo "${string}"
}

:
#! /usr/bin/env bash
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
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
[ "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' -a ! -z "${MULLE_ARRAY_SH}" ] && \
   echo "double inclusion of mulle-array.sh" >&2

[ -z "${MULLE_LOGGING_SH}" ] && echo "mulle-logging.sh must be included before mulle-array.sh" 2>&1 && exit 1

MULLE_ARRAY_SH="included"


array_value_check()
{
   local value="$1"

   case "${value}" in
      *$'\n'*)
         internal_fail "\"${value}\" has unescaped linefeeds"
      ;;
   esac
}


#
# more specialed lines code, that's not even used anywhere I think
#
r_count_lines()
{
   local array="$1"

   RVAL=0

   local line

   set -o noglob ; IFS=$'\n'
   for line in ${array}
   do
      RVAL=$((RVAL + 1))
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob
}


r_get_line_at_index()
{
   local array="$1"
   local i="${2:-0}"

   # for larger arrays:    sed -n "${i}p" <<< "${array}"

   set -o noglob ; IFS=$'\n'
   for RVAL in ${array}
   do
      if [ $i -eq 0 ]
      then
         IFS="${DEFAULT_IFS}" ; set +o noglob
         return 0
      fi
      i=$((i - 1))
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob
   return 1
}


r_insert_line_at_index()
{
   local array="$1"
   local i="$2"
   local value="$3"

   array_value_check "${value}"

   local line
   local added='NO'
   local rval

   RVAL=
   rval=1

   set -o noglob ; IFS=$'\n'
   for line in ${array}
   do
      if [ $i -eq 0 ]
      then
         r_add_line "${RVAL}" "${value}"
         rval=0
      fi
      r_add_line "${RVAL}" "${line}"
      i=$((i - 1))
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   if [ $i -eq 0 ]
   then
      r_add_line "${RVAL}" "${value}"
      rval=0
   fi

   return $rval
}

#
# assoc array contents can contain any characters except newline
# assoc array keys should be identifiers
#
assoc_array_key_check()
{
   local key="$1"

   [ -z "${key}" ] && internal_fail "key is empty"

   local identifier

   r_identifier "${key}"
   identifier="${RVAL}"

   [ "${identifier}" != "${key}" -a "${identifier}" != "_${key}" ] && internal_fail "\"${key}\" has non-identifier characters"
}


assoc_array_value_check()
{
   array_value_check "$@"
}


_r_assoc_array_add()
{
   local array="$1"
   local key="$2"
   local value="$3"

   assoc_array_key_check "${key}"
   assoc_array_value_check "${value}"

# DEBUG code
#   key="`_assoc_array_key_check "$2"`"
#   value="`array_value_check "$3"`"

   r_add_line "${array}" "${key}=${value}"
}


_r_assoc_array_remove()
{
   local array="$1"
   local key="$2"

   local line
   local delim

   RVAL=
   set -o noglob ; IFS=$'\n'
   for line in ${array}
   do
      case "${line}" in
         "${key}="*)
         ;;

         *)
            RVAL="${line}${delim}${RVAL}"
            delim=$'\n'
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob
}


r_assoc_array_get()
{
   local array="$1"
   local key="$2"

# DEBUG code
#   key="`_assoc_array_key_check "${key}"`"

   local line
   local rval

   RVAL=
   rval=1
   set -o noglob ; IFS=$'\n'
   for line in ${array}
   do
      case "${line}" in
         "${key}="*)
            RVAL="${line#*=}"
            rval=0
            break
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   return $rval
}


assoc_array_all_keys()
{
   local array="$1"

   sed -n 's/^\([^=]*\)=.*$/\1/p' <<< "${array}"
}


assoc_array_all_values()
{
   local array="$1"

   sed -n 's/^[^=]*=\(.*\)$/\1/p' <<< "${array}"
}


r_assoc_array_set()
{
   local array="$1"
   local key="$2"
   local value="$3"

   if [ -z "${value}" ]
   then
      _r_assoc_array_remove "${array}" "${key}"
      return
   fi

   local old_value

   r_assoc_array_get "${array}" "${key}"
   old_value="${RVAL}"

   if [ ! -z "${old_value}" ]
   then
      _r_assoc_array_remove "${array}" "${key}"
      array="${RVAL}"
   fi

   _r_assoc_array_add "${array}" "${key}" "${value}"
}


#
# merge second array into first array
# meaning if key in second array exists it overwrites
# the value in the first array
#
assoc_array_merge_with_array()
{
   local array1="$1"
   local array2="$2"

   printf "%s\n" "${array2}" "${array1}" | sort -u -t'=' -k1,1
}


#
# add second array into first array
# meaning only keys in second array that don't exists in the
# first are added
#
assoc_array_augment_with_array()
{
   local array1="$1"
   local array2="$2"

   printf "%s\n" "${array1}" "${array2}" | sort -u -t'=' -k1,1
}

:

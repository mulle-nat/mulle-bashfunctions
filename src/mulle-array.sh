# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
##
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
if ! [ ${MULLE_ARRAY_SH+x} ]
then
MULLE_ARRAY_SH='included'

[ -z "${MULLE_LOGGING_SH}" ] && _fatal "mulle-logging.sh must be included before mulle-array.sh"


_array_value_check()
{
   local value="$1"

   case "${value}" in
      *$'\n'*)
         _internal_fail "\"${value}\" has unescaped linefeeds"
      ;;
   esac
}


#
# r_add_line_lf <array> <line>
#
#    Add a line to <array>. You can add empty lines.
#
function r_add_line_lf()
{
   local lines="$1"
   local line="$2"

   if [ -z "${lines:0:1}" ]
   then
      RVAL="${line}"
      return
   fi
   RVAL="${lines}"$'\n'"${line}"
}

#
# r_get_line_at_index <array> <index>
#
#    Retrieve a line from <array> at <index>
#
function r_get_line_at_index()
{
   local array="$1"
   local i="${2:-0}"

   # for larger arrays:    sed -n "${i}pq" <<< "${array}"

   .foreachline RVAL in ${array}
   .do
      if [ $i -eq 0 ]
      then
         return 0
      fi
      i=$((i - 1))
   .done
   return 1
}


#
# r_insert_line_at_index <array> <index> <line>
#
#    Insert a <line> into <array> at <index>
#
function r_insert_line_at_index()
{
   local array="$1"
   local i="$2"
   local value="$3"

   _array_value_check "${value}"

   local line
   local rval

   RVAL=
   rval=1

   .foreachline line in ${array}
   .do
      if [ $i -eq 0 ]
      then
         r_add_line "${RVAL}" "${value}"
         rval=0
      fi
      r_add_line "${RVAL}" "${line}"
      i=$((i - 1))
   .done

   if [ $i -eq 0 ]
   then
      r_add_line "${RVAL}" "${value}"
      rval=0
   fi

   return $rval
}


#
# r_lines_in_range <array> <index> <count>
#
#     Return <count> lines in <array> starting at <index>
#
function r_lines_in_range()
{
   local array="$1"
   local i="$2"
   local n="$3"

   # this is not really faster for smaller arrays
   declare -a bash_array
   declare -a res_array

   IFS=$'\n' read -r -d '' -a bash_array <<< "${array}"

   local j
   local sentinel

   sentinel=$((i + n))

   j=0
   while [ $i -lt ${sentinel} ]
   do
      res_array[${j}]="${bash_array[${i}]}"
      i=$((i + 1))
      j=$((j + 1))
   done

   RVAL="${res_array[*]}"
}


#r_replace_lines_in_range()
#{
#   local array="$1"
#   local i="$2"
#   local j="$3"
#   local replacement="$4"
#
#   [ ${i} -gt ${j} ] && _internal_fail "i greater than j"
#
#   local line
#   local index
#   local result
#
#   shell_disable_glob; IFS=$'\n'
#   index=0
#   for line in ${array}
#   do
#      if [ ${index} -ge ${i} -a ${index} -le ${j} ]
#      then
#         if [ ${index} -eq ${i} ]
#         then
#            r_add_line "${result}" "${replacement}"
#            result="${RVAL}"
#         fi
#         continue
#      fi
#
#      index=$((index + 1))
#
#      r_add_line "${result}" "${line}"
#      result="${RVAL}"
#   done
#
#   IFS="${DEFAULT_IFS}" ; shell_enable_glob
#
#   [ ${i} -ge ${index} ] && _internal_fail "i $i invalid"
#   [ ${j} -ge ${index} ] && _internal_fail "j $j invalid"
#
#   RVAL="${result}"
#}


#
# assoc array contents can contain any characters except newline
# assoc array keys should be identifiers
#
_assoc_array_key_check()
{
   local key="$1"

   [ -z "${key}" ] && _internal_fail "key is empty"

   local identifier

   r_identifier "${key}"
   identifier="${RVAL}"

   [ "${identifier}" != "${key}" -a "${identifier}" != "_${key}" ] && _internal_fail "\"${key}\" has non-identifier characters"
}


_assoc_array_value_check()
{
   _array_value_check "$@"
}


_r_assoc_array_add()
{
   local array="$1"
   local key="$2"
   local value="$3"

   _assoc_array_key_check "${key}"
   _assoc_array_value_check "${value}"

# DEBUG code
#   key="`_assoc_array_key_check "$2"`"
#   value="`_array_value_check "$3"`"

   r_add_line "${array}" "${key}=${value}"
}


_r_assoc_array_remove()
{
   local array="$1"
   local key="$2"

   local line
   local delim

   delim=""
   RVAL=

   .foreachline line in ${array}
   .do
      case "${line}" in
         "${key}="*)
         ;;

         *)
            RVAL="${line}${delim}${RVAL}"
            delim=$'\n'
         ;;
      esac
   .done
}


#
# r_assoc_array_get <array> <key>
#
#    Retrieve value for <key> stored in <array>.
#
function r_assoc_array_get()
{
   local array="$1"
   local key="$2"

# DEBUG code
#   key="`_assoc_array_key_check "${key}"`"

   local line
   local rval

   RVAL=
   rval=1

   .foreachline line in ${array}
   .do
      case "${line}" in
         "${key}="*)
            RVAL="${line#*=}"
            rval=0
            .break
         ;;
      esac
   .done

   return $rval
}


#
# assoc_array_all_keys <array>
#
#    Output to stdout all keys stored in <array>.
#
function assoc_array_all_keys()
{
   local array="$1"

   sed -n 's/^\([^=]*\)=.*$/\1/p' <<< "${array}"
}


#
# assoc_array_all_values <array>
#
#    Output to stdout all values contained in <array>.
#
function assoc_array_all_values()
{
   local array="$1"

   sed -n 's/^[^=]*=\(.*\)$/\1/p' <<< "${array}"
}


#
# r_assoc_array_set <array> <key> <value>
#
#    Set <value> for <key> in <array>
#
function r_assoc_array_set()
{
   local array="$1"
   local key="$2"
   local value="${3:-}"

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
# assoc_array_merge_with_array <array1> <array2>
#
#    Merge second array into first array
#    meaning if key in second array exists it overwrites
#    the value in the first array.
#    The result is printed to stdout.
#
function assoc_array_merge_with_array()
{
   local array1="$1"
   local array2="$2"

   printf "%s%s\n" "${array2}" "${array1}" | sort -u -t'=' -k1,1
}


#
# assoc_array_augment_with_array <array1> <array2>
#
#    Add second array into first array.
#    Meaning only keys in second array that don't exists in the
#    first are added.
#    The result is printed to stdout.
#
function assoc_array_augment_with_array()
{
   local array1="$1"
   local array2="$2"

   printf "%s%s\n" "${array1}" "${array2}" | sort -u -t'=' -k1,1
}

fi
:


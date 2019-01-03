#! /usr/bin/env bash
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
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
[ ! -z "${MULLE_LEGACY_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-legacy.sh" >&2

[ -z "${MULLE_FILE_SH}" ] && echo "mulle-file.sh must be included before mulle-legacy.sh" 2>&1 && exit 1


MULLE_LEGACY_SH="included"


#
# functions used by mulle-bootstrap but really too specialiced to be in
# mulle-bash functions
#


prepend_to_search_path_if_missing()
{
   local fullpath="$1"; shift

   local new_path
   local tail_path
   local binpath

   tail_path=''
   new_path=''

   local oldifs
   local i

   oldifs="$IFS"
   IFS=":"

   set -o noglob
   for i in $fullpath
   do
      IFS="${oldifs}"
      set +o noglob

      # shims stay in front (homebrew)
      case "$i" in
         */shims/*)
            r_slash_concat "${new_path}" "$i"
            new_path="${RVAL}"
         ;;
      esac
   done
   set +o noglob

   #
   #
   #
   while [ $# -gt 0 ]
   do
      binpath="$1"
      shift

      r_simplified_absolutepath "${binpath}"
      binpath="${RVAL}"

      IFS=":"
      set -o noglob

      for i in $fullpath
      do
         IFS="${oldifs}"
         set +o noglob

         # don't duplicate if already in there
         case "$i" in
           "${binpath}/"|"${binpath}")
               binpath=''
               break
         esac
      done

      IFS="${oldifs}"
      set +o noglob

      if [ -z "${binpath}" ]
      then
         continue
      fi

      r_slash_concat "${tail_path}" "${binpath}"
      tail_path="${RVAL}"
   done

   IFS=":"
   set -o noglob

   for i in $fullpath
   do
      IFS="${oldifs}"
      set +o noglob

      # shims stay in front (homebrew)
      case "$i" in
         */shims/*)
            continue;
         ;;

         *)
            r_slash_concat "${tail_path}" "${i}"
            tail_path="${RVAL}"
         ;;
      esac
   done

   IFS="${oldifs}"
   set +o noglob

   slash_concat "${new_path}" "${tail_path}"
}



combined_escaped_search_path_if_exists()
{
   local i
   local combinedpath
   set -o noglob
   for i in "$@"
   do
      set +o noglob
      if [ ! -z "${i}" ]
      then
         r_escaped_spaces "$i"
         i="${RVAL}"
         if [ -e "${i}" ]
         then
            if [ -z "$combinedpath" ]
            then
               combinedpath="${i}"
            else
               combinedpath="${combinedpath} ${i}"
            fi
         fi
      fi
   done
   set +o noglob

   echo "${combinedpath}"
}


combined_escaped_search_path()
{
   local i
   local combinedpath
   set -o noglob
   for i in "$@"
   do
      set +o noglob
      if [ ! -z "${i}" ]
      then
         r_escaped_spaces "$i"
         i="${RVAL}"
         if [ -z "$combinedpath" ]
         then
            combinedpath="${i}"
         else
            combinedpath="${combinedpath} ${i}"
         fi
      fi
   done
   set +o noglob

   echo "${combinedpath}"
}



remove_absolute_path_prefix_up_to()
{
   local s="$1"
   local prefix="$2"

   r_fast_basename "${s}"
   if [ "${RVAL}" = "${prefix}" ]
   then
      return 0
   fi

   r_escaped_sed_pattern "${prefix}"
   prefix="${RVAL}"

   echo "${s}" | sed "s|^.*/${prefix}/\(.*\)*|\1|g"
}


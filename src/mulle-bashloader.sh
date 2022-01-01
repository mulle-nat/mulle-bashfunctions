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

# double inclusion of this file is OK!
if [ -z "${MULLE_BASHLOADER_SH}" ]
then
   MULLE_BASHLOADER_SH="included"

   r_uppercase()
   {
      case "${BASH_VERSION}" in
         [0123]*)
            RVAL="`printf "$1" | tr '[:lower:]' '[:upper:]'`"
         ;;

         *)
            if [ ! -z "${ZSH_VERSION}" ]
            then
               RVAL="${1:u}"
            else
               RVAL="${1^^}"
            fi
         ;;
      esac
   }


   include_executable_library()
   {
      local executable="$1"
      local header_define="$2"
      local libexec_define="$3"
      local filename="$4"

      if [ ! -z "${!header_define}" ]
      then
         return
      fi

      if [ -z "${!libexec_define}" ]
      then
         printf -v "${libexec_define}" "%s" "`"${executable}" libexec-dir`" || exit 1
         eval export "${libexec_define}"
      fi

      . "${!libexec_define}/${filename}" || exit 1
   }


   #  use <tool>::<name> scheme
   include_library()
   {
      local s="$1"

      local name
      local tool

      name="${s##*::}"
      if [ "${name}" != "${s}" ]
      then
         tool="${s%::*}"
      fi

      local upper_name

      r_uppercase "${name}"
      upper_name="${RVAL}"

      if [ -z "${tool}" ]
      then
         include_executable_library "mulle-bashfunctions-env" \
                                    "MULLE_${upper_name}_SH" \
                                    "MULLE_BASHFUNCTIONS_LIBEXEC_DIR" \
                                    "mulle-${name}.sh"
         return $?
      fi

      local upper_tool

      r_uppercase "${tool}"
      upper_tool="${RVAL}"

      local suffix

      suffix=""
      if [ "${use_env}" = 'YES' ]
      then
         suffix="-env"
      fi

      include_executable_library "mulle-${tool}${suffix}" \
                                 "MULLE_${upper_tool}_${upper_name}_SH" \
                                 "MULLE_${upper_tool}_LIBEXEC_DIR" \
                                 "mulle-${tool}-${name}.sh"
   }


   include_library_env()
   {
      include_library "$1" "YES"
   }


   __bashfunctions_loader()
   {
      # not sure about this
      if [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" -a ! -z "$0" ]
      then
         local tmp

         tmp="${0%/*}"
         if [  -f "${tmp}/mulle-bashfunctions.sh" ]
         then
            MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${tmp}"
         fi
      fi

      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] \
         && echo "MULLE_BASHFUNCTIONS_LIBEXEC_DIR not set" >&2 \
         && exit 1
      :
   }

   __bashfunctions_loader || exit 1
fi

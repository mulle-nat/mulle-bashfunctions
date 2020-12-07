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

# double inclusion of the main header file is OK!
if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
then
   MULLE_BASHFUNCTIONS_SH="included"

   __bashfunctions_loader()
   {

      if [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" -a ! -z "$0" ]
      then
         local tmp

         tmp="${0%/*}"
         if [  -f "${tmp}/mulle-bashfunctions.sh" ]
         then
            MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${tmp}"
         fi
      fi

      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && echo "MULLE_BASHFUNCTIONS_LIBEXEC_DIR not set" && exit 1

      if [ -z "${MULLE_LOGGING_SH}" ]
      then
         # shellcheck source=mulle-logging.sh
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-logging.sh"   || return 1
      fi
      if [ -z "${MULLE_EXEKUTOR_SH}" ]
      then
         # shellcheck source=mulle-exekutor.sh
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-exekutor.sh"  || return 1
      fi
      if [ -z "${MULLE_STRING_SH}" ]
      then
         # shellcheck source=mulle-string.sh
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-string.sh"    || return 1
      fi
      if [ -z "${MULLE_INIT_SH}" ]
      then
         # shellcheck source=mulle-init.sh
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-init.sh"   || return 1
      fi
      if [ -z "${MULLE_OPTIONS_SH}" ]
      then
         # shellcheck source=mulle-options.sh
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-options.sh"   || return 1
      fi

      #
      # These are not so often used, so increase speed. One
      # can turn them off using "minimal". '' is the default
      #
      case "$1" in
         minimal)
         ;;

         *)
            if [ -z "${MULLE_PATH_SH}" ]
            then
               # shellcheck source=mulle-path.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"      || return 1
            fi
            if [ -z "${MULLE_FILE_SH}" ]
            then
               # shellcheck source=mulle-file.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"      || return 1
            fi
         ;;
      esac

      case "$1" in
         'all')
            if [ -z "${MULLE_ARRAY_SH}" ]
            then
               # shellcheck source=mulle-array.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh"     || return 1
            fi
            if [ -z "${MULLE_VERSION_SH}" ]
            then
               # shellcheck source=mulle-version.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-version.sh"   || return 1
            fi
            if [ -z "${MULLE_CASE_SH}" ]
            then
               # shellcheck source=mulle-case.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"      || return 1
            fi
            if [ -z "${MULLE_PARALLEL_SH}" ]
            then
               # shellcheck source=mulle-parallel.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-parallel.sh"      || return 1
            fi
      esac
   }

   __bashfunctions_loader "$@" || exit 1
fi

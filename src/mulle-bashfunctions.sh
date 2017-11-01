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
[ ! -z "${MULLE_BASHFUNCTIONS_SH}" ] && echo "double inclusion of mulle-bashfunctions.sh" >&2 && exit 1

MULLE_BASHFUNCTIONS_SH="included"


__bashfunctions_loader()
{
   local tmp

   if [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" -a ! -z "$0" ]
   then
      tmp="`dirname -- "$0"`"
      if [  -f "${tmp}/mulle-array.sh" ]
      then
         MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${tmp}"
      fi
   fi

   [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && echo "MULLE_BASHFUNCTIONS_LIBEXEC_DIR not set" && exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-string.sh" &&
   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-logging.sh" &&
   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-exekutor.sh" &&
   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-options.sh" &&
   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" &&
   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-functions.sh" &&
   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-snip.sh"
}


__bashfunctions_loader "$@"

#! /usr/bin/env bash
#
#   Copyright (c) 2018-2021 Nat! - Mulle kybernetiK
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
if [ -z "${MULLE_BASHGLOBAL_SH}" ]
then
   MULLE_BASHGLOBAL_SH="included"

   DEFAULT_IFS="${IFS}" # as early as possible

   if [ ! -z "${ZSH_VERSION}" ]
   then
     setopt sh_word_split
     setopt POSIX_ARGZERO
   fi

   # this generally should be set by the main script
   # and not here, but if it isn't set then set it
   if [ -z "${MULLE_EXECUTABLE}" ]
   then
      # this actually works fairly well... We want to handle a lot of weird
      # situations, like only this file being sourced in. The main file being
      # sourced in or executed. Should run with zsh and bash...
      #
      MULLE_EXECUTABLE="${BASH_SOURCE[0]:-${(%):-%x}}"
      case "${MULLE_EXECUTABLE##*/}" in 
         mulle-bash*.sh)
            MULLE_EXECUTABLE="$0"
         ;;
      esac
   fi

   case "${MULLE_EXECUTABLE##*/}" in 
      mulle-bash*.sh)
         echo "MULLE_EXECUTABLE fail" >&2
         exit 1
      ;;
   esac

   # MULLE_EXECUTABLE_BIN_DIR="${MULLE_EXECUTABLE%/*}"

   # can be convenient to overload by caller sometimes
   if [ -z "${MULLE_EXECUTABLE_NAME}" ]
   then
      MULLE_EXECUTABLE_NAME="${MULLE_EXECUTABLE##*/}"
   fi

   #
   # this is useful for shortening filenames for output
   # like printf "%s\n" "${filename#${MULLE_USER_PWD}/}"
   #
   if [ -z "${MULLE_USER_PWD}" ]
   then
      MULLE_USER_PWD="${PWD}"
      export MULLE_USER_PWD
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME:-${MULLE_EXECUTABLE_NAME}}"

   MULLE_EXECUTABLE_PWD="${PWD}"
   MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE_NAME}"
   MULLE_EXECUTABLE_PID="$$"

   #
   # need this for scripts also
   #
   if [ -z "${MULLE_UNAME}" ]
   then
      case "${BASH_VERSION}" in
         [0123]*)
            MULLE_UNAME="`uname | tr '[:upper:]' '[:lower:]'`"
         ;;

         *)
            MULLE_UNAME="`uname`"
            if [ ! -z "${ZSH_VERSION}" ]
            then
               MULLE_UNAME="${MULLE_UNAME:l}"
            else
               MULLE_UNAME="${MULLE_UNAME,,}"
            fi
         ;;
      esac
      MULLE_UNAME="${MULLE_UNAME%%_*}"
      MULLE_UNAME="${MULLE_UNAME%[36][24]}" # remove 32 64 (hax)

      if [ "${MULLE_UNAME}" = "linux" ]
      then
         # check for WSL (Windows) we want this to be Windows then
         # abuse DEFAULT_IFS as tmp variable to lessen global var pollution
         read -r DEFAULT_IFS < /proc/sys/kernel/osrelease
         case "${DEFAULT_IFS}" in
            *-Microsoft)
               MULLE_UNAME="windows"
               MULLE_EXE_EXTENSION=".exe"
            ;;
         esac
      fi
   fi


   #
   # Tip: you can change the hostname to "travis-ci" via Travis settings
   #      Set MULLE_HOSTNAME to "travis-ci" there. Then you can load travis
   #      specific settings using host domain environment variables.
   #
   #      mulle-env environment --hostname-travis-ci set FOO "VfL Bochum"
   #
   if [ -z "${MULLE_HOSTNAME}" ]
   then
      case "${MULLE_UNAME}" in
         'mingw'*)
            MULLE_HOSTNAME="`hostname`"
         ;;

         *)
            MULLE_HOSTNAME="`hostname -s`"
         ;;
      esac

      case "${MULLE_HOSTNAME}" in
         \.*)
            MULLE_HOSTNAME="_${MULLE_HOSTNAME}"
         ;;
      esac
   fi

   # acquire some sort of username, its not super important
   # just be consistent
   if [ -z "${MULLE_USERNAME}" ]
   then
      MULLE_USERNAME="${MULLE_USERNAME:-${USERNAME}}" # mingw
      MULLE_USERNAME="${MULLE_USERNAME:-${USER}}"
      MULLE_USERNAME="${MULLE_USERNAME:-${LOGNAME}}"
      MULLE_USERNAME="${MULLE_USERNAME:-`id -nu 2> /dev/null`}"
      MULLE_USERNAME="${MULLE_USERNAME:-cptnemo}"
   fi
fi
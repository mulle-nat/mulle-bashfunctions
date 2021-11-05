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
      if [ "${MULLE_EXECUTABLE##*/}" = "mulle-bashfunctions.sh" ]
      then
         MULLE_EXECUTABLE="$0"
      fi
   fi

   if [ "${MULLE_EXECUTABLE##*/}" = "mulle-bashfunctions.sh" ]
   then
      echo "MULLE_EXECUTABLE fail" >&2
      exit 1
   fi

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

   DEFAULT_IFS="${IFS}" # as early as possible

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
         && echo "MULLE_BASHFUNCTIONS_LIBEXEC_DIR not set" && exit 1

      if [ -z "${MULLE_COMPATIBILITY_SH}" ]
      then
         # shellcheck source=mulle-compatibility.sh
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-compatibility.sh" || return 1
      fi

      case "$1" in
         'none')
         ;;

         ""|*)
            if [ -z "${MULLE_LOGGING_SH}" ]
            then
               # shellcheck source=mulle-logging.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-logging.sh"  || return 1
            fi
            if [ -z "${MULLE_EXEKUTOR_SH}" ]
            then
               # shellcheck source=mulle-exekutor.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-exekutor.sh" || return 1
            fi
            if [ -z "${MULLE_STRING_SH}" ]
            then
               # shellcheck source=mulle-string.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-string.sh"   || return 1
            fi
            if [ -z "${MULLE_INIT_SH}" ]
            then
               # shellcheck source=mulle-init.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-init.sh"     || return 1
            fi
            if [ -z "${MULLE_OPTIONS_SH}" ]
            then
               # shellcheck source=mulle-options.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-options.sh"  || return 1
            fi
         ;;
      esac
      #
      # These are not so often used, so increase speed. One
      # can turn them off using "minimal". '' is the default
      #
      case "$1" in
         'none'|'minimal')
         ;;

         ""|*)
            if [ -z "${MULLE_PATH_SH}" ]
            then
               # shellcheck source=mulle-path.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
            fi
            if [ -z "${MULLE_FILE_SH}" ]
            then
               # shellcheck source=mulle-file.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
            fi
         ;;
      esac

      case "$1" in
         'all')
            if [ -z "${MULLE_ARRAY_SH}" ]
            then
               # shellcheck source=mulle-array.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh"    || return 1
            fi
            if [ -z "${MULLE_CASE_SH}" ]
            then
               # shellcheck source=mulle-case.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"     || return 1
            fi
            if [ -z "${MULLE_ETC_SH}" ]
            then
               # shellcheck source=mulle-etc.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-etc.sh"      || return 1
            fi
            if [ -z "${MULLE_PARALLEL_SH}" ]
            then
               # shellcheck source=mulle-parallel.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-parallel.sh" || return 1
            fi
            if [ -z "${MULLE_VERSION_SH}" ]
            then
               # shellcheck source=mulle-version.sh
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-version.sh"  || return 1
            fi
      esac
   }

   __bashfunctions_loader "$@" || exit 1
fi
#! /usr/bin/env bash
#
#   Copyright (c) 2021 Nat! - Mulle kybernetiK
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
[ ! -z "${MULLE_COMPATIBILITY_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-compatibility.sh" >&2

MULLE_COMPATIBILITY_SH="included"


shell_enable_pipefail()
{
   set -o pipefail
}


shell_disable_pipefail()
{
   set +o pipefail
}


shell_is_pipefail_enabled()
{
   case "$-" in
      *f*)
         return 1
      ;;
   esac
   return 0
}



shell_enable_extglob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      setopt kshglob
      setopt bareglobqual
   else
      shopt -s extglob
   fi
}


shell_disable_extglob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      unsetopt bareglobqual
      unsetopt kshglob
   else
      shopt -u extglob
   fi
}


shell_is_extglob_enabled()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      [[ -o kshglob ]]
      return $?
   fi

   shopt -q extglob
}


shell_enable_nullglob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      setopt nullglob
   else
      shopt -s nullglob
   fi
}


shell_disable_nullglob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      unsetopt nullglob
   else
      shopt -u nullglob
   fi
}


shell_is_nullglob_enabled()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      [[ -o nullglob ]]
      return $?
   fi
   shopt -q nullglob
}


shell_enable_glob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      unsetopt noglob
   else
      set +f
   fi
}


shell_disable_glob()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      setopt noglob
   else
      set -f
   fi
}


shell_is_glob_enabled()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      if [[ -o noglob ]]
      then
         return 1
      fi
      return 0
   fi

   case "$-" in
      *f*)
         return 1
      ;;
   esac
   return 0
}


shell_is_function()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      case "`type "$1" `" in
         *function*)
            return 0
         ;;
      esac
      return 1
   fi

   [ "`type -t "$1"`" = "function" ]
   return $?
}


#
# extglob is enabled by default now. I see no real downside
# noglob would be another good default for scripting, but that's possibly
# a bit too surprising
#
shell_enable_extglob


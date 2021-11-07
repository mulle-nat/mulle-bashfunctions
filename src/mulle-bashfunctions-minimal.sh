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

#! /usr/bin/env bash
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
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
[ ! -z "${MULLE_LOGGING_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-logging.sh" >&2

MULLE_LOGGING_SH="included"


log_printf()
{
   local format="$1" ; shift

# convenient place to check something that shouldn't happen
#   [ "$__FAIL__" != 'YES' -a ! -w /tmp/vfl/.mulle/etc/sourcetree/config -a -e /tmp/vfl/.mulle/etc/sourcetree/config ] && __FAIL__="YES" && internal_fail "fail"

   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
   then
      printf "${format}" "$@" >&2
   else
      printf "${format}" "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
   fi
}


MULLE_LOG_ERROR_PREFIX=" error: "

log_error()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX}${MULLE_LOG_ERROR_PREFIX}${C_ERROR_TEXT}%b${C_RESET}\n" "$*"
}


MULLE_LOG_FAIL_ERROR_PREFIX=" fatal error: "

log_fail()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX}${MULLE_LOG_FAIL_ERROR_PREFIX}${C_ERROR_TEXT}%b${C_RESET}\n" "$*"
}


#
# don't prefix with warning: just let the colors speak
# errors are errors though
#
log_warning()
{
   if [ "${MULLE_FLAG_LOG_TERSE}" != 'YES' ]
   then
      log_printf "${C_WARNING}%b${C_RESET}\n" "$*"
   fi
}


log_info()
{
   if [ "${MULLE_FLAG_LOG_TERSE}" != 'YES' ]
   then
      log_printf "${C_INFO}%b${C_RESET}\n" "$*"
   fi
}


log_verbose()
{
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      log_printf "${C_VERBOSE}%b${C_RESET}\n" "$*"
   fi
}


log_fluff()
{
   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      log_printf "${C_FLUFF}%b${C_RESET}\n" "$*"
   else
      # fluff should be shown when debug is on but not fluff
      log_debug "$@"
   fi
}


# setting is like fluff but different color scheme
log_setting()
{
   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      log_printf "${C_SETTING}%b${C_RESET}\n" "$*"
   fi
}


# for debugging, not for user. same as fluff
log_debug()
{
   if [ "${MULLE_FLAG_LOG_DEBUG}" != 'YES' ]
   then
      return
   fi

   case "${MULLE_UNAME}" in
      linux)
         log_printf "${C_DEBUG}$(date "+%s.%N") %b${C_RESET}\n" "$*"
      ;;
      *)
         log_printf "${C_DEBUG}$(date "+%s") %b${C_RESET}\n" "$*"
      ;;
   esac
}


log_entry()
{
   if [ "${MULLE_FLAG_LOG_DEBUG}" != 'YES' ]
   then
      return
   fi

   local functionname="$1" ; shift

   local args

   if [ $# -ne 0 ]
   then
      args="'$1'"
      shift
   fi

   while [ $# -ne 0 ]
   do
      args="${args}, '$1'"
      shift
   done

   log_debug "${functionname} ${args}"
}


log_trace()
{
   case "${MULLE_UNAME}" in
      linux)
         log_printf "${C_TRACE}$(date "+%s.%N") %b${C_RESET}\n" "$*"
         ;;

      *)
         log_printf "${C_TRACE}$(date "+%s") %b${C_RESET}\n" "$*"
      ;;
   esac
}


log_trace2()
{
   case "${MULLE_UNAME}" in
      linux)
         log_printf "${C_TRACE2}$(date "+%s.%N") %b${C_RESET}\n" "$*"
         ;;

      *)
         log_printf "${C_TRACE2}$(date "+%s") %b${C_RESET}\n" "$*"
      ;;
   esac
}


#
# some common fail log functions
# caller failed on me in some bizarre fashion once
# 8: #762 /home/src/srcM/MulleEOF/MulleEOUtil/.mulle/var/.env/bin/mulle-sourcetree mulle-sourcetree
# 9: #
# 10: #
# 11: #
# 12: #


if [ -z "${BASH_VERSION}" ]
then
   # inspired by https://unix.stackexchange.com/questions/453144/functions-calling-context-in-zsh-equivalent-of-bash-caller
   function caller()
   {
      local i="${1:-1}"

      i=$((i+1))
      local file=${funcfiletrace[$((i))]%:*}
      local line line=${funcfiletrace[$((i))]##*:}
      local func=${funcstack[$((i + 1))]}
      if [ -z "${func## }" ]
      then
         return 1
      fi

      printf "%s %s %s\n" "$line" "$func" "${file##*/}"
      return 0
   }
fi


stacktrace()
{
   local i=1
   local line
   local max

   # don't stack trace when tracing
   case "$-" in
      *x*)
         return
      ;;
   esac

   max=100
   while line="`caller $i`"
   do
      log_printf "${C_CYAN}%b${C_RESET}\n" "$i: #${line}"
      i=$((i + 1))
      [ $i -gt $max ] && break
   done
}


fail()
{
   if [ ! -z "$*" ]
   then
      log_fail "$*"
   fi

   if [ "${MULLE_FLAG_LOG_DEBUG}" = 'YES' ]
   then
      stacktrace
   fi

   exit 1
}


MULLE_INTERNAL_ERROR_PREFIX=" *** internal error ***:"


internal_fail()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX}${MULLE_INTERNAL_ERROR_PREFIX}${C_ERROR_TEXT}%b${C_RESET}\n" "$*"
   stacktrace
   exit 1
}


# Escape sequence and resets, should use tput here instead of ANSI
logging_reset()
{
   printf "${C_RESET}" >&2
}


logging_trap_install()
{
   trap 'logging_reset ; exit 1' TERM INT
}


logging_initialize_color()
{
   # https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
   # https://www.systutorials.com/241795/how-to-judge-whether-its-stderr-is-redirected-to-a-file-in-a-bash-script-on-linux/
   # do not colorize when /dev/stderr is redirected
   # https://no-color.org/

   # fix for Xcode
   case "${TERM}" in
      dumb)
         MULLE_NO_COLOR=YES
      ;;
   esac

   if [ -z "${NO_COLOR}" -a "${MULLE_NO_COLOR}" != 'YES' ] && [ ! -f /dev/stderr ]
   then
      C_RESET="\033[0m"

      # Useable Foreground colours, for black/white white/black
      C_RED="\033[0;31m"     C_GREEN="\033[0;32m"
      C_BLUE="\033[0;34m"    C_MAGENTA="\033[0;35m"
      C_CYAN="\033[0;36m"

      C_BR_RED="\033[0;91m"
      C_BOLD="\033[1m"
      C_FAINT="\033[2m"
      C_SPECIAL_BLUE="\033[38;5;39;40m"

      if [ "${MULLE_LOGGING_TRAP}" != 'NO' ]
      then
         logging_trap_install
      fi
   fi

   C_RESET_BOLD="${C_RESET}${C_BOLD}"

   C_ERROR="${C_BR_RED}${C_BOLD}"
   C_WARNING="${C_RED}${C_BOLD}"
   C_INFO="${C_CYAN}${C_BOLD}"
   C_VERBOSE="${C_GREEN}${C_BOLD}"
   C_FLUFF="${C_GREEN}${C_BOLD}"
   C_SETTING="${C_GREEN}${C_FAINT}"
   C_TRACE="${C_FLUFF}${C_FAINT}"
   C_TRACE2="${C_RESET}${C_FAINT}"
   C_DEBUG="${C_SPECIAL_BLUE}"

   C_ERROR_TEXT="${C_RESET}${C_BR_RED}${C_BOLD}"
}


_r_lowercase()
{
   # ksh bails on ,, during parse
   case "${BASH_VERSION}" in
      [4-9]*|[1-9][0-9]*)
         RVAL="${1,,}"
         return
      ;;
   esac

   if [ ! -z "${ZSH_VERSION}" ]
   then
      RVAL="${1:l}"
      return
   fi

   RVAL="`printf "$1" | tr '[:upper:]' '[:lower:]'`"
}


logging_initialize()
{
   logging_initialize_color
}

logging_initialize "$@"

:
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
[ ! -z "${MULLE_EXEKUTOR_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-exekutor.sh" >&2

[ -z "${MULLE_LOGGING_SH}" ] && \
   echo "mulle-logging.sh must be included before mulle-executor.sh" 2>&1 && exit 1

MULLE_EXEKUTOR_SH="included"


# ####################################################################
#                          Execution
# ####################################################################
exekutor_print_arrow()
{
   local arrow

   [ -z "${MULLE_EXECUTABLE_PID}" ] && internal_fail "MULLE_EXECUTABLE_PID not set"

   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}"  \
        -a ! -z "${BASHPID}" \
        -a "${MULLE_EXECUTABLE_PID}" != "${BASHPID}" ]
   then
      arrow="=[${BASHPID:-0}]=>"
   else
      arrow="==>"
   fi

   printf "%s" "${arrow}"
}


# keep output down to 240 byte per line
exekutor_print()
{
   exekutor_print_arrow

   local escaped

   while [ $# -ne 0 ]
   do
      case "$1" in
         *[^a-zA-Z0-9._-]*|"")
            escaped="${1//\'/\'\"\'\"\'}"
            printf "%.240s" " '${escaped}'"
         ;;

         *)
            printf "%.240s" " $1"
         ;;
      esac
      shift
   done
   printf '\n'
}


eval_exekutor_print()
{
   exekutor_print_arrow

   local escaped

   while [ $# -ne 0 ]
   do
      printf "%s" " `echo \"$1\"`"  # what was the point of that ?
      shift
   done
   printf '\n'
}


exekutor_trace()
{
   local printer="$1"; shift

   if [  "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         ${printer} "$@" >&2
      else
         ${printer} "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi
}


exekutor_trace_output()
{
   local printer="$1"; shift
   local redirect="$1"; shift
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         ${printer} "$@" "${redirect}" "${output}" >&2
      else
         ${printer} "$@" "${redirect}" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi
}


exekutor()
{
   exekutor_trace "exekutor_print" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   "$@"

   MULLE_EXEKUTOR_RVAL=$?
   return ${MULLE_EXEKUTOR_RVAL}
}


#
# the rexekutor promises only to read and is therefore harmless
#
rexekutor()
{
   exekutor_trace "exekutor_print" "$@"

   "$@"

   MULLE_EXEKUTOR_RVAL=$?
   return ${MULLE_EXEKUTOR_RVAL}
}


eval_exekutor()
{
   exekutor_trace "eval_exekutor_print" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   eval "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


#
# declared as harmless (read only)
# old name reval_exekutor didnt make much sense
#
eval_rexekutor()
{
   exekutor_trace "eval_exekutor_print" "$@"

   eval "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


_eval_exekutor()
{
   exekutor_trace "eval_exekutor_print" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   eval "$@"

   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


redirect_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
   local output="$1"; shift

   exekutor_trace_output "exekutor_print" '>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( "$@" ) > "${output}"

   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


redirect_eval_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
   local output="$1"; shift

   exekutor_trace_output "eval_exekutor_print" '>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( eval "$@" ) > "${output}"

   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


redirect_append_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
   local output="$1"; shift

   exekutor_trace_output "exekutor_print" '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( "$@" ) >> "${output}"

   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


_redirect_append_eval_exekutor()
{
   # You have a funny "not found" problem ? the base directory of output is missing!
   local output="$1"; shift

   exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( eval "$@" ) >> "${output}"

   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


_append_tee_exekutor()
{
   # You have a funny "not found" problem ? the base directory of output is missing!
   local output="$1"; shift
   local teeoutput="$1"; shift

   exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( "$@" ) 2>&1 | tee -a "${teeoutput}" "${output}"

   MULLE_EXEKUTOR_RVAL=${PIPESTATUS[0]}

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


_append_tee_eval_exekutor()
{
   # You have a funny "not found" problem ? the base directory of output is missing!
   local output="$1"; shift
   local teeoutput="$1"; shift

   exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( eval "$@" ) 2>&1 | tee -a "${teeoutput}" "${output}"

   MULLE_EXEKUTOR_RVAL=${PIPESTATUS[0]}

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-18}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


#
# output is supposed to be the logfile and teeoutput the console
#
logging_tee_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   # if we are tracing, we don't want to see this twice
   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" != 'YES' ]
   then
      exekutor_print "$@" >> "${teeoutput}"
   fi
   exekutor_print "$@" >> "${output}"

   _append_tee_exekutor "${output}" "${teeoutput}" "$@"
}


#
# output is supposed to be the logfile and teeoutput the console
#
logging_tee_eval_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   # if we are tracing, we don't want to see this twice
   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" != 'YES' ]
   then
      eval_exekutor_print "$@" >> "${teeoutput}"
   fi
   eval_exekutor_print "$@" >> "${output}"
   _append_tee_eval_exekutor "${output}" "${teeoutput}" "$@"
}


#
# output eval trace also into logfile
#
logging_redirekt_exekutor()
{
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" != 'YES' ]
   then
      exekutor_print "$@" >> "${output}"
   fi
   redirect_append_exekutor "${output}" "$@"
}


logging_redirect_eval_exekutor()
{
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" != 'YES' ]
   then
      eval_exekutor_print "$@" >> "${output}"
   fi
   _redirect_append_eval_exekutor "${output}" "$@"
}


#
# prefer mulle-column as it colorifies
#        column if installed (as its a BSD tool, its often missing)
#        cat as a fallback to get anything
#
rexecute_column_table_or_cat()
{
   local separator="$1"; shift

   local cmd
   local column_cmds="mulle-column column cat"

   if [ -z "${COLUMN}" ]
   then
      for cmd in ${column_cmds}
      do
         if COLUMN="`command -v "${cmd}" `"
         then
            break
         fi
      done
   fi

   if [ -z "${COLUMN}" ]
   then
      fail "No matching executable for any of ${column_cmds// /,} found"
   fi

   case "${COLUMN}" in
      *column)
         rexekutor "${COLUMN}" '-t' '-s' "${separator:-;}" "$@"
      ;;

      *)
         rexekutor "${COLUMN}" "$@"
      ;;
   esac
}

:
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
[ ! -z "${MULLE_STRING_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-string.sh" >&2

MULLE_STRING_SH="included"

[ -z "${MULLE_COMPATIBILITY_SH}" ] && echo "mulle-compatibility.sh must be included before mulle-string.sh" 2>&1 && exit 1

# ####################################################################
#                            Concatenation
# ####################################################################
#

# no separator
r_append()
{
   RVAL="${1}${2}"
}


r_concat()
{
   local separator="${3:- }"

   if [ -z "${1}" ]
   then
      RVAL="${2}"
   else
      if [ -z "${2}" ]
      then
         RVAL="${1}"
      else
         RVAL="${1}${separator}${2}"
      fi
   fi
}


concat()
{
   r_concat "$@"
   printf "%s\n" "$RVAL"
}


# https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
r_trim_whitespace()
{
   RVAL="$*"
   RVAL="${RVAL#"${RVAL%%[![:space:]]*}"}"
   RVAL="${RVAL%"${RVAL##*[![:space:]]}"}"
}


#
# works for a "common" set of separators
#
r_remove_ugly()
{
   local s="$1"
   local separator="${2:- }"

   local escaped
   local dualescaped
   local replacement

   printf -v escaped '%q' "${separator}"

   dualescaped="${escaped//\//\/\/}"
   replacement="${separator}"
   case "${separator}" in
      */*)
         replacement="${escaped}"
      ;;
   esac

   local old

   RVAL="${s}"
   old=''
   while [ "${RVAL}" != "${old}" ]
   do
      old="${RVAL}"
      RVAL="${RVAL##[${separator}]}"
      RVAL="${RVAL%%[${separator}]}"
      RVAL="${RVAL//${dualescaped}${dualescaped}/${replacement}}"
   done
}

#
# this is "cross-platform" because the paths on MINGW are converted to
# '/' already
#

# use for PATHs
r_colon_concat()
{
   r_concat "$1" "$2" ":"
   r_remove_ugly "${RVAL}" ":"
}

# use for lists w/o empty elements
r_comma_concat()
{
   r_concat "$1" "$2" ","
   r_remove_ugly "${RVAL}" ","
}

# use for CSV
r_semicolon_concat()
{
   r_concat "$1" "$2" ";"
}


# use for filepaths
r_slash_concat()
{
   r_concat "$1" "$2" "/"
   r_remove_duplicate "${RVAL}" "/"
}

# remove a value from a list
r_list_remove()
{
   local sep="${3:- }"

   RVAL="${sep}$1${sep}//${sep}$2${sep}/}"
   RVAL="${RVAL##${sep}}"
   RVAL="${RVAL%%${sep}}"
}


r_colon_remove()
{
   r_list_remove "$1" "$2" ":"
}


r_comma_remove()
{
   r_list_remove "$1" "$2" ","
}


# use for building sentences, where space is a separator and
# not indenting or styling
r_space_concat()
{
   concat_no_double_separator "$1" "$2" | string_remove_ugly_separators
}


r_add_line()
{
   local lines="$1"
   local line="$2"

   if [ ! -z "${lines:0:1}" ]
   then
      if [ ! -z "${line:0:1}" ]
      then
         RVAL="${lines}"$'\n'"${line}"
      else
         RVAL="${lines}"
      fi
   else
      RVAL="${line}"
   fi
}


r_remove_line()
{
   local lines="$1"
   local search="$2"

   local line

   local delim

   RVAL=
   shell_disable_glob; IFS=$'\n'
   for line in ${lines}
   do
      if [ "${line}" != "${search}" ]
      then
         RVAL="${RVAL}${delim}${line}"
         delim=$'\n'
      fi
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob
}


r_remove_line_once()
{
   local lines="$1"
   local search="$2"

   local line

   local delim

   RVAL=
   shell_disable_glob; IFS=$'\n'
   for line in ${lines}
   do
      if [ -z "${search}" -o "${line}" != "${search}" ]
      then
         RVAL="${RVAL}${delim}${line}"
         delim=$'\n'
      else 
         search="" 
      fi
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob
}


r_get_last_line()
{
  RVAL="$(sed -n '$p' <<< "$1")" # get last line
}


r_remove_last_line()
{
   RVAL="$(sed '$d' <<< "$1")"  # remove last line
}

#
# can't have linefeeds as delimiter
# e.g. find_item "a,b,c" b -> 0
#      find_item "a,b,c" d -> 1
#      find_item "a,b,c" "," -> 1
#
find_item()
{
   local line="$1"
   local search="$2"
   local delim="${3:-,}"

   shell_is_extglob_enabled || internal_fail "need extglob enabled"

   if [ ! -z "${ZSH_VERSION}" ]
   then
      case "${delim}${line}${delim}" in
         *"${delim}${~search}${delim}"*)
            return 0
         ;;
      esac
   else
      case "${delim}${line}${delim}" in
         *"${delim}${search}${delim}"*)
            return 0
         ;;
      esac
   fi      
   return 1
}

#
# find_line is fairly critical for mulle-sourcetree walk, which
# is the slowest operation and most used operation. Don't dick
# around with this without profiling!
#
find_empty_line_zsh()
{
   local lines="$1"

   case "${lines}" in 
      *$'\n'$'\n'*)
         return 0
      ;;
   esac

   return 1
}

# zsh:
# this is faster than calling fgrep externally
# this is faster than while read line <<< lines
# this is faster than case ${lines} in 
#f
find_line_zsh()
{
   local lines="$1"
   local search="$2"

   if [ -z "${search:0:1}" ]
   then
      if [ -z "${lines:0:1}" ]
      then
         return 0
      fi
      find_empty_line_zsh "${lines}"
      return $?
   fi

   local rval
   local line

   rval=1

   IFS=$'\n'
   for line in ${lines}
   do
      if [ "${line}" = "${search}" ]
      then
         rval=0
         break
      fi
   done
   IFS="${DEFAULT_IFS}"

   return $rval
}


# bash:
# this is faster than calling fgrep externally
# this is faster than while read line <<< lines
# this is faster than for line in lines
#
find_line()
{
   # ZSH is apparently super slow in pattern matching
   if [ ! -z "${ZSH_VERSION}" ]
   then
      find_line_zsh "$@"
      return $?
   fi

   local lines="$1"
   local search="$2"

   local escaped_lines
   local pattern

# ensure leading and trailing linefeed for matching and $'' escaping
   printf -v escaped_lines "%q" "
${lines}
"

# add a linefeed here to get also $'' escaping
   printf -v pattern "%q" "${search}
"
   # remove $'
   pattern="${pattern:2}"
   # remove \n'
   pattern="${pattern%???}"

   local rval

   rval=1

   shell_is_extglob_enabled || internal_fail "extglob must be enabled"

   if [ ! -z "${ZSH_VERSION}" ]
   then
      case "${escaped_lines}" in
         *"\\n${~pattern}\\n"*)
            rval=0
         ;;
      esac
   else
      case "${escaped_lines}" in
         *"\\n${pattern}\\n"*)
            rval=0
         ;;
      esac
   fi

   return $rval
}


r_count_lines()
{
   local array="$1"

   RVAL=0

   local line

   shell_disable_glob; IFS=$'\n'
   for line in ${array}
   do
      RVAL=$((RVAL + 1))
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob
}


#
# this removes any previous occurrence, its very costly
#
r_add_unique_line()
{
   local lines="$1"
   local line="$2"

   if [ -z "${line:0:1}" -o -z "${lines:0:1}" ]
   then
      RVAL="${lines}${line}"
      return
   fi

   if find_line "${lines}" "${line}"
   then
      RVAL="${lines}"
      return
   fi

   RVAL="${lines}
${line}"
}



r_remove_duplicate_lines()
{
   RVAL="`awk '!x[$0]++' <<< "$@"`"
}


remove_duplicate_lines()
{
   awk '!x[$0]++' <<< "$@"
}


remove_duplicate_lines_stdin()
{
   awk '!x[$0]++'
}


#
# for very many lines use
# `sed -n '1!G;h;$p' <<< "${lines}"`"
#
r_reverse_lines()
{
   local lines="$1"

   local line
   local delim

   RVAL=

   IFS=$'\n'
   while read -r line
   do
      RVAL="${line}${delim}${RVAL}"
      delim=$'\n'
   done <<< "${lines}"
   IFS="${DEFAULT_IFS}"
}


#
# makes somewhat prettier filenames, removing superflous "."
# and trailing '/'
# DO NOT USE ON URLs
#
r_filepath_cleaned()
{
   RVAL="$1"

   [ -z "${RVAL}" ] && return

   local old

   old=''

   # remove excess //, also inside components
   # remove excess /./, also inside components
   while [ "${RVAL}" != "${old}" ]
   do
      old="${RVAL}"
      RVAL="${RVAL//\/.\///}"
      RVAL="${RVAL//\/\///}"
   done

   if [ -z "${RVAL}" ] 
   then
      RVAL="${1:0:1}"
   fi
}


r_filepath_concat()
{
   local i
   local s
   local sep
   local fallback

   fallback=

   shell_disable_glob
   for i in "$@"
   do
      sep="/"

      r_filepath_cleaned "${i}"
      i="${RVAL}"

      case "$i" in
         "")
            continue
         ;;

         "."|"./")
            if [ -z "${fallback}" ]
            then
               fallback="./"
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
   shell_enable_glob

   if [ ! -z "${s}" ]
   then
      r_filepath_cleaned "${s}"
   else
      RVAL="${fallback:0:1}" # / make ./ . again
   fi
}


filepath_concat()
{
   r_filepath_concat "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


r_upper_firstchar()
{
   case "${BASH_VERSION}" in
      [0123]*)
         RVAL="`printf "${1:0:1}" | tr '[:lower:]' '[:upper:]'`"
         RVAL="${RVAL}${1:1}"
      ;;

      *)
         if [ ! -z "${ZSH_VERSION}" ]
         then
            RVAL="${1:0:1}"
            RVAL="${RVAL:u}${1:1}"
         else
            RVAL="${1^}"
         fi
      ;;
   esac
}


r_capitalize()
{
   r_lowercase "$@"
   r_upper_firstchar "${RVAL}"
}



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


r_lowercase()
{
   case "${BASH_VERSION}" in
      [0123]*)
         RVAL="`printf "$1" | tr '[:upper:]' '[:lower:]'`"
      ;;

      *)
         if [ ! -z "${ZSH_VERSION}" ]
         then
            RVAL="${1:l}"
         else
            RVAL="${1,,}"
         fi
      ;;
   esac
}


r_identifier()
{
   # works in bash 3.2
   # may want to disambiguate mulle-scion and MulleScion with __
   # but it looks surprising for mulle--testallocator
   #
   RVAL="${1//-/_}" # __
   RVAL="${RVAL//[^a-zA-Z0-9]/_}"
   case "${RVAL}" in
      [0-9]*)
         RVAL="_${RVAL}"
      ;;
   esac
}


# ####################################################################
#                            Strings
# ####################################################################
#
is_yes()
{
   local s

   case "$1" in
      [yY][eE][sS]|Y|1)
         return 0
      ;;
      [nN][oO]|[nN]|0|"")
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

#
# unused code
#

# escape_linefeeds()
# {
#    local text
#
#    text="${text//\|/\\\|}"
#    printf "%s" "${text}" | tr '\012' '|'
# }
#
#
# _unescape_linefeeds()
# {
#    tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
# }
#
#
# unescape_linefeeds()
# {
#    printf "%s\n" "$@" | tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
# }


# this is heaps faster than the sed code
r_escaped_grep_pattern()
{
   local s="$1"

   s="${s//\\/\\\\}"
   s="${s//\[/\\[}"
   s="${s//\]/\\]}"
   s="${s//\//\\/}"
   s="${s//\$/\\$}"
   s="${s//\*/\\*}"
   s="${s//\./\\.}"
   s="${s//\^/\\^}"
   s="${s//\|/\\|}"

   RVAL="$s"
}


# assumed that / is used like in sed -e 's/x/y/'
r_escaped_sed_pattern()
{
   local s="$1"

   s="${s//\\/\\\\}"
   s="${s//\[/\\[}"
   s="${s//\]/\\]}"
   s="${s//\//\\/}"
   s="${s//\$/\\$}"
   s="${s//\*/\\*}"
   s="${s//\./\\.}"
   s="${s//\^/\\^}"

   RVAL="$s"
}


# assumed that / is used like in sed -e 's/x/y/'
r_escaped_sed_replacement()
{
   local s="$1"

   s="${s//\\/\\\\}"
   s="${s//\//\\/}"
   s="${s//&/\\&}"

   RVAL="$s"
}


r_escaped_spaces()
{
   RVAL="${1// /\\ }"
}


r_escaped_backslashes()
{
   RVAL="${1//\\/\\\\}"
}


# it's assumed you want to put contents into
# singlequotes e.g.
#   r_escaped_singlequotes "say 'hello'"
#   x='${RVAL}'
r_escaped_singlequotes()
{
   local quote

   quote="'"
   RVAL="${1//${quote}/${quote}\"${quote}\"${quote}}"
}


# does not add surrounding "" 
r_escaped_doublequotes()
{
   RVAL="${*//\\/\\\\}"
   RVAL="${RVAL//\"/\\\"}"
}


# does not remove surrounding "" though
r_unescaped_doublequotes()
{
   RVAL="${*//\\\"/\"}"
   RVAL="${RVAL//\\\\/\\}"
}


r_escaped_shell_string()
{
   printf -v RVAL '%q' "$*"
}


# ####################################################################
#                          Prefix / Suffix
# ####################################################################
#
string_has_prefix()
{
  [ "${1#$2}" != "$1" ]
}


string_has_suffix()
{
  [ "${1%$2}" != "$1" ]
}


# much faster than calling "basename"
r_basename()
{
   local filename="$1"

   while :
   do
      case "${filename}" in
         /)
           RVAL="/"
           return
         ;;

         */)
            filename="${filename%?}"
         ;;

         *)
            RVAL="${filename##*/}"
            return
         ;;
      esac
   done
}


r_dirname()
{
   local filename="$1"

   local last

   while :
   do
      case "${filename}" in
         /)
            RVAL="${filename}"
            return
         ;;

         */)
            filename="${filename%?}"
            continue
         ;;
      esac
      break
   done

   # need to escape filename here as it may contain wildcards
   printf -v last '%q' "${filename##*/}"
   RVAL="${filename%${last}}"

   while :
   do
      case "${RVAL}" in
         /)
           return
         ;;

         */)
            RVAL="${RVAL%?}"
         ;;

         *)
            RVAL="${RVAL:-.}"
            return
         ;;
      esac
   done
}


#
# get prefix leading up to character 'c', but if 'c' is quoted deal with it
# properly
#
_r_prefix_with_unquoted_string()
{
   local s="$1"
   local c="$2"

   local prefix
   local e_prefix
   local head

   while :
   do
      prefix="${s%%${c}*}"             # a${
      if [ "${prefix}" = "${_s}" ]
      then
         RVAL=
         return 1
      fi

      e_prefix="${_s%%\\${c}*}"         # a\\${ or whole string if no match
      if [ "${e_prefix}" = "${_s}" ]
      then
         RVAL="${head}${prefix}"
         return 0
      fi

      if [ "${#e_prefix}" -gt "${#prefix}" ]
      then
         RVAL="${head}${prefix}"
         return 0
      fi

      e_prefix="${e_prefix}\\${c}"
      head="${head}${e_prefix}"
      # cut like this to avoid interpretation of e_prefix
      s="${s:${#e_prefix}}"
   done
}


#
# should be safe from malicious backticks and so forth, unfortunately
# this is not smart enough to parse all valid contents properly
#
_r_expand_string()
{
   local prefix_opener
   local prefix_closer
   local identifier
   local identifier_1
   local identifier_2
   local anything
   local value
   local default_value
   local head
   local found

   # ex: "a${b:-c${d:-e}}g"
   while [ ${#_s} -ne 0 ]
   do
      # look for ${
      _r_prefix_with_unquoted_string "${_s}" '${'
      found=$?
      prefix_opener="${RVAL}" # can be empty

      #
      # if there is an } before hand, then we stop execution
      # but we consume that. If there is none at all we bail
      #
      if ! _r_prefix_with_unquoted_string "${_s}" '}'
      then
         if [ ${found} -eq 0 ]
         then
            log_error "missing '}'"
            RVAL=
            return 1
         fi

         #
         # if we don't have an opener ${ or it comes after us we
         # are done
         #
      else
         prefix_closer="${RVAL}"
         if [ ${found} -ne 0 -o ${#prefix_closer} -lt ${#prefix_opener} ]
         then
            _s="${_s:${#prefix_closer}}"
            _s="${_s#\}}"
            RVAL="${head}${prefix_closer}"
            return 0
         fi
      fi

      #
      # No ${ here, then we are done
      #
      if [ ${found} -ne 0 ]
      then
         RVAL="${head}${_s}"
         return 0
      fi

      #
      # the middle is what we evaluate, that'_s whats left in '_s'
      #
      head="${head}${prefix_opener}"   # copy verbatim and continue

      _s="${_s:${#prefix_opener}}"
      _s="${_s#\$\{}"

      #
      # identifier_1 : ${identifier}
      # identifier_2 : ${identifier:-anything}
      #
      anything=
      identifier_1="${_s%%\}*}"     # this can't fail
      identifier_2="${_s%%:-*}"
      if [ "${identifier_2}" = "${_s}" ]
      then
         identifier_2=""
      fi

      default_value=
      if [ -z "${identifier_2}" -o ${#identifier_1} -lt ${#identifier_2} ]
      then
         identifier="${identifier_1}"
         _s="${_s:${#identifier}}"
         _s="${_s#\}}"
         anything=
      else
         identifier="${identifier_2}"
         _s="${_s:${#identifier}}"
         _s="${_s#:-}"
         anything="${_s}"
         if [ ! -z "${anything}" ]
         then
            if ! _r_expand_string
            then
               return 1
            fi
            default_value="${RVAL}"
         fi
      fi

      # idiot protection
      r_identifier "${identifier}"
      identifier="${RVAL}"

      if [ "${_expand}" = 'YES' ]
      then
         if [ ! -z "${ZSH_VERSION}" ]
         then
            value="${(P)identifier:-${default_value}}"
         else
            value="${!identifier:-${default_value}}"
         fi
      else
         value="${default_value}"
      fi
      head="${head}${value}"
   done

   RVAL="${head}"
   return 0
}


r_expanded_string()
{
   local string="$1"
   local expand="${2:-YES}"

   local _s="${string}"
   local _expand="${expand}"

   local rval

   _r_expand_string
   rval=$?

   return $rval
}

:
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
[ ! -z "${MULLE_INIT_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-init.sh" >&2

[ -z "${MULLE_STRING_SH}" ] && echo "mulle-string.sh must be included before mulle-init.sh" 2>&1 && exit 1


MULLE_INIT_SH="included"


# export into RVAL global
r_dirname()
{
   RVAL="$1"

   while :
   do
      case "${RVAL}" in
         /)
            return
         ;;

         */)
            RVAL="${RVAL%?}"
            continue
         ;;
      esac
      break
   done

   local last

   last="${RVAL##*/}"
   RVAL="${RVAL%${last}}"

   while :
   do
      case "${RVAL}" in
         /)
           return
         ;;

         */)
            RVAL="${RVAL%?}"
         ;;

         *)
            RVAL="${RVAL:-.}"
            return
         ;;
      esac
   done
}


#
# stolen from:
# http://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
# ----
#
r_prepend_path_if_relative()
{
   case "$2" in
      /*)
         RVAL="$2"
      ;;

      *)
         RVAL="$1/$2"
      ;;
   esac
}


r_resolve_symlinks()
{
   local filepath

   RVAL="$1"

   filepath="`readlink "${RVAL}"`"
   if [ $? -eq 0 ]
   then
      r_dirname "${RVAL}"
      r_prepend_path_if_relative "${RVAL}" "${filepath}"
      r_resolve_symlinks "${RVAL}"
   fi
}


#
# executablepath: will be $0
# subdir: will be mulle-bashfunctions/${VERSION}
# matchfile: the file to match agains
#
# Written this way, so it can get reused
#
r_get_libexec_dir()
{
   local executablepath="$1"
   local subdir="$2"
   local matchfile="$3"

   local exedirpath
   local prefix

   case "${executablepath}" in
      \.*|/*|~*)
      ;;

      *)
         executablepath="`command -v "${executablepath}"`"
      ;;
   esac

   r_resolve_symlinks "${executablepath}"
   executablepath="${RVAL}"

   r_dirname "${executablepath}"
   exedirpath="${RVAL}"

   r_dirname "${exedirpath}"
   prefix="${RVAL}"


   # now setup the global variable

   RVAL="${prefix}/libexec/${subdir}"
   if [ ! -f "${RVAL}/${matchfile}" ]
   then
      RVAL="${exedirpath}/src"
   fi

   case "$RVAL" in
      /*|~*)
      ;;

      .)
         RVAL="$PWD"
      ;;

      *)
         RVAL="$PWD/${RVAL}"
      ;;
   esac

   if [ ! -f "${RVAL}/${matchfile}" ]
   then
      unset RVAL
      printf "%s\n" "$0 fatal error: Could not find \"${subdir}\" libexec (${PWD#${MULLE_USER_PWD}/})" >&2
      exit 1
   fi
}


call_main()
{
   local flags="$1"; [ $# -ne 0 ] && shift

   if [ -z "${flags}" ]
   then
      main "$@"
      return $?
   fi

   local arg
   local args 
   local sep 

   args=""
   for arg in "$@"
   do
      printf -v args "%s%s%q" "${args}" "${sep}" "${arg}"
      sep=" "
   done

   unset arg

   eval main "${flags}" "${args}"
}
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
[ ! -z "${MULLE_OPTIONS_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-options.sh" >&2

[ -z "${MULLE_LOGGING_SH}" ] && echo "mulle-logging.sh must be included before mulle-options.sh" 2>&1 && exit 1

MULLE_OPTIONS_SH="included"


## core option parsing
# not used by mulle-bootstrap itself at the moment

#
# variables called flag. because they are indirectly set by flags
#
options_dump_env()
{
   log_trace "ARGS:${C_TRACE2} ${MULLE_ARGUMENTS}"
   log_trace "PWD :${C_TRACE2} `pwd -P 2> /dev/null`"
   log_trace "ENV :${C_TRACE2} `env | sort`"
   log_trace "LS  :${C_TRACE2} `ls -a1F`"
}

# caller should do set +x if 0
options_setup_trace()
{

   if [ "${MULLE_FLAG_LOG_ENVIRONMENT}" = YES ]
   then
      options_dump_env
   fi

   case "${1}" in
      VERBOSE)
         MULLE_FLAG_LOG_VERBOSE='YES'
      ;;

      FLUFF)
         MULLE_FLAG_LOG_FLUFF='YES'
         MULLE_FLAG_LOG_VERBOSE='YES'
      ;;

      TRACE)
         MULLE_FLAG_LOG_EXEKUTOR='YES'
         MULLE_FLAG_LOG_FLUFF='YES'
         MULLE_FLAG_LOG_VERBOSE='YES'
      ;;

      1848)
         MULLE_FLAG_LOG_SETTINGS='YES'
         MULLE_FLAG_LOG_FLUFF='YES'
         MULLE_FLAG_LOG_VERBOSE='YES'

         if [ "${MULLE_TRACE_POSTPONE}" != 'YES' ]
         then
            # log_trace "1848 trace (set -x) started"
            # set -x # lol fcking zsh turns this off at function end
            #        # unsetopt localoptions does not help
            PS4="+ ${ps4string} + "
         fi
         return 0
      ;;
   esac

   return 2
}


_options_technical_flags_usage()
{
   local DELIMITER="${1:- : }"
   local align="${2:-YES}"

   local S

   if [ "${align}" = 'YES' ]
   then
      S=" "
   fi

   cat <<EOF
   -n${S}${S}${S}${DELIMITER}dry run
   -s${S}${S}${S}${DELIMITER}be silent
   -v${S}${S}${S}${DELIMITER}be verbose (increase with -vv, -vvv)
EOF

   if [ ! -z "${MULLE_TRACE}" ]
   then
      cat <<EOF
   -ld${S}${S}${DELIMITER}additional debug output
   -le${S}${S}${DELIMITER}additional environment debug output
   -lx${S}${S}${DELIMITER}external command execution log output
EOF
   fi
}


options_technical_flags_usage()
{
   _options_technical_flags_usage "$@" | sort
}


before_trace_fail()
{
   [ "${MULLE_TRACE}" = '1848' ] || \
      fail "option \"$1\" must be specified after -t"
}


after_trace_warning()
{
   [ "${MULLE_TRACE}" = '1848' ] && \
      log_warning "warning: ${MULLE_EXECUTABLE_FAIL_PREFIX}: $1 after -t invalidates -t"
}


#
# local MULLE_FLAG_EXEKUTOR_DRY_RUN
# local MULLE_FLAG_LOG_DEBUG
# local MULLE_FLAG_LOG_EXEKUTOR
# local MULLE_FLAG_LOG_TERSE
# local MULLE_FLAG_LOG_ENVIRONMENT
# local MULLE_TRACE
#
options_technical_flags()
{
   local flag="$1"

   case "${flag}" in
      -n|--dry-run)
         MULLE_FLAG_EXEKUTOR_DRY_RUN='YES'
      ;;

      -ld|--log-debug)
         MULLE_FLAG_LOG_DEBUG='YES'
         # propagate
      ;;

      -lD)
         MULLE_FLAG_LOG_DEBUG='YES'
         return # don't propagate
      ;;

      -lD*D)
         MULLE_FLAG_LOG_DEBUG='YES'
         flag="${flag%D}"
      ;;

      -le|--log-environment)
         MULLE_FLAG_LOG_ENVIRONMENT='YES'
         # propagate
      ;;

      -lE)
         MULLE_FLAG_LOG_ENVIRONMENT='YES'
         return # don't propagate
      ;;

      -lE*E)
         MULLE_FLAG_LOG_ENVIRONMENT='YES'
         flag="${flag%E}"
      ;;

      -ls|--log-settings)
         MULLE_FLAG_LOG_SETTINGS='YES'
         # propagate
      ;;

      -lS)
         MULLE_FLAG_LOG_SETTINGS='YES'
         return # don't propagate
      ;;

      -lS*S)
         MULLE_FLAG_LOG_SETTINGS='YES'
         flag="${flag%S}"
      ;;

      -lx|--log-exekutor|--log-execution)
         MULLE_FLAG_LOG_EXEKUTOR='YES'
         # propagate
      ;;

      -lX)
         MULLE_FLAG_LOG_EXEKUTOR='YES'
         return # don't propagate
      ;;

      -lX*X)
         MULLE_FLAG_LOG_EXEKUTOR='YES'
         flag="${flag%X}"
      ;;

      -l-)
         MULLE_FLAG_LOG_DEBUG=
         MULLE_FLAG_LOG_ENVIRONMENT=
         MULLE_FLAG_LOG_EXEKUTOR=
         MULLE_FLAG_LOG_SETTINGS=
      ;;


      -t|--trace)
         MULLE_TRACE='1848'
         if [ ! -z "${ZSH_VERSION}" ]
         then
            ps4string='%1x:%I' # TODO: fix for zsh
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         # propagate
      ;;

      -tfpwd|--trace-full-pwd)
         before_trace_fail "${flag}"
         if [ ! -z "${ZSH_VERSION}" ]
         then
            ps4string='%1x:%I \"\w\"'
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO} \"\w\"'
         fi
      ;;

      -tp|--trace-profile)
#         if [ ! -z "${ZSH_VERSION}" ]
#         then
#            zmodload "zsh/zprof"
#            # can't trap global exit from within function :(
#            MULLE_RUN_ZPROF_ON_EXIT="YES"
#         else
            before_trace_fail "${flag}"
   
            case "${MULLE_UNAME}" in
               '')
                  internal_fail 'MULLE_UNAME must be set by now'
               ;;
               linux)
                  if [ ! -z "${ZSH_VERSION}" ]
                  then
                     ps4string='$(date "+%s.%N (%1x:%I)")'
                  else
                     ps4string='$(date "+%s.%N (${BASH_SOURCE[0]##*/}:${LINENO})")'
                  fi
               ;;
               *)
                  if [ ! -z "${ZSH_VERSION}" ]
                  then
                     ps4string='$(date "+%s (%1x:%I)")'
                  else
                     ps4string='$(date "+%s (${BASH_SOURCE[0]##*/}:${LINENO})")'
                  fi
               ;;
            esac
#         fi
         return # don't propagate
      ;;

      -tpo|--trace-postpone)
         before_trace_fail "${flag}"
         MULLE_TRACE_POSTPONE='YES'
      ;;

      -tpwd|--trace-pwd)
         before_trace_fail "${flag}"
         if [ ! -z "${ZSH_VERSION}" ]
         then
            ps4string='%1x:%I \".../\W\"'
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO} \".../\W\"'
         fi
      ;;

      -tx|--trace-immediately)
         set -x
      ;;

      -t-)
         MULLE_TRACE=
         set +x
      ;;

      -T)
         MULLE_TRACE='1848'
         if [ ! -z "${ZSH_VERSION}" ]
         then
            ps4string='%1x:%I'
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         return # don't propagate
      ;;

      -T*T)
         MULLE_TRACE='1848'
         if [ ! -z "${ZSH_VERSION}" ]
         then
            ps4string='%1x:%I'
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         flag="${flag%T}"
      ;;

      -s|--silent)
         MULLE_FLAG_LOG_TERSE='YES'
      ;;

      -v-|--no-verbose)
         MULLE_FLAG_LOG_TERSE=
      ;;

      -v|--verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='VERBOSE'
      ;;

      -vv|--very-verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='FLUFF'
      ;;

      -vvv|--very-very-verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='TRACE'
      ;;

      -V)
         after_trace_warning "${flag}"

         MULLE_TRACE='VERBOSE'
         return # don't propagate
      ;;

      -VV)
         after_trace_warning "${flag}"

         MULLE_TRACE='FLUFF'
         return # don't propagate
      ;;

      -VVV)
         after_trace_warning "${flag}"

         MULLE_TRACE='TRACE'
         return # don't propagate
      ;;

      --clear-flags)
         MULLE_TECHNICAL_FLAGS=''
         return 0
      ;;

      --list-technical-flags)
         echo "\
--clear-flags
--dry-run
--log-debug
--log-environment
--log-settings
--log-exekutor
--trace
--trace-full-pwd
--trace-profile
--trace-postpone
--trace-pwd
--trace-immediately
--silent
--verbose
--very-verbose
--very-very-verbose"
         return 0
      ;;

      *)
         return 1
      ;;
   esac

   #
   # collect technical options so interested parties can forward them to
   # other mulle tools. In tools they are called flags, and this will be
   # renamed too, eventually. If you don't want to forward the technical
   # flags to other mulle-bashfunction programs - sometimes- use
   # --clear-flags after all the other flags.
   #
   if [ -z "${MULLE_TECHNICAL_FLAGS}" ]
   then
      MULLE_TECHNICAL_FLAGS="${flag}"
   else
      MULLE_TECHNICAL_FLAGS="${MULLE_TECHNICAL_FLAGS} ${flag}"
   fi

   return 0
}


## option parsing common


options_unpostpone_trace()
{
   if [ ! -z "${MULLE_TRACE_POSTPONE}" -a "${MULLE_TRACE}" = '1848' ]
   then
      set -x
      PS4="+ ${ps4string} + "
   fi
}


#
# this has very limited use, i only use it in some tests
# caller should do set +x if 0
_options_mini_main()
{
   while [ $# -ne 0 ]
   do
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      break
   done

   options_setup_trace "${MULLE_TRACE}"
}


:
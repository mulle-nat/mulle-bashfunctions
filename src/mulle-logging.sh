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
[ ! -z "${MULLE_LOGGING_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = "YES" ] && \
   echo "double inclusion of mulle-logging.sh" >&2

MULLE_LOGGING_SH="included"


log_printf()
{
   local format="$1" ; shift

   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
   then
      printf "${format}" "$@" >&2
   else
      printf "${format}" "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
   fi
}


log_error()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX} error:${C_ERROR_TEXT} %b${C_RESET}\n" "$*"
}


log_fail()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX} fatal error:${C_ERROR_TEXT} %b${C_RESET}\n" "$*"
}


log_warning()
{
   if [ "${MULLE_FLAG_LOG_TERSE}" != "YES" ]
   then
      log_printf "${C_WARNING}${MULLE_EXECUTABLE_FAIL_PREFIX} warning:${C_WARNING_TEXT} %b${C_RESET}\n" "$*"
   fi
}


log_info()
{
   if [ "${MULLE_FLAG_LOG_TERSE}" != "YES" ]
   then
      log_printf "${C_INFO}%b${C_RESET}\n" "$*"
   fi
}


log_verbose()
{
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
   then
      log_printf "${C_VERBOSE}%b${C_RESET}\n" "$*"
   fi
}


log_fluff()
{
   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      log_printf "${C_FLUFF}%b${C_RESET}\n" "$*"
   fi
}


# setting is like fluff but different color scheme
log_setting()
{
   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      log_printf "${C_SETTING}%b${C_RESET}\n" "$*"
   fi
}


# for debugging, not for user. same as fluff
log_debug()
{
   if [ "${MULLE_FLAG_LOG_DEBUG}" != "YES" ]
   then
      return
   fi

   case "${MULLE_UNAME}" in
      linux)
         log_printf "${C_BR_RED}$(date "+%s.%N") %b${C_RESET}\n" "$*"
      ;;
      *)
         log_printf "${C_BR_RED}$(date "+%s") %b${C_RESET}\n" "$*"
      ;;
   esac
}


log_entry()
{
   if [ "${MULLE_FLAG_LOG_DEBUG}" != "YES" ]
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

   log_debug "${functionname}" ${args}
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
#

stacktrace()
{
   local i=1
   local line

   # don't stack trace when tracing
   case "$-" in
      *x*)
         return
      ;;
   esac

   while line="`caller $i`"
   do
      log_printf "${C_CYAN}%b${C_RESET}\n" "$i: #${line}"
      ((i++))
   done
}


_bail()
{
#   should kill process group...
#   kills calling shell too though
#   kill 0

#   if [ ! -z "${MULLE_EXECUTABLE_PID}" ]
#   then
#      kill -INT "${MULLE_EXECUTABLE_PID}"  # kill myself (especially, if executing in subshell)
#      if [ $$ -ne ${MULLE_EXECUTABLE_PID} ]
#      then
#         kill -INT $$  # actually useful
#      fi
#   fi
# case "${UNM"
#   sleep 1
   exit 1
}



fail()
{
   if [ ! -z "$*" ]
   then
      log_fail "$*"
   fi

   if [ "${MULLE_FLAG_LOG_DEBUG}" = "YES" ]
   then
      stacktrace
   fi

   _bail
}


internal_fail()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX} *** internal error ***:${C_ERROR_TEXT} %b${C_RESET}\n" "$*"
   stacktrace
   _bail
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


logging_trap_remove()
{
   local rval

   rval=$?
   trap - TERM INT
   return $rval
}


logging_initialize()
{
   if [ ! -z "${MULLE_EXECUTABLE}" ]
   then
      return
   fi

   MULLE_EXECUTABLE="$0"

   # can be convenient to overload by caller sometimes
   if [ -z "${MULLE_EXECUTABLE_NAME}" ]
   then
      MULLE_EXECUTABLE_NAME="`basename -- "${MULLE_EXECUTABLE}"`"
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME:-${MULLE_EXECUTABLE_NAME}}"
   MULLE_EXECUTABLE_PWD="${PWD}"
   MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE_NAME}"
   MULLE_EXECUTABLE_PID="$$"

   DEFAULT_IFS="${IFS}" # as early as possible

   #
   # need this for scripts also
   #
   if [ -z "${MULLE_UNAME}" ]
   then
      MULLE_UNAME="`uname | cut -d_ -f1 | sed 's/64$//' | tr 'A-Z' 'a-z'`"
      UNAME="${MULLE_UNAME}"  # backwards compatibility
   fi

   if [ -z "${MULLE_HOSTNAME}" ]
   then
      MULLE_HOSTNAME="`hostname -s`"
      # MULLE_HOSTNAME="`printf "%s" "${MULLE_HOSTNAME}" | tr -c 'a-zA-Z0-9._-' '_'`"
   fi

   if [ "${MULLE_NO_COLOR}" != "YES" ]
   then
      case "${MULLE_UNAME}" in
         *)
            C_RESET="\033[0m"

            # Useable Foreground colours, for black/white white/black
            C_RED="\033[0;31m"     C_GREEN="\033[0;32m"
            C_BLUE="\033[0;34m"    C_MAGENTA="\033[0;35m"
            C_CYAN="\033[0;36m"

            C_BR_RED="\033[0;91m"
            C_BOLD="\033[1m"
            C_FAINT="\033[2m"

            C_RESET_BOLD="${C_RESET}${C_BOLD}"

            if [ "${MULLE_LOGGING_TRAP}" != "NO" ]
            then
               logging_trap_install
            fi
         ;;
      esac
   fi


   C_ERROR="${C_BR_RED}${C_BOLD}"
   C_WARNING="${C_RED}${C_BOLD}"
   C_INFO="${C_CYAN}${C_BOLD}"
   C_VERBOSE="${C_GREEN}${C_BOLD}"
   C_FLUFF="${C_GREEN}${C_BOLD}"
   C_SETTING="${C_GREEN}${C_FAINT}"
   C_TRACE="${C_FLUFF}${C_FAINT}"
   C_TRACE2="${C_RESET}${C_FAINT}"

   C_WARNING_TEXT="${C_RESET}${C_RED}${C_BOLD}"
   C_ERROR_TEXT="${C_RESET}${C_BR_RED}${C_BOLD}"

   if [ ! -z "${MULLE_LIBEXEC_TRACE}" ]
   then
      local exedir
      local exedirpath

      exedir="`dirname "${BASH_SOURCE}"`"
      exedirpath="$( cd "${exedir}" ; pwd -P )" || fail "failed to get pwd"
      echo "${MULLE_EXECUTABLE_NAME} libexec: ${exedirpath}" >&2
   fi
}

logging_initialize "$@"

:

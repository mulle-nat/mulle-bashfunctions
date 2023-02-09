### >> START OF mulle-bashfunctions-embed.sh >>
#
#   Copyright (c) 2015-2021 Nat! - Mulle kybernetiK
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
#

if ! [ ${MULLE_BASHGLOBAL_SH+x} ]
then
   MULLE_BASHGLOBAL_SH='included'

   DEFAULT_IFS="${IFS}" # as early as possible

   if [ ${ZSH_VERSION+x} ]
   then
     setopt sh_word_split
     setopt POSIX_ARGZERO
     set -o GLOB_SUBST        # neede for [[ $i == $pattern ]]
   fi

   if [ -z "${MULLE_EXECUTABLE:-}" ]
   then
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


   if [ -z "${MULLE_EXECUTABLE_NAME:-}" ]
   then
      MULLE_EXECUTABLE_NAME="${MULLE_EXECUTABLE##*/}"
   fi

   if [ -z "${MULLE_USER_PWD:-}" ]
   then
      MULLE_USER_PWD="${PWD}"
      export MULLE_USER_PWD
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME:-${MULLE_EXECUTABLE_NAME}}"

   MULLE_EXECUTABLE_PWD="${PWD}"
   MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE_NAME}"
   MULLE_EXECUTABLE_PID="$$"

   if [ -z "${MULLE_UNAME:-}" ]
   then
      case "${BASH_VERSION:-}" in
         [0123]*)
            MULLE_UNAME="`uname | tr '[:upper:]' '[:lower:]'`"
         ;;

         *)
            MULLE_UNAME="${_MULLE_UNAME:-`uname`}"
            if [ ${ZSH_VERSION+x} ]
            then
               MULLE_UNAME="${MULLE_UNAME:l}"
            else
               MULLE_UNAME="${MULLE_UNAME,,}"
            fi
         ;;
      esac
      
      MULLE_UNAME="${MULLE_UNAME%%_*}"
      MULLE_UNAME="${MULLE_UNAME%[36][24]}" # remove 32 64 (hax)

      case "${MULLE_UNAME}" in 
         linux)
            read -r MULLE_UNAME < /proc/sys/kernel/osrelease
            case "${MULLE_UNAME}" in
               *-[Mm]icrosoft-*)
                  MULLE_UNAME="windows" # wsl2, this is super slow on NTFS
               ;;

               *-[Mm]icrosoft)
                  MULLE_UNAME="windows" # wsl1
               ;;

               *-android-*|*-android)
                  MULLE_UNAME="android"
               ;;
     
               *)
                  MULLE_UNAME="linux"
               ;;
            esac
         ;;

         msys|cygwin)
            MULLE_UNAME='msys'
         ;;
      esac
   fi

   if [ "${MULLE_UNAME}" = "windows" ]
   then
      MULLE_EXE_EXTENSION=".exe"
   fi

   if [ -z "${MULLE_HOSTNAME:-}" ]
   then
      case "${MULLE_UNAME}" in
         'mingw'|'msys'|'sunos')
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

   if [ -z "${MULLE_USERNAME:-}" ]
   then
      MULLE_USERNAME="${MULLE_USERNAME:-${USERNAME}}" # mingw
      MULLE_USERNAME="${MULLE_USERNAME:-${USER}}"
      MULLE_USERNAME="${MULLE_USERNAME:-${LOGNAME}}"
      MULLE_USERNAME="${MULLE_USERNAME:-`id -nu 2> /dev/null`}"
      MULLE_USERNAME="${MULLE_USERNAME:-cptnemo}"
   fi
fi
if ! [ ${MULLE_COMPATIBILITY_SH+x} ]
then
MULLE_COMPATIBILITY_SH='included'


function shell_enable_pipefail()
{
   set -o pipefail
}


function shell_disable_pipefail()
{
   set +o pipefail
}


function shell_is_pipefail_enabled()
{
   case "$-" in
      *f*)
         return 1
      ;;
   esac
   return 0
}


function shell_enable_extglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt kshglob
      setopt bareglobqual
   else
      shopt -s extglob
   fi
}


function shell_disable_extglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt bareglobqual
      unsetopt kshglob
   else
      shopt -u extglob
   fi
}


function shell_is_extglob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
   then
      [[ -o kshglob ]]
      return $?
   fi

   shopt -q extglob
}


function shell_enable_nullglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt nullglob
   else
      shopt -s nullglob
   fi
}


function shell_disable_nullglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt nullglob
   else
      shopt -u nullglob
   fi
}


function shell_is_nullglob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
   then
      [[ -o nullglob ]]
      return $?
   fi
   shopt -q nullglob
}


function shell_enable_glob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt noglob
   else
      set +f
   fi
}


function shell_disable_glob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt noglob
   else
      set -f
   fi
}


function shell_is_glob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
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


function shell_is_function()
{
   if [ ${ZSH_VERSION+x} ]
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


function r_shell_indirect_expand()
{
   local key="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      RVAL="${(P)key}"
   else
      RVAL="${!key}"
   fi
}

unalias -a

if [ ${ZSH_VERSION+x} ]
then
   setopt aliases

   alias .for="setopt noglob; for"
   alias .foreachline="setopt noglob; IFS=$'\n'; for"
   alias .foreachword="setopt noglob; IFS=' '$'\t'$'\n'; for"
   alias .foreachitem="setopt noglob; IFS=','; for"
   alias .foreachpath="setopt noglob; IFS=':'; for"
   alias .foreachpathcomponent="set -f; IFS='/'; for"
   alias .foreachcolumn="setopt noglob; IFS=';'; for"
   alias .foreachfile="unsetopt noglob; setopt nullglob; IFS=' '$'\t'$'\n'; for"
   alias .do="do
   unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'"
   alias .done="done;unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'"

else
   shopt -s expand_aliases

   alias .for="set -f; for"
   alias .foreachline="set -f; IFS=$'\n'; for"
   alias .foreachword="set -f; IFS=' '$'\t'$'\n'; for"
   alias .foreachitem="set -f; IFS=','; for"
   alias .foreachpath="set -f; IFS=':'; for"
   alias .foreachpathcomponent="set -f; IFS='/'; for"
   alias .foreachcolumn="set -f; IFS=';'; for"
   alias .foreachfile="set +f; shopt -s nullglob; IFS=' '$'\t'$'\n'; for"
   alias .do="do
set +f; shopt -u nullglob; IFS=' '$'\t'$'\n'"
   alias .done="done;set +f; shopt -u nullglob; IFS=' '$'\t'$'\n'"
fi


alias .break="break"
alias .continue="continue"


shell_enable_extglob
shell_enable_pipefail

fi
:
if ! [ ${MULLE_LOGGING_SH+x} ]
then
MULLE_LOGGING_SH='included'



_log_printf()
{
   local format="$1" ; shift


   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE:-}" ]
   then
      printf "${format}" "$@" >&2
   else
      printf "${format}" "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
   fi
}


MULLE_LOG_ERROR_PREFIX=" error: "
MULLE_LOG_FAIL_ERROR_PREFIX=" fatal error: "

_log_error()
{
   _log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX}${MULLE_LOG_ERROR_PREFIX}${C_ERROR_TEXT}%b${C_RESET}\n" "$*"
}



_log_fail()
{
   _log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX}${MULLE_LOG_FAIL_ERROR_PREFIX}${C_ERROR_TEXT}%b${C_RESET}\n" "$*"
}


_log_warning()
{
   if [ "${MULLE_FLAG_LOG_TERSE:-}" != 'YES' ]
   then
      _log_printf "${C_WARNING}%b${C_RESET}\n" "$*"
   fi
}


_log_info()
{
   if [ "${MULLE_FLAG_LOG_TERSE:-}" != 'YES' ]
   then
      _log_printf "${C_INFO}%b${C_RESET}\n" "$*"
   fi
}


_log_verbose()
{
   if [ "${MULLE_FLAG_LOG_VERBOSE:-}" = 'YES' ]
   then
      _log_printf "${C_VERBOSE}%b${C_RESET}\n" "$*"
   fi
}


_log_fluff()
{
   if [ "${MULLE_FLAG_LOG_FLUFF:-}" = 'YES' ]
   then
      _log_printf "${C_FLUFF}%b${C_RESET}\n" "$*"
   else
      _log_debug "$@"
   fi
}


_log_setting()
{
   if [ "${MULLE_FLAG_LOG_SETTINGS:-}" = 'YES' ]
   then
      _log_printf "${C_SETTING}%b${C_RESET}\n" "$*"
   fi
}


_log_debug()
{
   if [ "${MULLE_FLAG_LOG_DEBUG:-}" != 'YES' ]
   then
      return
   fi

   case "${MULLE_UNAME}" in
      'linux'|'windows')
         _log_printf "${C_DEBUG}$(date "+%s.%N") %b${C_RESET}\n" "$*"
      ;;

      *)
         _log_printf "${C_DEBUG}$(date "+%s") %b${C_RESET}\n" "$*"
      ;;
   esac
}


_log_entry()
{
   if [ "${MULLE_FLAG_LOG_DEBUG:-}" != 'YES' ]
   then
      return
   fi

   local functionname="$1" ; shift

   local args
   local truncate

   if [ $# -ne 0 ]
   then
      truncate="$1"
      if [ "${#truncate}" -gt 200 ]
      then
         truncate="${truncate:0:197}..."
      fi
      args="'${truncate}'"
      shift
   fi

   while [ $# -ne 0 ]
   do
      truncate="$1"
      if [ "${#truncate}" -gt 200 ]
      then
         truncate="${truncate:0:197}..."
      fi
      args="${args}, '${truncate}'"
      shift
   done

   _log_debug "${functionname} ${args}"
}


_log_trace()
{
   case "${MULLE_UNAME}" in
      linux)
         _log_printf "${C_TRACE}$(date "+%s.%N") %b${C_RESET}\n" "$*"
         ;;

      *)
         _log_printf "${C_TRACE}$(date "+%s") %b${C_RESET}\n" "$*"
      ;;
   esac
}


alias log_debug='_log_debug'

alias log_entry='_log_entry'

alias log_error='_log_error'

alias log_fluff='_log_fluff'

alias log_info='_log_info'

alias log_setting='_log_setting'

alias log_trace='_log_trace'

alias log_verbose='_log_verbose'

alias log_warning='_log_warning'


log_set_trace_level()
{
   alias log_debug='_log_debug'
   alias log_entry='_log_entry'
   alias log_error='_log_error'
   alias log_fluff='_log_fluff'
   alias log_info='_log_info'
   alias log_setting='_log_setting'
   alias log_trace='_log_trace'
   alias log_verbose='_log_verbose'
   alias log_warning='_log_warning'


   if [ "${MULLE_FLAG_LOG_DEBUG:-}" != 'YES' ]
   then
      alias log_entry=': #'
      alias log_debug=': #'
   fi

   if [ "${MULLE_FLAG_LOG_SETTINGS:-}" != 'YES' ]
   then
      alias log_setting=': #'
   fi

   if [ "${MULLE_FLAG_LOG_FLUFF:-}" != 'YES' ]
   then
      if [ "${MULLE_FLAG_LOG_DEBUG:-}" = 'YES' ]
      then
         alias log_fluff='log_debug'
      else
         alias log_fluff=': #'
      fi
   fi

   if [ "${MULLE_FLAG_LOG_VERBOSE:-}" != 'YES' ]
   then
      alias log_verbose=': #'
   fi

   if [ "${MULLE_FLAG_LOG_TERSE:-}" = 'YES' ]
   then
      alias log_info=': #'
      alias log_warning=': #'
   fi
   :
}



if [ ${ZSH_VERSION+x} ]
then
   function caller()
   ( # sic!
      local i="${1:-1}"

      set +u
      i=$((i+1))
      local file=${funcfiletrace[$((i))]%:*}
      local line=${funcfiletrace[$((i))]##*:}
      local func=${funcstack[$((i + 1))]}

      if [ -z "${func## }" ]
      then
         return 1
      fi

      printf "%s %s %s\n" "$line" "$func" "${file##*/}"
      return 0
   ) # sic!
fi


stacktrace()
{
   case "$-" in
      *x*)
         return
      ;;
   esac

   local i
   local line
   local max

   i=1
   max=100

   while line="`caller $i`"
   do
      _log_printf "${C_CYAN}%b${C_RESET}\n" "$i: #${line}"
      i=$((i + 1))
      [ $i -gt $max ] && break
   done
}


function fail()
{
   if [ ! -z "$*" ]
   then
      _log_fail "$@"
   fi

   if [ "${MULLE_FLAG_LOG_DEBUG:-}" = 'YES' ]
   then
      stacktrace
   fi

   exit 1
}


MULLE_INTERNAL_ERROR_PREFIX=" *** internal error ***:"


function _internal_fail()
{
   _log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX}${MULLE_INTERNAL_ERROR_PREFIX}${C_ERROR_TEXT}%b${C_RESET}\n" "$*"
   stacktrace
   exit 1
}


_fatal()
{
   _internal_fail "$@"
}


logging_reset()
{
   printf "%b" "${C_RESET}" >&2
}


logging_trap_install()
{
   trap 'logging_reset ; exit 1' TERM INT
}


logging_initialize_color()
{

   case "${TERM:-}" in
      dumb)
         MULLE_NO_COLOR=YES
      ;;
   esac

   if [ -z "${NO_COLOR:-}" -a "${MULLE_NO_COLOR:-}" != 'YES' ] && [ ! -f /dev/stderr ]
   then
      C_RESET="\033[0m"

      C_RED="\033[0;31m"     C_GREEN="\033[0;32m"
      C_BLUE="\033[0;34m"    C_MAGENTA="\033[0;35m"
      C_CYAN="\033[0;36m"

      C_BR_RED="\033[0;91m"
      C_BR_GREEN="\033[0;92m"
      C_BR_BLUE="\033[0;94m"
      C_BR_CYAN="\033[0;96m"
      C_BR_MAGENTA="\033[0;95m"
      C_BOLD="\033[1m"
      C_FAINT="\033[2m"
      C_SPECIAL_BLUE="\033[38;5;39;40m"

      if [ "${MULLE_LOGGING_TRAP:-}" != 'NO' ]
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


logging_initialize()
{
   logging_initialize_color
}


logging_initialize "$@"

fi
:
if ! [ ${MULLE_EXEKUTOR_SH+x} ]
then
MULLE_EXEKUTOR_SH='included'

[ -z "${MULLE_LOGGING_SH}" ] && \
   echo "mulle-logging.sh must be included before mulle-exekutor.sh" 2>&1 && exit 1



exekutor_print_arrow()
{
   local arrow

   [ -z "${MULLE_EXECUTABLE_PID}" ] && _internal_fail "MULLE_EXECUTABLE_PID not set"

   local pid

   pid="${BASHPID:-$$}"

   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE:-}"  \
        -a ${pid} -ne 0 \
        -a "${MULLE_EXECUTABLE_PID}" != "${pid}" ]
   then
      arrow="=[${pid}]=>"
   else
      arrow="==>"
   fi

   printf "%s" "${arrow}"
}


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
      printf " %s" "$1"  # what was the point of that ?
      shift
   done
   printf '\n'
}


exekutor_trace()
{
   local printer="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE:-}" ]
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

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE:-}" ]
      then
         ${printer} "$@" "${redirect}" "${output}" >&2
      else
         ${printer} "$@" "${redirect}" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi
}

function exekutor()
{
   exekutor_trace "exekutor_print" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


function rexekutor()
{
   exekutor_trace "exekutor_print" "$@"

   "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


function eval_exekutor()
{
   exekutor_trace "eval_exekutor_print" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   eval "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


function eval_rexekutor()
{
   exekutor_trace "eval_exekutor_print" "$@"

   eval "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


function redirect_exekutor()
{
   local output="$1"; shift

   exekutor_trace_output "exekutor_print" '>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   ( "$@" ) > "${output}"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}



function redirect_eval_exekutor()
{
   local output="$1"; shift

   exekutor_trace_output "eval_exekutor_print" '>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   ( eval "$@" ) > "${output}"

   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


redirect_append_exekutor()
{
   local output="$1"; shift

   exekutor_trace_output "exekutor_print" '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   ( "$@" ) >> "${output}"

   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


_redirect_append_eval_exekutor()
{
   local output="$1"; shift

   exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   ( eval "$@" ) >> "${output}"

   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


_append_tee_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   if [ ${ZSH_VERSION+x} ]
   then
      ( "$@" ) 2>&1 | tee -a "${teeoutput}" "${output}"
      MULLE_EXEKUTOR_RVAL=${pipestatus[1]}
   else
      ( "$@" ) 2>&1 | tee -a "${teeoutput}" "${output}"
      MULLE_EXEKUTOR_RVAL=${PIPESTATUS[0]}
   fi

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return "${MULLE_EXEKUTOR_RVAL}"
}


_append_tee_eval_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   if [ ${ZSH_VERSION+x} ]
   then
      ( eval "$@" ) 2>&1 | tee -a "${teeoutput}" "${output}"
      MULLE_EXEKUTOR_RVAL=${pipestatus[1]}
   else
      ( eval "$@" ) 2>&1 | tee -a "${teeoutput}" "${output}"
      MULLE_EXEKUTOR_RVAL=${PIPESTATUS[0]}
   fi

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return "${MULLE_EXEKUTOR_RVAL}"
}


function logging_tee_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" != 'YES' ]
   then
      exekutor_print "$@" >> "${teeoutput}"
   fi
   exekutor_print "$@" >> "${output}"

   _append_tee_exekutor "${output}" "${teeoutput}" "$@"
}


function logging_tee_eval_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" != 'YES' ]
   then
      eval_exekutor_print "$@" >> "${teeoutput}"
   fi
   eval_exekutor_print "$@" >> "${output}"

   _append_tee_eval_exekutor "${output}" "${teeoutput}" "$@"
}


function logging_redirekt_exekutor()
{
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" != 'YES' ]
   then
      exekutor_print "$@" >> "${output}"
   fi
   redirect_append_exekutor "${output}" "$@"
}


function logging_redirect_eval_exekutor()
{
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" != 'YES' ]
   then
      eval_exekutor_print "$@" >> "${output}"
   fi
   _redirect_append_eval_exekutor "${output}" "$@"
}


function rexecute_column_table_or_cat()
{
   local separator="$1"; shift

   local cmd
   local column_cmds="mulle-column column cat"

   if ! [ ${COLUMN+x} ]
   then
      .for cmd in ${column_cmds}
      .do
         if COLUMN="`command -v "${cmd}" `"
         then
            .break
         fi
      .done
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

fi
:
if ! [ ${MULLE_STRING_SH+x} ]
then
MULLE_STRING_SH='included'

[ -z "${MULLE_BASHGLOBAL_SH}" ]    && _fatal "mulle-bashglobal.sh must be included before mulle-file.sh"
[ -z "${MULLE_COMPATIBILITY_SH}" ] && _fatal "mulle-compatibility.sh must be included before mulle-string.sh"






function r_trim_whitespace()
{
   RVAL="$*"
   RVAL="${RVAL#"${RVAL%%[![:space:]]*}"}"
   RVAL="${RVAL%"${RVAL##*[![:space:]]}"}"
}




function r_upper_firstchar()
{
   case "${BASH_VERSION:-}" in
      [0123]*)
         RVAL="`printf "%s" "${1:0:1}" | tr '[:lower:]' '[:upper:]'`"
         RVAL="${RVAL}${1:1}"
      ;;

      *)
         if [ ${ZSH_VERSION+x} ]
         then
            RVAL="${1:0:1}"
            RVAL="${RVAL:u}${1:1}"
         else
            RVAL="${1^}"
         fi
      ;;
   esac
}


function r_capitalize()
{
   r_lowercase "$@"
   r_upper_firstchar "${RVAL}"
}


function r_uppercase()
{
   case "${BASH_VERSION:-}" in
      [0123]*)
         RVAL="`printf "%s" "$1" | tr '[:lower:]' '[:upper:]'`"
      ;;

      *)
         if [ ${ZSH_VERSION+x} ]
         then
            RVAL="${1:u}"
         else
            RVAL="${1^^}"
         fi
      ;;
   esac
}

function r_lowercase()
{
   case "${BASH_VERSION:-}" in
      [0123]*)
         RVAL="`printf "%s" "$1" | tr '[:upper:]' '[:lower:]'`"
      ;;

      *)
         if [ ${ZSH_VERSION+x} ]
         then
            RVAL="${1:l}"
         else
            RVAL="${1,,}"
         fi
      ;;
   esac
}


function r_identifier()
{
   RVAL="${1//-/_}" # __
   RVAL="${RVAL//[^a-zA-Z0-9]/_}"
   case "${RVAL}" in
      [0-9]*)
         RVAL="_${RVAL}"
      ;;
   esac
}


function r_extended_identifier()
{
   RVAL="${1//[^a-zA-Z0-9+:.=_-]/_}"
}




function r_append()
{
   RVAL="${1}${2}"
}

function r_concat()
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


r_remove_duplicate()
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
      RVAL="${RVAL//${dualescaped}${dualescaped}/${replacement}}"
   done
}


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

function r_colon_concat()
{
   r_concat "$1" "$2" ":"
   r_remove_ugly "${RVAL}" ":"
}

function r_comma_concat()
{
   r_concat "$1" "$2" ","
   r_remove_ugly "${RVAL}" ","
}

function r_semicolon_concat()
{
   r_concat "$1" "$2" ";"
}


function r_slash_concat()
{
   r_concat "$1" "$2" "/"
   r_remove_duplicate "${RVAL}" "/"
}





function r_list_remove()
{
   local sep="${3:- }"

   RVAL="${sep}$1${sep}//${sep}$2${sep}/}"
   RVAL="${RVAL##"${sep}"}"
   RVAL="${RVAL%%"${sep}"}"
}


function r_colon_remove()
{
   r_list_remove "$1" "$2" ":"
}


function r_comma_remove()
{
   r_list_remove "$1" "$2" ","
}


function r_add_line()
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


function r_remove_line()
{
   local lines="$1"
   local search="$2"

   local line

   local delim

   delim=""
   RVAL=

   .foreachline line in ${lines}
   .do
      if [ "${line}" != "${search}" ]
      then
         RVAL="${RVAL}${delim}${line}"
         delim=$'\n'
      fi
   .done
}


function  r_remove_line_once()
{
   local lines="$1"
   local search="$2"

   local line

   local delim

   delim=""
   RVAL=

   .foreachline line in ${lines}
   .do
      if [ -z "${search}" -o "${line}" != "${search}" ]
      then
         RVAL="${RVAL}${delim}${line}"
         delim=$'\n'
      else 
         search="" 
      fi
   .done
}


function  r_get_last_line()
{
  RVAL="$(sed -n '$p' <<< "$1")" # get last line
}


function r_remove_last_line()
{
   RVAL="$(sed '$d' <<< "$1")"  # remove last line
}


function find_item()
{
   local line="$1"
   local search="$2"
   local delim="${3:-,}"

   shell_is_extglob_enabled || _internal_fail "need extglob enabled"

   if [ ${ZSH_VERSION+x} ]
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


_find_empty_line_zsh()
{
   local lines="$1"

   case "${lines}" in 
      *$'\n'$'\n'*)
         return 0
      ;;
   esac

   return 1
}


_find_line_zsh()
{
   local lines="$1"
   local search="$2"

   if [ -z "${search:0:1}" ]
   then
      if [ -z "${lines:0:1}" ]
      then
         return 0
      fi

      _find_empty_line_zsh "${lines}"
      return $?
   fi

   local line

   .foreachline line in ${lines}
   .do
      if [ "${line}" = "${search}" ]
      then
         return 0
      fi
   .done

   return 1
}


function find_line()
{
   if [ ${ZSH_VERSION+x} ]
   then
      _find_line_zsh "$@"
      return $?
   fi

   local lines="$1"
   local search="$2"

   local escaped_lines
   local pattern

   printf -v escaped_lines "%q" "
${lines}
"

   printf -v pattern "%q" "${search}
"
   pattern="${pattern:2}"
   pattern="${pattern%???}"

   local rval

   rval=1

   shell_is_extglob_enabled || _internal_fail "extglob must be enabled"

   if [ ${ZSH_VERSION+x} ]
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


function r_count_lines()
{
   local array="$1"

   RVAL=0

   local line

   .foreachline line in ${array}
   .do
      RVAL=$((RVAL + 1))
   .done
}



function r_add_unique_line()
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


function r_remove_duplicate_lines()
{
   RVAL="`awk '!x[$0]++' <<< "$@"`"
}


function remove_duplicate_lines()
{
   awk '!x[$0]++' <<< "$@"
}


function remove_duplicate_lines_stdin()
{
   awk '!x[$0]++'
}


function r_reverse_lines()
{
   local lines="$1"

   local line
   local delim

   delim=""
   RVAL=

   IFS=$'\n'
   while read -r line
   do
      RVAL="${line}${delim}${RVAL}"
      delim=$'\n'
   done <<< "${lines}"
   IFS="${DEFAULT_IFS}"
}


is_yes()
{
   local s

   case "$1" in
      [yY][eE][sS]|[yY]|1|[oO][nN])
         return 0
      ;;
      [nN][oO]|[nN]|0|[oO][fF][fF]|"")
         return 1
      ;;

      *)
         return 4
      ;;
   esac
}







function r_escaped_grep_pattern()
{
   local s="$1"

   s="${s//\\/\\\\}"
   s="${s//\[/\\[}"
   s="${s//\]/\\]}"
   s="${s//\$/\\$}"
   s="${s//\*/\\*}"
   s="${s//\./\\.}"
   s="${s//\^/\\^}"
   s="${s//\|/\\|}"

   RVAL="$s"
}


function r_escaped_sed_pattern()
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
   s="${s//$'\n'/\\$'\n'}" # assume

   RVAL="$s"
}


function r_escaped_sed_replacement()
{
   local s="$1"

   s="${s//\\/\\\\}"
   s="${s//\//\\/}"
   s="${s//&/\\&}"
   s="${s//$'\n'/\\$'\n'}"

   RVAL="$s"
}


function r_escaped_spaces()
{
   RVAL="${1// /\\ }"
}


function r_escaped_backslashes()
{
   RVAL="${1//\\/\\\\}"
}


function r_escaped_singlequotes()
{
   local quote

   quote="'"
   RVAL="${1//${quote}/${quote}\"${quote}\"${quote}}"
}


function r_escaped_doublequotes()
{
   RVAL="${*//\\/\\\\}"
   RVAL="${RVAL//\"/\\\"}"
}

function r_unescaped_doublequotes()
{
   RVAL="${*//\\\"/\"}"
   RVAL="${RVAL//\\\\/\\}"
}


function r_escaped_shell_string()
{
   printf -v RVAL '%q' "$*"
}



function string_has_prefix()
{
  [ "${1#"$2"}" != "$1" ]
}


function string_has_suffix()
{
  [ "${1%"$2"}" != "$1" ]
}





function r_fnv1a_32()
{
   local i
   local len

   i=0
   len="${#1}"

   local hash
   local value

   hash=2166136261
   while [ $i -lt $len ]
   do
      printf -v value "%u" "'${1:$i:1}"
      hash=$(( ((hash ^ (value & 0xFF)) * 16777619) & 0xFFFFFFFF ))
      i=$(( i + 1 ))
   done

   RVAL=${hash}
}





_r_prefix_with_unquoted_string()
{
   local s="$1"
   local c="$2"

   local prefix
   local e_prefix
   local head

   head=""
   while :
   do
      prefix="${s%%"${c}"*}"             # a${
      if [ "${prefix}" = "${_s}" ]
      then
         RVAL=
         return 1
      fi

      e_prefix="${_s%%\\"${c}"*}"         # a\\${ or whole string if no match
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
      s="${s:${#e_prefix}}"
   done
}


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

   head=""

   while [ ${#_s} -ne 0 ]
   do
      _r_prefix_with_unquoted_string "${_s}" '${'
      found=$?
      prefix_opener="${RVAL}" # can be empty

      if ! _r_prefix_with_unquoted_string "${_s}" '}'
      then
         if [ ${found} -eq 0 ]
         then
            log_error "missing '}'"
            RVAL=
            return 1
         fi

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

      if [ ${found} -ne 0 ]
      then
         RVAL="${head}${_s}"
         return 0
      fi

      head="${head}${prefix_opener}"   # copy verbatim and continue

      _s="${_s:${#prefix_opener}}"
      _s="${_s#\$\{}"

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

      r_identifier "${identifier}"
      identifier="${RVAL}"

      if [ "${_expand}" = 'YES' ]
      then
         r_shell_indirect_expand "${identifier}"
         value="${RVAL:-${default_value}}"
      else
         value="${default_value}"
      fi
      head="${head}${value}"
   done

   RVAL="${head}"
   return 0
}


function r_expanded_string()
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

fi
:
if ! [ ${MULLE_INIT_SH+x} ]
then
MULLE_INIT_SH='included'

[ -z "${MULLE_STRING_SH}" ] && _fatal "mulle-string.sh must be included before mulle-init.sh"


function r_dirname()
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


function r_resolve_symlinks()
{
   local filepath

   RVAL="$1"

   if filepath="`readlink "${RVAL}"`"
   then
      r_dirname "${RVAL}"
      r_prepend_path_if_relative "${RVAL}" "${filepath}"
      r_resolve_symlinks "${RVAL}"
   fi
}


function r_get_libexec_dir()
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
   exedirpath="`( cd "${RVAL}" && pwd -P ) 2>/dev/null `"

   r_dirname "${exedirpath}"
   prefix="${RVAL}"

   local is_present

   RVAL="${prefix}/${MULLE_BASHFUNCTIONS_LIBEXEC_DIRNAME:-libexec}/${subdir}"
   if [ ! -f "${RVAL}/${matchfile}" ]
   then
      RVAL="${exedirpath}/src"
   else
      is_present="${RVAL}/${matchfile}"
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

   if [ "${is_present}" = "${RVAL}/${matchfile}" ]
   then
      return 0
   fi

   if [ ! -f "${RVAL}/${matchfile}" ]
   then
      printf "%s\n" "$0 fatal error: Could not find \"${subdir}\" libexec (${PWD#"${MULLE_USER_PWD}/"})" >&2
      exit 1
   fi
}


function r_escaped_eval_arguments()
{
   local arg
   local args
   local sep

   args=""
   for arg in "$@"
   do
      printf -v args "%s%s%q" "${args}" "${sep}" "${arg}"
      sep=" "
   done

   RVAL="${args}"
}


call_with_flags()
{
   local functionname="$1"; shift
   local flags="$1"; [ $# -ne 0 ] && shift

   if [ -z "${flags}" ]
   then
      ${functionname} "$@"
      return $?
   fi

   r_escaped_eval_arguments "$@"
   eval "'${functionname}'" "${flags}" "${RVAL}"
}

fi
:
if ! [ ${MULLE_OPTIONS_SH+x} ]
then
MULLE_OPTIONS_SH='included'

[ -z "${MULLE_LOGGING_SH}" ] && _fatal "mulle-logging.sh must be included before mulle-options.sh"




options_dump_env()
{
   log_trace "ARGS:${C_TRACE2} ${MULLE_ARGUMENTS}"
   log_trace "PWD :${C_TRACE2} `pwd -P 2> /dev/null`"
   log_trace "ENV :${C_TRACE2} `env | sort`"
   log_trace "LS  :${C_TRACE2} `ls -a1F`"
}

function options_setup_trace()
{
   local mode="$1"

   local rc

   if [ "${MULLE_FLAG_LOG_ENVIRONMENT:-}" = YES ]
   then
      options_dump_env
   fi

   rc=2
   case "${mode}" in
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

         if [ "${MULLE_TRACE_POSTPONE:-}" != 'YES' ]
         then
            PS4="+ ${ps4string} + "
         fi
         rc=0
      ;;
   esac

   log_set_trace_level

   return $rc
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

   if [ ! -z "${MULLE_TRACE:-}" ]
   then
      cat <<EOF
   -ld${S}${S}${DELIMITER}additional debug output
   -le${S}${S}${DELIMITER}additional environment debug output
   -lt${S}${S}${DELIMITER}trace through bash code
   -lx${S}${S}${DELIMITER}external command execution log output
EOF
   fi
}


function options_technical_flags_usage()
{
   _options_technical_flags_usage "$@" | sort
}


before_trace_fail()
{
   [ "${MULLE_TRACE:-}" = '1848' ] || \
      fail "option \"$1\" must be specified after -lt"
}


after_trace_warning()
{
   [ "${MULLE_TRACE:-}" = '1848' ] && \
      log_warning "warning: ${MULLE_EXECUTABLE_FAIL_PREFIX}: $1 after -lt invalidates -lt"
}


function options_technical_flags()
{
   local flag="$1"

   case "${flag}" in
      -n|--dry-run)
         MULLE_FLAG_EXEKUTOR_DRY_RUN='YES'
      ;;

      -s|--silent)
         MULLE_FLAG_LOG_TERSE='YES'
      ;;

      -v|--verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='VERBOSE'
      ;;

      -V)
         after_trace_warning "${flag}"

         MULLE_TRACE='VERBOSE'
         return # don't propagate
      ;;

      -ld|--log-debug)
         MULLE_FLAG_LOG_DEBUG='YES'
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

      -lt|--trace)
         MULLE_TRACE='1848'
         if [ ${ZSH_VERSION+x} ]
         then
            ps4string='%1x:%I' # TODO: fix for zsh
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
      ;;

      -lT)
         MULLE_TRACE='1848'
         if [ ${ZSH_VERSION+x} ]
         then
            ps4string='%1x:%I'
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         return # don't propagate
      ;;

      -tfpwd|--trace-full-pwd)
         before_trace_fail "${flag}"
         if [ ${ZSH_VERSION+x} ]
         then
            ps4string='%1x:%I \"\w\"'
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO} \"\w\"'
         fi
      ;;

      -tp|--trace-profile)
   
            case "${MULLE_UNAME}" in
               '')
                  _internal_fail 'MULLE_UNAME must be set by now'
               ;;
               linux)
                  if [ ${ZSH_VERSION+x} ]
                  then
                     ps4string='$(date "+%s.%N (%1x:%I)")'
                  else
                     ps4string='$(date "+%s.%N (${BASH_SOURCE[0]##*/}:${LINENO})")'
                  fi
               ;;
               *)
                  if [ ${ZSH_VERSION+x} ]
                  then
                     ps4string='$(date "+%s (%1x:%I)")'
                  else
                     ps4string='$(date "+%s (${BASH_SOURCE[0]##*/}:${LINENO})")'
                  fi
               ;;
            esac
         return # don't propagate
      ;;

      -tpwd|--trace-pwd)
         before_trace_fail "${flag}"
         if [ ${ZSH_VERSION+x} ]
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


      -T*T)
         MULLE_TRACE='1848'
         if [ ${ZSH_VERSION+x} ]
         then
            ps4string='%1x:%I'
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         flag="${flag%T}"
      ;;

      -v-|--no-verbose)
         MULLE_FLAG_LOG_TERSE=
      ;;

      -vv|--very-verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='FLUFF'
      ;;

      -vvv|--very-very-verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='TRACE'
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

   if [ ${MULLE_TECHNICAL_FLAGS+x} ]
   then
      MULLE_TECHNICAL_FLAGS="${MULLE_TECHNICAL_FLAGS} ${flag}"
   else
      MULLE_TECHNICAL_FLAGS="${flag}"
   fi

   return 0
}


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

   options_setup_trace "${MULLE_TRACE:-}" && set -x
}

fi
:
if ! [ ${MULLE_PATH_SH+x} ]
then
MULLE_PATH_SH='included'

[ -z "${MULLE_STRING_SH}" ] && _fatal "mulle-string.sh must be included before mulle-path.sh"




function r_filepath_cleaned()
{
   RVAL="$1"

   [ -z "${RVAL}" ] && return

   local old

   old=''

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

   s=""
   fallback=""

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

   if [ ! -z "${s}" ]
   then
      r_filepath_cleaned "${s}"
   else
      RVAL="${fallback:0:1}" # / make ./ . again
   fi
}




function r_basename()
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


function r_dirname()
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


function r_path_depth()
{
   local name="$1"

   local depth

   depth=0

   if [ ! -z "${name}" ]
   then
      depth=1

      while [ "$name" != "." -a "${name}" != '/' ]
      do
         r_dirname "${name}"
         name="${RVAL}"

         depth=$((depth + 1))
      done
   fi
   RVAL="${depth}"
}


function r_extensionless_basename()
{
   r_basename "$@"

   RVAL="${RVAL%.*}"
}


function r_extensionless_filename()
{
   RVAL="${RVAL%.*}"
}


function r_path_extension()
{
   r_basename "$@"
   case "${RVAL}" in
      *.*)
        RVAL="${RVAL##*.}"
        return
      ;;
   esac

   RVAL=""
}



__r_relative_path_between()
{
    RVAL=''
    [ $# -ge 1 ] && [ $# -le 2 ] || return 1

    current="${2:+"$1"}"
    target="${2:-"$1"}"

    [ "$target" != . ] || target=/

    target="/${target##/}"
    [ "$current" != . ] || current=/

    current="${current:="/"}"
    current="/${current##/}"
    appendix="${target##/}"
    relative=''

    while appendix="${target#"$current"/}"
        [ "$current" != '/' ] && [ "$appendix" = "$target" ]; do
        if [ "$current" = "$appendix" ]; then
            relative="${relative:-.}"
            RVAL="${relative#/}"
            return 0
        fi
        current="${current%/*}"
        relative="$relative${relative:+/}.."
    done

    RVAL="$relative${relative:+${appendix:+/}}${appendix#/}"
}


_r_relative_path_between()
{
   local a
   local b

   if [ "${MULLE_TRACE_PATHS_FLIP_X:-}" = 'YES' ]
   then
      set +x
   fi


   r_simplified_path "$1"
   a="${RVAL}"
   r_simplified_path "$2"
   b="${RVAL}"


   [ -z "${a}" ] && _internal_fail "Empty path (\$1)"
   [ -z "${b}" ] && _internal_fail "Empty path (\$2)"

   __r_relative_path_between "${b}" "${a}"   # flip args (historic)

   if [ "${MULLE_TRACE_PATHS_FLIP_X:-}" = 'YES' ]
   then
      set -x
   fi
}

function r_relative_path_between()
{
   local a="$1"
   local b="$2"


   case "${a}" in
      "")
         _internal_fail "First path is empty"
      ;;

      ../*|*/..|*/../*|..)
         _internal_fail "Path \"${a}\" mustn't contain .."
      ;;

      ./*|*/.|*/./*|.)
         _internal_fail "Filename \"${a}\" mustn't contain component \".\""
      ;;


      /*)
         case "${b}" in
            "")
               _internal_fail "Second path is empty"
            ;;

            ../*|*/..|*/../*|..)
               _internal_fail "Filename \"${b}\" mustn't contain \"..\""
            ;;

            ./*|*/.|*/./*|.)
               _internal_fail "Filename \"${b}\" mustn't contain \".\""
            ;;


            /*)
            ;;

            *)
               _internal_fail "Mixing absolute filename \"${a}\" and relative filename \"${b}\""
            ;;
         esac
      ;;

      *)
         case "${b}" in
            "")
               _internal_fail "Second path is empty"
            ;;

            ../*|*/..|*/../*|..)
               _internal_fail "Filename \"${b}\" mustn't contain component \"..\"/"
            ;;

            ./*|*/.|*/./*|.)
               _internal_fail "Filename \"${b}\" mustn't contain component \".\""
            ;;

            /*)
               _internal_fail "Mixing relative filename \"${a}\" and absolute filename \"${b}\""
            ;;

            *)
            ;;
         esac
      ;;
   esac

   _r_relative_path_between "${a}" "${b}"
}


function r_compute_relative()
{
   local name="${1:-}"

   local relative
   local depth

   r_path_depth "${name}"
   depth="${RVAL}"

   if [ "${depth}" -gt 1 ]
   then
      relative=".."
      while [ "$depth" -gt 2 ]
      do
         relative="${relative}/.."
         depth=$((depth - 1))
      done
   fi


   RVAL="${relative}"
}


function is_absolutepath()
{
   case "${1}" in
      /*|~*)
        return 0
      ;;

      *)
        return 1
      ;;
   esac
}


function is_relativepath()
{
   case "${1}" in
      ""|/*|~*)
        return 1
      ;;

      *)
        return 0
      ;;
   esac
}


function r_absolutepath()
{
  local directory="$1"
  local working="${2:-${PWD}}"

   case "${directory}" in
      "")
        RVAL=''
      ;;

      /*|~*)
        RVAL="${directory}"
      ;;

      *)
        RVAL="${working}/${directory}"
      ;;
   esac
}


function r_simplified_absolutepath()
{
  local directory="$1"
  local working="${2:-${PWD}}"

   case "${1}" in
      "")
        RVAL=''
      ;;

      /*|~*)
        r_simplified_path "${directory}"
      ;;

      *)
        r_simplified_path "${working}/${directory}"
      ;;
   esac
}

function r_symlink_relpath()
{
   local a
   local b

   r_absolutepath "$1"
   a="$RVAL"

   r_absolutepath "$2"
   b="$RVAL"

   _r_relative_path_between "${a}" "${b}"
}



_r_simplified_path()
{
   local filepath="$1"

   [ -z "${filepath}" ] && fail "empty path given"

   local i
   local last
   local result
   local remove_empty

   result=""
   last=""
   remove_empty='NO'  # remove trailing slashes

   .foreachpathcomponent i in ${filepath}
   .do
      case "$i" in
         \.)
           remove_empty='YES'
           .continue
         ;;

         \.\.)
           remove_empty='YES'

           if [ "${last}" = "|" ]
           then
              .continue
           fi

           if [ ! -z "${last}" -a "${last}" != ".." ]
           then
              r_remove_last_line "${result}"
              result="${RVAL}"
              r_get_last_line "${result}"
              last="${RVAL}"
              .continue
           fi
         ;;

         ~*)
            fail "Can't deal with ~ filepaths"
         ;;

         "")
            if [ "${remove_empty}" = 'NO' ]
            then
               last='|'
               result='|'
            fi
            .continue
         ;;
      esac

      remove_empty='YES'

      last="${i}"

      r_add_line "${result}" "${i}"
      result="${RVAL}"
   .done


   if [ -z "${result}" ]
   then
      RVAL="."
      return
   fi

   if [ "${result}" = '|' ]
   then
      RVAL="/"
      return
   fi

   RVAL="${result//\|/}"
   RVAL="${RVAL//$'\n'//}"
   RVAL="${RVAL%/}"
}


function r_simplified_path()
{
   case "${1}" in
      ""|".")
         RVAL="."
      ;;

      */|*\.\.*|*\./*|*/\.)
         if [ "${MULLE_TRACE_PATHS_FLIP_X:-}" = 'YES' ]
         then
            set +x
         fi

         _r_simplified_path "$@"

         if [ "${MULLE_TRACE_PATHS_FLIP_X:-}" = 'YES' ]
         then
            set -x
         fi
      ;;

      *)
         RVAL="$1"
      ;;
   esac
}


function r_assert_sane_path()
{
   r_simplified_path "$1"

   case "${RVAL}" in
      \$*|~|"${HOME}"|..|.)
         fail "refuse unsafe path \"$1\""
      ;;

      /tmp/*)
      ;;

      ""|/*)
         local filepath

         filepath="${RVAL}"
         r_path_depth "${filepath}"
         if [ "${RVAL}" -le 2 ]
         then
            fail "Refuse suspicious path \"$1\""
         fi
         RVAL="${filepath}"
      ;;

      *)
         if [ "${RVAL}" = "${HOME}" ]
         then
            fail "refuse unsafe path \"$1\""
         fi
      ;;
   esac
}

fi
:
if ! [ ${MULLE_FILE_SH+x} ]
then
MULLE_FILE_SH='included'

[ -z "${MULLE_BASHGLOBAL_SH}" ] && _fatal "mulle-bashglobal.sh must be included before mulle-file.sh"
[ -z "${MULLE_PATH_SH}" ]       && _fatal "mulle-path.sh must be included before mulle-file.sh"
[ -z "${MULLE_EXEKUTOR_SH}" ]   && _fatal "mulle-exekutor.sh must be included before mulle-file.sh"



function mkdir_if_missing()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if [ -d "$1" ]
   then
      return 0
   fi

   local rval

   exekutor mkdir -p "$1"
   rval="$?"

   if [ "${rval}" -eq 0 ]
   then
      log_fluff "Created directory \"$1\" (${PWD#"${MULLE_USER_PWD}/"})"
      return 0
   fi

   if [ -L "$1" ]
   then
      r_resolve_symlinks "$1"
      if [ ! -d "${RVAL}" ]
      then
         fail "failed to create directory \"$1\" as a symlink to a file is there"
      fi
      return 0
   fi

   if [ -f "$1" ]
   then
      fail "failed to create directory \"$1\" because a file is there"
   fi
   fail "failed to create directory \"$1\" from $PWD ($rval)"
}


function r_mkdir_parent_if_missing()
{
   local filename="$1"

   local dirname

   r_dirname "${filename}"
   dirname="${RVAL}"

   case "${dirname}" in
      ""|\.)
         return 1
      ;;
   esac

   mkdir_if_missing "${dirname}"
   RVAL="${dirname}"
   return 0
}


function dir_is_empty()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if [ ! -d "$1" ]
   then
      return 2
   fi

   local empty

   empty="`ls -A "$1" 2> /dev/null`"
   [ -z "$empty" ]
}


rmdir_safer()
{
   [ -z "$1" ] && _internal_fail "empty path"

   [ $"PWD" = "${directory}" ] && fail "Refuse to remove PWD"

   if [ -d "$1" ]
   then
      r_assert_sane_path "$1"

      case "${MULLE_UNAME}" in
         'android'|'sunos')
            exekutor chmod -R ugo+wX "${RVAL}" 2> /dev/null
         ;;
         *)
            exekutor chmod -R ugo+wX "${RVAL}"  || fail "Failed to make \"${RVAL}\" writable"
         ;;
      esac
      exekutor rm -rf "${RVAL}"  >&2 || fail "failed to remove \"${RVAL}\""
   fi
}


rmdir_if_empty()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if dir_is_empty "$1"
   then
      exekutor rmdir "$1"  >&2 || fail "failed to remove $1"
   fi
}


_create_file_if_missing()
{
   local filepath="$1" ; shift

   [ -z "${filepath}" ] && _internal_fail "empty path"

   if [ -f "${filepath}" ]
   then
      return
   fi

   local directory

   r_dirname "${filepath}"
   directory="${RVAL}"
   if [ ! -z "${directory}" ]
   then
      mkdir_if_missing "${directory}"
   fi

   log_fluff "Creating \"${filepath}\""
   if [ ! -z "$*" ]
   then
      redirect_exekutor "${filepath}" printf "%s\n" "$*" || fail "failed to create \"{filepath}\""
   else
      exekutor touch "${filepath}"  || fail "failed to create \"${filepath}\""
   fi
}


function create_file_if_missing()
{
   _create_file_if_missing "$1" "# intentionally blank file"
}


function merge_line_into_file()
{
  local line="$1"
  local filepath="$2"

  if grep -F -q -x "${line}" "${filepath}" > /dev/null 2>&1
  then
     return
  fi
  redirect_append_exekutor "${filepath}" printf "%s\n" "${line}"
}


_remove_file_if_present()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   if ! rm -f "$1" 2> /dev/null
   then
      case "${MULLE_UNAME}" in
         'sunos')
            exekutor chmod u+w "$1" 2> /dev/null
         ;;
         *)
            exekutor chmod u+w "$1"  || fail "Failed to make $1 writable"
         ;;
      esac
      exekutor rm -f "$1"      || fail "failed to remove \"$1\""
   else
      exekutor_trace "exekutor_print" rm -f "$1"
   fi
   return 0
}


remove_file_if_present()
{
   if [ -e "$1"  -o -L "$1" ] && _remove_file_if_present "$1"
   then
      log_fluff "Removed \"${1#${PWD}/}\" (${PWD#"${MULLE_USER_PWD}/"})"
      return 0
   fi
   return 1
}


r_uuidgen()
{
   local i

   local -a v

   if [ ${ZSH_VERSION+x} ]
   then
      if [ -e "/dev/urandom" ]
      then
         RANDOM="`od -vAn -N4 -t u4 < /dev/urandom`"
      else
         if [ -e "/dev/random" ]
         then
            RANDOM="`od -vAn -N4 -t u4 < /dev/random`"
         else
            sleep 1 # need something unique between two calls
            RANDOM="`date +%s`"
         fi
      fi
   fi

   for i in 1 2 3 4 5 6 7 8
   do
      v[$i]=$(($RANDOM+$RANDOM))
   done
   v[4]=$((${v[4]}|16384))
   v[4]=$((${v[4]}&20479))
   v[5]=$((${v[5]}|32768))
   v[5]=$((${v[5]}&49151))
   printf -v RVAL "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" \
                  ${v[1]} ${v[2]} ${v[3]} ${v[4]} \
                  ${v[5]} ${v[6]} ${v[7]} ${v[8]}
}


_make_tmp_in_dir_mktemp()
{
   local tmpdir="$1"
   local name="$2"
   local filetype="$3"
   local extension="$4"

   case "${filetype}" in
      *d*)
         TMPDIR="${tmpdir}" exekutor mktemp -d "${name}-XXXXXXXX${extension}"
      ;;

      *)
         TMPDIR="${tmpdir}" exekutor mktemp "${name}-XXXXXXXX${extension}"
      ;;
   esac
}


_r_make_tmp_in_dir_uuidgen()
{
   local UUIDGEN="$1"; shift

   local tmpdir="$1"
   local name="$2"
   local filetype="${3:-f}"
   local extension="$4"

   local MKDIR
   local TOUCH

   MKDIR="$(command -v mkdir)"
   TOUCH="$(command -v touch)"

   [ -z "${MKDIR}" ] && fail "No \"mkdir\" found in PATH ($PATH)"
   [ -z "${TOUCH}" ] && fail "No \"touch\" found in PATH ($PATH)"

   local uuid
   local fluke

   fluke=0
   RVAL=''

   while :
   do
      if [ -z "${UUIDGEN}" ]
      then
         r_uuidgen
         uuid="${RVAL}"
      else
         uuid="`${UUIDGEN}`" || fail "uuidgen failed"
      fi

      RVAL="${tmpdir}/${name}-${uuid}${extension}"

      case "${filetype}" in
         *d*)
            exekutor "${MKDIR}" "${RVAL}" 2> /dev/null && return 0
         ;;

         *)
            exekutor "${TOUCH}" "${RVAL}" 2> /dev/null && return 0
         ;;
      esac

      if [ ! -e "${RVAL}" ]
      then
         fluke=$((fluke + 1 ))
         if [ "${fluke}" -gt 20 ]
         then
            fail "Could not (even repeatedly) create \"${RVAL}\" (${filetype:-f})"
         fi
      fi
   done
}


_r_make_tmp_in_dir()
{
   local tmpdir="$1"
   local name="$2"
   local filetype="${3:-f}"

   mkdir_if_missing "${tmpdir}"

   [ ! -w "${tmpdir}" ] && fail "${tmpdir} does not exist or is not writable"

   name="${name:-${MULLE_EXECUTABLE_NAME}}"
   name="${name:-mulle}"

   if [ ! -z "${extension}" ]
   then
      extension=".${extension}"
   fi 

   _r_make_tmp_in_dir_uuidgen "" "${tmpdir}" "${name}" "${filetype}" "${extension}"
   return $?
}


function r_make_tmp()
{
   local name="$1"
   local filetype="${2:-f}"
   local extension="$3"

   local tmpdir

   tmpdir=
   case "${MULLE_UNAME}" in
      darwin)
      ;;

      *)
         tmpdir="${TMP:-${TMPDIR:-${TMP_DIR:-}}}"
         r_filepath_cleaned "${tmpdir}"
         tmpdir="${RVAL}"
      ;;
   esac
   tmpdir="${tmpdir:-/tmp}"

   _r_make_tmp_in_dir "${tmpdir}" "${name}" "${filetype}" "${extension}"
}


function r_make_tmp_file()
{
   r_make_tmp "$1" "f" "$2"
}


function r_make_tmp_directory()
{
   r_make_tmp "$1" "d" "$2"
}



function r_resolve_all_path_symlinks()
{
   local filepath="$1"

   local resolved

   r_resolve_symlinks "${filepath}"
   resolved="${RVAL}"

   local filename
   local directory

   r_dirname "${resolved}"
   directory="${RVAL}"

   case "${directory}" in
      ''|'/')
         RVAL="${resolved}"
      ;;

      *)
         r_basename "${resolved}"
         filename="${RVAL}"
         r_resolve_all_path_symlinks "${directory}"
         r_filepath_concat "${RVAL}" "${filename}"
      ;;
   esac
}



_r_canonicalize_dir_path()
{
   RVAL="`
   (
     cd "$1" 2>/dev/null &&
     pwd -P
   )`"
}


_r_canonicalize_file_path()
{
   local component
   local directory

   r_basename "$1"
   component="${RVAL}"
   r_dirname "$1"
   directory="${RVAL}"

   if ! _r_canonicalize_dir_path "${directory}"
   then
      return 1
   fi

   RVAL="${RVAL}/${component}"
   return 0
}


function r_canonicalize_path()
{
   [ -z "$1" ] && _internal_fail "empty path"

   r_resolve_symlinks "$1"
   if [ -d "${RVAL}" ]
   then
      _r_canonicalize_dir_path "${RVAL}"
   else
      _r_canonicalize_file_path "${RVAL}"
   fi
}


function r_physicalpath()
{
   if [ -d "$1" ]
   then
      RVAL="`( cd "$1" && pwd -P ) 2>/dev/null `"
      return $?
   fi

   local dir
   local file

   r_dirname "$1"
   dir="${RVAL}"

   r_basename "$1"
   file="${RVAL}"

   if ! r_physicalpath "${dir}"
   then
      RVAL=
      return 1
   fi

   r_filepath_concat "${RVAL}" "${file}"
}


function r_realpath()
{
   [ -e "$1" ] || fail "only use r_realpath on existing files ($1)"

   r_resolve_symlinks "$1"
   r_canonicalize_path "${RVAL}"
}

function create_symlink()
{
   local source="$1"       # URL of the clone
   local symlink="$2"      # symlink of this clone (absolute or relative to $PWD)
   local absolute="${3:-NO}"

   [ -e "${source}" ]     || fail "${C_RESET}${C_BOLD}${source}${C_ERROR} does not exist (${PWD#"${MULLE_USER_PWD}/"})"
   [ ! -z "${absolute}" ] || fail "absolute must be YES or NO"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN:-}" = 'YES' ]
   then
      return
   fi

   r_absolutepath "${source}"
   r_realpath "${RVAL}"
   source="${RVAL}"        # resolve symlinks


   local directory
   r_dirname "${symlink}"
   directory="${RVAL}"

   mkdir_if_missing "${directory}"
   r_realpath "${directory}"
   directory="${RVAL}"  # resolve symlinks

   if [ "${absolute}" = 'NO' ]
   then
      r_symlink_relpath "${source}" "${directory}"
      source="${RVAL}"
   fi

   local oldlink

   oldlink=""
   if [ -L "${symlink}" ]
   then
      oldlink="`readlink "${symlink}"`"
   fi

   if [ -z "${oldlink}" -o "${oldlink}" != "${source}" ]
   then
      exekutor ln -s -f "${source}" "${symlink}" >&2 || \
         fail "failed to setup symlink \"${symlink}\" (to \"${source}\")"
   fi
}



function modification_timestamp()
{
   case "${MULLE_UNAME}" in
      macos|*bsd|dragonfly)
         stat -f "%m" "$1"
      ;;

      *)
         stat --printf "%Y\n" "$1"
      ;;
   esac
}


function lso()
{
   ls -ald "$@" | \
   awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print }' | \
   awk '{print $1}'
}



function file_is_binary()
{
   local result

   case "${MULLE_UNAME}" in
      sunos)
         result="`file "$1"`"
         case "${result}" in
            *\ text*|*\ script|*\ document)
               return 1
            ;;
         esac
         return 0
      ;;
   esac

   result="`file -b --mime-encoding "$1"`"
   [ "${result}" = "binary" ]
}


function file_size_in_bytes()
{
   if [ ! -f "$1" ]
   then
      return 1
   fi

   case "${MULLE_UNAME}" in
      darwin|*bsd|dragonfly)
         stat -f '%z' "$1"
      ;;

      *)
         stat -c '%s' -- "$1"
      ;;
   esac
}



function dir_has_files()
{
   local dirpath="$1"; shift

   case "${MULLE_UNAME}" in
      sunos)
         local lines

         if ! lines="`( rexekutor cd "${dirpath}" && rexekutor ls -1 ) 2> /dev/null `"
         then
            return 1
         fi

         local line

         .foreachline line in ${lines}
         .do
            case "${line}" in
               '.'|'..')
                  .continue
               ;;

               *)
                  case "$1" in
                     f)
                        [ ! -f "${dirpath}/${line}" ] && .continue
                     ;;

                     d)
                        [ ! -d "${dirpath}/${line}" ] && .continue
                     ;;

                     l)
                        [ ! -L "${dirpath}/${line}" ] && .continue
                     ;;
                  esac

                  return 0
               ;;
            esac
         .done
         return 1
      ;;
   esac

   local flags

   case "$1" in
      f)
         flags="-type f"
         shift
      ;;

      d)
         flags="-type d"
         shift
      ;;

      l)
         flags="-type l"
         shift
      ;;
   esac

   local empty

   empty="`rexekutor find "${dirpath}" -xdev \
                                       -mindepth 1 \
                                       -maxdepth 1 \
                                       -name "[a-zA-Z0-9_-]*" \
                                       ${flags} \
                                       "$@" \
                                       -print 2> /dev/null`"
   [ ! -z "$empty" ]
}


function dir_list_files()
{
   local directory="$1"
   local pattern="${2:-*}"
   local flagchars="${3:-}"

   [ ! -z "${directory}" ] || _internal_fail "directory is empty"

   log_debug "flagchars=${flagchars}"

   case "${MULLE_UNAME}" in
      sunos)
         local line
         local dirpath
         local lines

         for dirpath in ${directory}
         do
            lines="`( cd "${dirpath}"; ls -1 ) 2> /dev/null`"

            .foreachline line in ${lines}
            .do
               case "${line}" in
                  '.'|'..')
                     .continue
                  ;;

                  *)
                     if [[ $line != ${pattern} ]]
                     then
                        continue
                     fi

                     local match 
                     
                     match='YES'
                     if [ ! -z "${flagchars}" ]
                     then
                        match='NO'
                     fi

                     case "${flagchars}" in
                        *f*)
                           [ -f "${dirpath}/${line}" ] && match='YES'
                        ;;
                     esac
                     case "${flagchars}" in
                        *d*)
                           [ -d "${dirpath}/${line}" ] && match='YES'
                        ;;
                     esac
                     case "${flagchars}" in
                        *l*)
                           [ ! -L "${dirpath}/${line}" ] && match='YES'
                        ;;
                     esac

                     if [ "${match}" = 'NO' ]
                     then
                        .continue
                     fi
                  ;;
               esac
               printf "%s\n" "${dirpath}/${line}"
            .done
         done

         IFS=' '$'\t'$'\n'
         return
      ;;
   esac


   local flags

   if [ ! -z "${flagchars}" ]
   then
      case "${flagchars}" in
         *f*)
            flags="-type f"
         ;;
      esac
      case "${flagchars}" in
         *d*)
            r_concat "${flags}" "-type d" " -o "
            flags="${RVAL}"
         ;;
      esac
      case "${flagchars}" in
         *l*)
            r_concat "${flags}" "-type l"  " -o "
            flags="${RVAL}"
         ;;
      esac

      flags="\\( ${flags} \\)"
   fi

   IFS=$'\n'
   eval_rexekutor find ${directory} -xdev \
                                    -mindepth 1 \
                                    -maxdepth 1 \
                                    -name "'${pattern:-*}'" \
                                    ${flags} \
                                    -print  | sort -n
   IFS=' '$'\t'$'\n'
}


function dirs_contain_same_files()
{
   log_entry "dirs_contain_same_files" "$@"

   local etcdir="$1"
   local sharedir="$2"

   if [ ! -d "${etcdir}" -o ! -e "${etcdir}" ]
   then
      _internal_fail "Both directories \"${etcdir}\" and \"${sharedir}\" need to exist"
   fi

   etcdir="${etcdir%%/}"
   sharedir="${sharedir%%/}"

   local DIFF

   if ! DIFF="`command -v diff`"
   then
      fail "diff command not installed"
   fi

   local etcfile
   local sharefile
   local filename 

   .foreachline sharefile in `find ${sharedir} \! -type d -print`
   .do
      filename="${sharefile#${sharedir}/}"
      etcfile="${etcdir}/${filename}"

      if ! "${DIFF}" -b "${etcfile}" "${sharefile}" > /dev/null 2>&1
      then
         return 2
      fi
   .done

   .foreachline etcfile in `find ${etcdir} \! -type d -print`
   .do
      filename="${etcfile#${etcdir}/}"
      sharefile="${sharedir}/${filename}"

      if [ ! -e "${sharefile}" ]
      then
         return 2
      fi
   .done

   return 0
}



function inplace_sed()
{
   local tmpfile
   local args
   local filename

   local rval 


   case "${MULLE_UNAME}" in
      darwin|*bsd|sun*|dragonfly)

         while [ $# -ne 1 ]
         do
            r_escaped_shell_string "$1"
            r_concat "${args}" "${RVAL}"
            args="${RVAL}"
            shift
         done

         filename="$1"

         if [ ! -w "${filename}" ]
         then
            if [ ! -e "${filename}" ]
            then
               fail "\"${filename}\" does not exist"
            fi
            fail "\"${filename}\" is not writable"
         fi


         r_make_tmp
         tmpfile="${RVAL}"

         redirect_eval_exekutor "${tmpfile}" 'sed' "${args}" "'${filename}'"
         rval=$?
         if [ $rval -eq 0 ]
         then
            exekutor cp "${tmpfile}" "${filename}"
         fi
         _remove_file_if_present "${tmpfile}" # don't fluff log :)
      ;;

      *)
         exekutor sed -i'' "$@"
         rval=$?
      ;;
   esac

   return ${rval}
}

fi
:
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


function r_add_line_lf()
{
   local lines="$1"
   local line="$2"

   line="${line}"$'\n'

   if [ -z "${lines:0:1}" ]
   then
      RVAL="${line}"
   fi
   RVAL="${lines}${line}"
}

function r_get_line_at_index()
{
   local array="$1"
   local i="${2:-0}"


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


function r_lines_in_range()
{
   local array="$1"
   local i="$2"
   local n="$3"

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


function r_assoc_array_get()
{
   local array="$1"
   local key="$2"


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


function assoc_array_all_keys()
{
   local array="$1"

   sed -n 's/^\([^=]*\)=.*$/\1/p' <<< "${array}"
}


function assoc_array_all_values()
{
   local array="$1"

   sed -n 's/^[^=]*=\(.*\)$/\1/p' <<< "${array}"
}


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


function assoc_array_merge_with_array()
{
   local array1="$1"
   local array2="$2"

   printf "%s%s\n" "${array2}" "${array1}" | sort -u -t'=' -k1,1
}


function assoc_array_augment_with_array()
{
   local array1="$1"
   local array2="$2"

   printf "%s%s\n" "${array1}" "${array2}" | sort -u -t'=' -k1,1
}

fi
:

if ! [ ${MULLE_CASE_SH+x} ]
then
MULLE_CASE_SH='included'


_r_tweaked_de_camel_case()
{
   local s="$1"

   local output
   local state
   local collect

   local c

   s="${s//ObjC/Objc}"

   state='start'
   while [ ! -z "${s}" ]
   do
      c="${s:0:1}"
      s="${s:1}"

      case "${state}" in
         'start')
            case "${c}" in
               [A-Z])
                  state="upper";
                  collect="${collect}${c}"
                  continue
               ;;

               *)
                  state="lower"
               ;;
            esac
         ;;

         'upper')
            case "${c}" in
               [A-Z])
                  collect="${collect}${c}"
                  continue
               ;;

               *)
                  if [ ! -z "${output}" -a ! -z "${collect}" ]
                  then
                     if [ ! -z "${collect:1}" ]
                     then
                        output="${output}_${collect%?}_${collect#${collect%?}}"
                     else
                        output="${output}_${collect}"
                     fi
                  else
                     if [ -z "${output}" -a "${#collect}" -gt 1 ]
                     then
                        output="${collect%?}_${collect: -1}"
                     else
                        output="${output}${collect}"
                     fi
                  fi
                  collect=""
                  state="lower"
               ;;
            esac
         ;;

         'lower')
            case "${c}" in
               [A-Z])
                  output="${output}${collect}"
                  collect="${c}"
                  state="upper"
                  continue
               ;;
            esac
         ;;
      esac

      output="${output}${c}"
   done

   if [ ! -z "${output}" -a ! -z "${collect}" ]
   then
      output="${output}_${collect}"
   else
      output="${output}${collect}"
   fi

   RVAL="${output}"
}


function r_tweaked_de_camel_case()
{
   LC_ALL=C _r_tweaked_de_camel_case "$@"
}


function r_de_camel_case_identifier()
{
   r_tweaked_de_camel_case "$1"
   r_identifier "${RVAL}"
}


function r_smart_downcase_identifier()
{
   r_de_camel_case_identifier "$1"
   r_lowercase "${RVAL}"
}


function r_smart_upcase_identifier()
{
   r_uppercase "$1"
   r_identifier "${RVAL}"

   if [ "${RVAL}" = "$1" ]
   then
      return
   fi

   r_de_camel_case_identifier "$1"
   r_uppercase "${RVAL}"
}


function r_smart_file_upcase_identifier()
{
   local s="$1"

   s="${s//-/__}"

   r_uppercase "$s"
   r_identifier "${RVAL}"

   if [ "${RVAL}" = "$s" ]
   then
      return
   fi

   r_de_camel_case_identifier "$s"
   r_uppercase "${RVAL}"
}



fi

:
if ! [ ${MULLE_PARALLEL_SH+x} ]
then
MULLE_PARALLEL_SH='included'

[ -z "${MULLE_FILE_SH}" ] && _fatal "mulle-file.sh must be included before mulle-parallel.sh"





very_short_sleep()
{
   local us="$1"

   us="${us:0:6}"

   local zeroes="000000"

   us="0.${zeroes:${#us}}${us}"
   us="${us%%0}"
   case "${MULLE_UNAME}" in 
      darwin|*bsd|dragonfly)
      ;;

      *)
         us="${us}s"
      ;;
   esac
   LC_ALL=C sleep "${us}"
}  


r_get_core_count()
{
   if ! [ ${MULLE_CORES+x} ]
   then
      MULLE_CORES="`PATH="$PATH:/usr/sbin:/sbin" nproc 2> /dev/null`"
      if [ -z "${MULLE_CORES}" ]
      then
         MULLE_CORES="`PATH="$PATH:/usr/sbin:/sbin" sysctl -n hw.ncpu 2> /dev/null`"
      fi

      if [ -z "${MULLE_CORES}" ]
      then
         MULLE_CORES=4
         log_verbose "Unknown core count, setting it to 4 as default"
         RVAL=${MULLE_CORES}
         return 2
      fi
   fi

   RVAL=${MULLE_CORES}
   return 0
}


r_convenient_max_load_average()
{
   local cores="$1"

   if [ -z "${cores}" ]
   then
      r_get_core_count
      cores="${RVAL}"
   fi

   case "${MULLE_UNAME}" in
      linux)
         RVAL=$((cores * 6))
      ;;

      *)
         RVAL=$((cores * 2))
      ;;
   esac
}


wait_for_available_job()
{
   log_entry "wait_for_available_job" "$@"

   local maxjobs="${1:-8}"

   local running
   local count
   local us

   us=1000 # start with 1 ms

   while :
   do
      running=($(jobs -pr))  #  http://mywiki.wooledge.org/BashFAQ/004
      count=${#running[@]}

      if [ ${count} -le ${maxjobs} ]
      then
         log_debug "Currently only ${count} jobs run, spawn another"
         break
      fi

      log_debug "Waiting $us us on jobs to finish (${#running[@]})"

      very_short_sleep $us
      us=$((us + us))
      if [ ${us} -gt 500000 ]
      then
         us=500000
      fi
   done
}


get_current_load_average()
{
   case "${MULLE_UNAME}" in
      'freebsd'|'darwin')
         sysctl -n vm.loadavg | sed -n -e 's/.*{[ ]*\([0-9]*\).*/\1/p'
      ;;

      'mingw'|'msys')
         echo "7"  # no way to know
      ;;

      *)
         uptime | sed -n -e 's/.*average[s]*:[ ]*\([0-9]*\).*/\1/p'
      ;;
   esac
}


r_available_core_count()
{
   log_entry "r_available_core_count" "$@"

   local maxaverage="$1"

   local cores

   r_get_core_count
   cores="${RVAL}"

   if [ -z "${maxaverage}" ]
   then
      r_convenient_max_load_average "${cores}"
      maxaverage="${RVAL}"
   fi

   local loadavg
   local available

   loadavg="`get_current_load_average`"
   available="$(( cores - loadavg ))"
   if [ ${available} -lt 1 ]
   then
      available="1"
   fi

   RVAL="${available}"
}


wait_for_load_average()
{
   log_entry "wait_for_load_average" "$@"

   local maxaverage="${1:-8}"

   local loadavg

   while :
   do
      loadavg="`get_current_load_average`"
      if [ "${loadavg:-0}" -le ${maxaverage} ]
      then
         break
      fi
      log_debug "Waiting on load average to come down"

      very_short_sleep
   done
}


function __parallel_begin()
{
   log_entry "__parallel_begin" "$@"

   _parallel_maxjobs="${1:-0}"

   _parallel_jobs=0
   _parallel_fails=0

   r_make_tmp "mulle-parallel" || exit 1
   _parallel_statusfile="${RVAL}"

   if [ ${_parallel_maxjobs} -eq 0 ]
   then
      _parallel_maxjobs="${MULLE_PARALLEL_MAX_JOBS:-0}"
      if [ ${_parallel_maxjobs} -eq 0 ]
      then
         r_get_core_count
         _parallel_maxjobs="${RVAL}"
      fi
   fi
}


__parallel_status()
{
   log_entry "__parallel_status" "$@"

   local rval="$1"; shift

   [ -z "${_parallel_statusfile}" ] && _internal_fail "_parallel_statusfile must be defined"

   if [ $rval -ne 0 ]
   then
      log_warning "warning: Parallel job \"$*\" failed with $rval"
      redirect_append_exekutor "${_parallel_statusfile}" printf "%s\n" "${rval};$*"
   fi
}


function __parallel_execute()
{
   log_entry "__parallel_execute" "$@"

   wait_for_available_job "${_parallel_maxjobs}"
   _parallel_jobs=$(($_parallel_jobs + 1))

   log_debug "Running job #${_parallel_jobs}: $*"

   (
      local rval

      ( exekutor "$@" ) # run in subshell to capture exit code
      __parallel_status $? "$@"
   ) &
}


function __parallel_end()
{
   log_entry "__parallel_end" "$@"

   wait

   _parallel_fails="`exekutor wc -l "${_parallel_statusfile}" | awk '{ printf $1 }'`"

   log_setting "_parallel_jobs : ${_parallel_jobs}"
   log_setting "_parallel_fails: ${_parallel_fails}"
   log_setting "${_parallel_statusfile} : `exekutor cat "${_parallel_statusfile}"`"

   exekutor rm "${_parallel_statusfile}"

   if [ "${_parallel_fails:-1}" -ne 0 ]
   then
      log_warning "warning: ${_parallel_fails} parallel jobs failed"
      return 1
   fi

   return 0
}



function parallel_execute()
{
   log_entry "parallel_execute" "$@"

   local arguments="$1"; shift

   local _parallel_statusfile
   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails

   [ $# -eq 0 ] && _internal_fail "missing commandline"

   __parallel_begin

   local argument

   shell_disable_glob

   .foreachline argument in ${arguments}
   .do
      __parallel_execute "$@" "${argument}"
   .done

   shell_enable_glob

   __parallel_end
}

fi
:
if ! [ ${MULLE_URL_SH+x} ]
then
MULLE_URL_SH='included'




function r_url_encode()
{
   local s="$1"

   local c
   local safe
   local encode

   RVAL=
   while :
   do
      safe="${s%%[^a-zA-Z0-9.~_-]*}"
      RVAL="${RVAL}${safe}"
      s="${s#"${safe}"}"
      if [ -z "${s}" ]
      then
         break
      fi

      c="${s:0:1}"
      s="${s:1}"
      printf -v encode '%%%02X' "'${c}'"
      RVAL="${RVAL}${encode}"
   done
}


function r_url_remove_scheme()
{
   RVAL="${1#*:}"
}


function r_url_remove_query()
{
   RVAL="${1%\?*}"
}


function r_url_remove_fragment()
{
   RVAL="${1%#*}"
}

function url_has_file_compression_extension()
{
   r_url_remove_query "$1"
   case "${RVAL}" in
      *.z|*.gz|*.bz2|*.xz)
         return 0
      ;;
   esac
   return 1
}


function r_url_remove_file_compression_extension()
{
   local url="$1"

   r_url_remove_query "${url}"
   url="${RVAL}"

   RVAL="${url%.z}"
   [ "${RVAL}" != "$url" ] && return
   RVAL="${url%.gz}"
   [ "${RVAL}" != "$url" ] && return
   RVAL="${url%.bz2}"
   [ "${RVAL}" != "$url" ] && return
   RVAL="${url%.xz}"
}



MULLE_URI_REGEX='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?(/([^?#]*))(\?([^#]*))?(#(.*))?'


function __url_parse()
{
   log_entry "__url_parse" "$@"

   local url="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      setopt local_options BASH_REMATCH
      setopt local_options KSH_ARRAYS
   fi

   case "${url}" in
      *://*)
         if ! [[ "${url}" =~ ${MULLE_URI_REGEX} ]]
         then
            return 1
         fi

            _scheme="${BASH_REMATCH[2]}"
            _userinfo="${BASH_REMATCH[6]}"
            _host="${BASH_REMATCH[7]}"
            _port="${BASH_REMATCH[9]}"
            _path="${BASH_REMATCH[10]}"
            _query="${BASH_REMATCH[13]}"
            _fragment="${BASH_REMATCH[15]}"

         if [ -z "${_userinfo}${_host}${_port}" -a "${_path:0:3}" = "///" ]
         then
            _path="${_path#//}"
         fi
      ;;

      *:*)
         _scheme=
         _host="${url%:*}"
         r_url_remove_query "${url##*:}"
         r_url_remove_fragment "${RVAL}"
         _path=${RVAL}
         _userinfo=
         _port=
         case "${_host}" in 
            *@*)
               _userinfo="${_host%%@*}"
               _host="${_host#*@}"
            ;;
         esac
         case "${_host}" in 
            *:*)
               _port="${_host%%:*}"
               _host="${_host#*:}"
            ;;
         esac
         _query=
         _fragment=
      ;;

      *)
         _scheme="${url%:*}"
         _host=
         r_url_remove_query "${url##*:}"
         r_url_remove_fragment "${RVAL}"
         _path=${RVAL}
         _userinfo=
         _port=
         _query=
         _fragment=
      ;;
   esac
}


function r_url_get_path()
{
   log_entry "r_url_get_path" "$@"

   local url="$1"

   local _scheme
   local _userinfo
   local _host
   local _port
   local _path
   local _query
   local _fragment

   if __url_parse "${url}"
   then
      RVAL="${_path}"
      return
   fi

   return 1
}


fi
:


if ! [ ${MULLE_VERSION_SH+x} ]
then
MULLE_VERSION_SH='included'



function r_get_version_major()
{
   RVAL="${1%%\.*}"
}


function r_get_version_minor()
{
   RVAL="${1#*\.}"
   if [ "${RVAL}" = "$1" ]
   then
      RVAL=0
   else
      RVAL="${RVAL%%\.*}"
   fi
}


function r_get_version_patch()
{
   local prev

   prev="${1#*\.}"
   RVAL="${prev#*\.}"
   if [ "${RVAL}" = "${prev}" ]
   then
      RVAL=0
   else
      RVAL="${RVAL%%\.*}"
   fi
}


_r_version_value()
{
   RVAL="$((${1:-0} * 1048576 + ${2:-0} * 256 + ${3:-0}))"
}


function r_version_value()
{
   local major
   local minor
   local patch

   r_get_version_major "$1"
   major="${RVAL}"
   r_get_version_minor "$1"
   minor="${RVAL}"
   r_get_version_patch "$1"
   patch="${RVAL}"

   _r_version_value "${major}" "${minor}" "${patch}"
}


_r_version_value_distance()
{
   RVAL="$(($2 - $1))"
}


function r_version_distance()
{
   local value1
   local value2

   r_version_value "$1"
   value1="${RVAL}"
   r_version_value "$2"
   value2="${RVAL}"

   _r_version_value_distance "${value1}" "${value2}"
}


_is_compatible_version_value_distance()
{
   if [ "$1" -ge 1048576 -o "$1" -le -1048575 ]
   then
      return 1
   fi

   if [ "$1" -gt 4096 ]
   then
      return 1
   fi

   [ "$1" -le 0 ]
}


function is_compatible_version()
{
   r_version_distance "$1" "$2"
   _is_compatible_version_value_distance "${RVAL}"
}

fi
:
if ! [ ${MULLE_ETC_SH+x} ]
then
MULLE_ETC_SH='included'





function etc_make_file_from_symlinked_file()
{
   log_entry "etc_make_file_from_symlinked_file" "$@"

   local dstfile="$1"

   if [ ! -L "${dstfile}" ]
   then
      return 1
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   log_verbose "Turn symlink \"${dstfile}\" into a file"

   local targetfile

   targetfile="`readlink "${dstfile}"`"
   exekutor rm "${dstfile}"

   local directory
   local filename

   r_dirname "${dstfile}"
   directory="${RVAL}"
   r_basename "${dstfile}"
   filename="${RVAL}"
   (
      rexekutor cd "${directory}" || exit 1

      if [ ! -f "${targetfile}" ]
      then
         log_fluff "Stale link encountered"
         return 0
      fi

      exekutor cp ${flags} "${targetfile}" "${filename}" || exit 1
      exekutor chmod ug+w "${filename}"
   ) || fail "Could not copy \"${targetfile}\" to \"${dstfile}\""
}



function etc_prepare_for_write_of_file()
{
   log_entry "etc_prepare_for_write_of_file" "$@"

   local filename="$1"

   r_mkdir_parent_if_missing "${filename}"

   etc_make_file_from_symlinked_file "${filename}"
}



function etc_make_symlink_if_possible()
{
   log_entry "etc_make_symlink_if_possible" "$@"

   local dstfile="$1"
   local sharedir="$2"
   local symlink="$3"

   if [ -z "${sharedir}" ]
   then
      return 2
   fi

   if [ -L "${dstfile}" ]
   then
      return 4
   fi

   local srcfile
   local filename

   r_basename "${dstfile}"
   filename="${RVAL}"

   r_filepath_concat "${sharedir}" "${filename}"
   srcfile="${RVAL}"

   if [ ! -e "${srcfile}" ]
   then
      return 2
   fi

   local DIFF

   if ! DIFF="`command -v diff`"
   then
      fail "diff command not installed"
   fi

   local dstdir

   r_dirname "${dstfile}"
   dstdir="${RVAL}"

   if ! "${DIFF}" -b "${dstfile}" "${srcfile}" > /dev/null
   then
      return 3
   fi

   log_verbose "\"${dstfile}\" has no user edits: replace with symlink"

   remove_file_if_present "${dstfile}"
   etc_symlink_or_copy_file "${srcfile}" \
                            "${dstdir}" \
                            "${filename}" \
                            "${symlink}"
   return $?
}


function etc_symlink_or_copy_file()
{
   log_entry "etc_symlink_or_copy_file" "$@"

   local srcfile="$1"
   local dstdir="$2"
   local filename="$3"
   local symlink="$4"

   [ -f "${srcfile}" ] || _internal_fail "\"${srcfile}\" does not exist or is not a file"
   [ -d "${dstdir}" ]  || _internal_fail "\"${dstdir}\" does not exist or is not a directory"

   local dstfile

   if [ -z "${filename}" ]
   then
   	r_basename "${srcfile}"
   	filename="${RVAL}"
	fi

   r_filepath_concat "${dstdir}" "${filename}"
   dstfile="${RVAL}"

   if [ -e "${dstfile}" ]
   then
      log_error "\"${dstfile}\" already exists"
      return 1
   fi

   r_mkdir_parent_if_missing "${dstfile}"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   if [ -z "${symlink}" ]
   then
      case "${MULLE_UNAME}" in
         'mingw'|'msys')
            symlink='NO'
         ;;

         *)
            symlink='YES'
         ;;
      esac
   fi

   if [ "${symlink}" = 'YES' ]
   then
      local linkrel

      r_relative_path_between "${srcfile}" "${dstdir}"
      linkrel="${RVAL}"

      exekutor ln -s ${flags} "${linkrel}" "${dstfile}"
      return $?
   fi

   exekutor cp ${flags} "${srcfile}" "${dstfile}" &&
   exekutor chmod ug+w "${dstfile}"
}


function etc_setup_from_share_if_needed()
{
   log_entry "etc_setup_from_share_if_needed" "$@"

   local etc="$1"
   local share="$2"
   local symlink="$3"

   if [ -d "${etc}" ]
   then
      log_fluff "etc folder already setup"
      return
   fi

   mkdir_if_missing "${etc}"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   local filename

   if [ -d "${share}" ] # sometimes it's not there, but find complains
   then
      .foreachline filename in `find "${share}" ! -type d -print`
      .do
         r_basename "${filename}"
         etc_symlink_or_copy_file "${filename}" \
                                  "${etc}" \
                                  "${RVAL}" \
                                  "${symlink}"
      .done
   fi
}


function etc_remove_if_possible()
{
   log_entry "etc_remove_if_possible" "$@"

   [ $# -eq 2 ] || _internal_fail "API error"

   local etcdir="$1"
   local sharedir="$2"

   if [ ! -d "${etcdir}" ]
   then
      return
   fi

   if dirs_contain_same_files "${etcdir}" "${sharedir}"
   then
      rmdir_safer "${etcdir}"
   fi
}


function etc_repair_files()
{
   log_entry "etc_repair_files" "$@"

   local srcdir="$1" # share
   local dstdir="$2" # etc

   local glob="$3"
   local add="$4"
   local symlink="$5"

   if [ ! -d "${dstdir}" ]
   then
      log_verbose "Nothing to repair, as \"${dstdir}\" does not exist yet"
      return
   fi

   local filename
   local dstfile
   local srcfile
   local can_remove_etc

   can_remove_etc='YES'

   dstdir="${dstdir%%/}"
   srcdir="${srcdir%%/}"

   local DIFF

   if ! DIFF="`command -v diff`"
   then
      fail "diff command not installed"
   fi

   .foreachline dstfile in `find "${dstdir}" ! -type d -print` # dstdir is etc
   .do
      filename="${dstfile#${dstdir}/}"
      srcfile="${srcdir}/${filename}"

      if [ -L "${dstfile}" ]
      then
         if ! ( cd "${dstdir}" && [ -f "`readlink "${filename}"`" ] )
         then
            globtest="${glob}${filename#${glob}}"
            if [ ! -z "${glob}" ] && [ -f "${srcdir}"/${globtest} ]
            then
               log_verbose "\"${filename}\" moved to ${globtest}: relink"
               remove_file_if_present "${dstfile}"
               etc_symlink_or_copy_file "${srcdir}/"${globtest} \
                                        "${dstdir}" \
                                        "" \
                                        "${symlink}"
            else
               log_verbose "\"${filename}\" no longer exists: remove"
               remove_file_if_present "${dstfile}"
            fi
         else
            log_fluff "\"${filename}\" is a healthy symlink: keep"
         fi
      else
         if [ -f "${srcfile}" ]
         then
            if "${DIFF}" -b "${dstfile}" "${srcfile}" > /dev/null
            then
               log_verbose "\"${filename}\" has no user edits: replace with symlink"
               remove_file_if_present "${dstfile}"
               etc_symlink_or_copy_file "${srcfile}" \
                                        "${dstdir}" \
                                        "${filename}" \
                                        "${symlink}"
            else
               log_fluff "\"${filename}\" contains edits: keep"
               can_remove_etc='NO'
            fi
         else
            log_fluff "\"${filename}\" is an addition: keep"
            can_remove_etc='NO'
         fi
      fi
   .done

   .foreachline srcfile in `find "${srcdir}" ! -type d -print` # dstdir is etc
   .do
      filename="${srcfile#${srcdir}/}"
      dstfile="${dstdir}/${filename}"

      if [ ! -e "${dstfile}" ]
      then
         if [ "${add}" = 'YES' ]
         then
            log_verbose "\"${filename}\" is missing: recreate"
            etc_symlink_or_copy_file "${srcfile}" \
                                     "${dstdir}" \
                                     "${filename}" \
                                     "${symlink}"
         else
            log_info "\"${filename}\" is new but not used. Use \`repair --add\` to add it."
            can_remove_etc='NO'
         fi
      fi
   .done

   if [ "${can_remove_etc}" = 'YES' ]
   then
      log_info "\"${dstdir#"${MULLE_USER_PWD}/"}\" contains no user changes so use \"share\" again"
      rmdir_safer "${dstdir}"
      rmdir_if_empty "${srcdir}"
   fi
}

fi
:


mulle_isbase64_char()
{
   [ -z "${1//[A-Za-z0-9\/+]/}" ]
}


r_mulle_base64_encode_string()
{
   local width="$1"
   local _src="$2"

   _src="${_src}"$'\n'     # stay compatible

   local inLen="${#_src}"
   local inPos=0
   local breakPos=0
   local out
   local c1
   local c2
   local c3
   local d1
   local d2
   local d3
   local d4
   local i
   local n
   local index

   local mulle_base64tab_string="\
ABCDEFGHIJKLMNOPQRSTUVWXYZ\
abcdefghijklmnopqrstuvwxyz0123456789+/"

   breakPos=${width}

   n=$(( inLen / 3 ))
   remain=$(( inLen % 0x3 ))

   i=0
   while [ $i -lt $n ]
   do
      printf -v c1 "%d" "'${_src:${inPos}:1}"
      inPos=$(( inPos + 1 ))
      printf -v c2 "%d" "'${_src:${inPos}:1}"
      inPos=$(( inPos + 1 ))
      printf -v c3 "%d" "'${_src:${inPos}:1}"
      inPos=$(( inPos + 1 ))

      index=$(( c1 >> 2 ))
      d1="${mulle_base64tab_string:${index}:1}"
      index=$(( ((c1 & 0x03) << 4) | (c2 >> 4) ))
      d2="${mulle_base64tab_string:${index}:1}"
      index=$(( ((c2 & 0x0F) << 2) | ((c3 & 0xC0) >> 6) ))
      d3="${mulle_base64tab_string:${index}:1}"
      index=$(( c3 & 0x3F ))
      d4="${mulle_base64tab_string:${index}:1}"

      out="${out}${d1}${d2}${d3}${d4}"
      outPos=$(( outPos + 4 ))

      if [ "${width}" -gt 0  -a ${outPos} -ge ${breakPos} ]
      then
         out="${out}"$'\n'
         outPos=$(( outPos + 1 ))
         breakPos=$(( outPos + $width ))
      fi
      i=$(( i + 1))
   done

   case $remain in
      2)
         printf -v c1 "%d" "'${_src:${inPos}:1}"
         inPos=$(( inPos + 1 ))
         printf -v c2 "%d" "'${_src:${inPos}:1}"

         index=$(( (c1 & 0xFC) >> 2 ))
         d1="${mulle_base64tab_string:${index}:1}"
         index=$(( ((c1 & 0x03) << 4) | ((c2 & 0xF0) >> 4) ))
         d2="${mulle_base64tab_string:${index}:1}"
         index=$(( ((c2 & 0x0F) << 2) ))
         d3="${mulle_base64tab_string:${index}:1}"

         out="${out}${d1}${d2}${d3}="
      ;;

      1)
         printf -v c1 "%d" "'${_src:${inPos}:1}"
         index=$(( (c1 & 0xFC) >> 2 ))
         d1="${mulle_base64tab_string:${index}:1}"
         index=$(( (c1 & 0x03) << 4 ))
         d2="${mulle_base64tab_string:${index}:1}"
         out="${out}${d1}${d2}=="
      ;;

      0)
      ;;
   esac

   RVAL="${out}"
}


mulle_base64_encode()
{
   local width="$1"
   local filename="${2:--}"

   local _src

   if [ "${filename}" = '-' ]
   then
      _src="`cat`" || return 1
   else
      _src="`cat "${filename}"`" || return 1
   fi

   if ! r_mulle_base64_encode_string "${width}" "${_src}"
   then
      return 1
   fi

   printf "%s\n" "${RVAL}"
}


mulle_base64idx_string=\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\377\377\377\377\377'\
$'\377\377\377\076\377\377\377\077'\
$'\064\065\066\067\070\071\072\073'\
$'\074\075\377\377\377\377\377\377'\
$'\377'_$'\001\002\003\004\005\006'\
$'\007\010\011\012\013\014\015\016'\
$'\017\020\021\022\023\024\025\026'\
$'\027\030\031\377\377\377\377\377'\
$'\377\032\033\034\035\036\037\040'\
$'\041\042\043\044\045\046\047\050'\
$'\051\052\053\054\055\056\057\060'\
$'\061\062\063\377\377\377\377\377'


r_mulle_base64_decode_char()
{
   local c="$1"

   if [ "$c" -eq 65 ]
   then
      RVAL=0
      return
   fi
   printf -v RVAL "%d" "'${mulle_base64idx_string:${c}:1}"
}


r_mulle_base64_decode_string()
{
   local _src="$1"

   local isErr=0
   local isEndSeen=0
   local b1
   local b2
   local b3
   local a1
   local a2
   local a3
   local a4
   local inPos=0
   local outPos=0
   local inLen
   local c
   local out


   inLen="${#_src}"

   while [ $inPos -lt $inLen ]
   do
      for i in 1 2 3 4
      do
         while [ $inPos -lt $inLen ]
         do
            c="${_src:${inPos}:1}"
            inPos=$(( inPos + 1 ))

            if mulle_isbase64_char "${c}"
            then
               printf -v "a${i}" "${c}"
               break
            fi

            case "${c}" in
               '=')
                  printf -v "a${i}" "0"
                  isEndSeen=1
                  break
               ;;

               $'\r'|$'\n'|' '|$'\t')
               ;;

               *)
                  log_error "garbage character ${c} in base64 string"
                  RVAL=
                  return 1
               ;;
            esac
         done

         if [ $isEndSeen -ne 0 ]
         then
            i=$((i - 1))
            break
         fi
      done

      case "${i}" in
         4)
            printf -v a1 "%d" "'${a1}"
            printf -v a2 "%d" "'${a2}"
            printf -v a3 "%d" "'${a3}"
            printf -v a4 "%d" "'${a4}"

            r_mulle_base64_decode_char "$a1"
            a1=${RVAL}
            r_mulle_base64_decode_char "$a2"
            a2=${RVAL}
            r_mulle_base64_decode_char "$a3"
            a3=${RVAL}
            r_mulle_base64_decode_char "$a4"
            a4=${RVAL}

            b1=$(( ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03) ))
            b2=$(( ((a2 << 4) & 0xF0) | ((a3 >> 2) & 0x0F) ))
            b3=$(( ((a3 << 6) & 0xC0) | ( a4     & 0x3F) ))

            printf -v b1 \\$(printf '%03o' $b1)
            printf -v b2 \\$(printf '%03o' $b2)
            printf -v b3 \\$(printf '%03o' $b3)

            out="${out}${b1}${b2}${b3}"
         ;;

         3)
            printf -v a1 "%d" "'${a1}"
            printf -v a2 "%d" "'${a2}"
            printf -v a3 "%d" "'${a3}"

            r_mulle_base64_decode_char "$a1"
            a1=${RVAL}
            r_mulle_base64_decode_char "$a2"
            a2=${RVAL}
            r_mulle_base64_decode_char "$a3"
            a3=${RVAL}

            b1=$(( ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03) ))
            b2=$(( ((a2 << 4) & 0xF0) | ((a3 >> 2) & 0x0F) ))

            printf -v b1 \\$(printf '%03o' $b1)
            printf -v b2 \\$(printf '%03o' $b2)

            out="${out}${b1}${b2}"
         ;;

         2)
            printf -v a1 "%d" "'${a1}"
            printf -v a2 "%d" "'${a2}"

            r_mulle_base64_decode_char "$a1"
            a1=${RVAL}
            r_mulle_base64_decode_char "$a2"
            a2=${RVAL}

            b1=$(( ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03) ))

            printf -v b1 \\$(printf '%03o' $b1)

            out="${out}${b1}"
         ;;

         *)
            if [ "${ignore_garbage}" = 'YES' ]
            then
               continue
            fi

            log_error "garbage character in base64 string"
            RVAL=
            return 1
         ;;
      esac

      if [ $isEndSeen -eq 1 ]
      then
         break
      fi
   done

   RVAL="${out%$'\n'}"
   return 0
}


mulle_base64_decode()
{
   local filename="${1:--}"

   local _src

   if [ "${filename}" = '-' ]
   then
      _src="`cat`" || return 1
   else
      _src="`cat "${filename}"`" || return 1
   fi

   if ! r_mulle_base64_decode_string "${_src}"
   then
      return 1
   fi

   printf "%s\n" "${RVAL}"
}


mulle_base64()
{
   local decode
   local ignore
   local width=76

   while [ $# -ne 0 ]
   do
      case "$1" in
         -d|--decode)
            decode='YES'
         ;;

         -i)
            ignore_garbage='YES'
         ;;

         -w|--width|-b)
            shift
            width="$1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   case "${MULLE_UNAME}" in
      openbsd|netbsd)
      ;;

      *)
         local base64

         if base64="`command -v base64`"
         then
            if [ "${decode}" = 'YES' ]
            then
               rexekutor "${base64}" -d "$@"
               return $?
            fi

            case "${MULLE_UNAME}" in
               openbsd)
                  rexekutor "${base64}" "$@"
                  return $?
               ;;

               macos|*bsd|dragonfly)
                  rexekutor "${base64}" -b "${width}" "$@"
                  return $?
               ;;
            esac

            rexekutor "${base64}" -w "${width}"
            return $?
         fi
      ;;
   esac

   if [ "${decode}" ]
   then
      mulle_base64_decode "${ignore_garbage}" "$@"
      return $?
   fi

   mulle_base64_encode "${width}" "$@"
}
### << END OF mulle-bashfunctions-embed.sh <<

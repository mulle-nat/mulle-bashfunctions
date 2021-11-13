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

if [ -z "${MULLE_BASHGLOBAL_SH}" ]
then
   MULLE_BASHGLOBAL_SH="included"

   DEFAULT_IFS="${IFS}" # as early as possible

   if [ ! -z "${ZSH_VERSION}" ]
   then
     setopt sh_word_split
     setopt POSIX_ARGZERO
   fi

   if [ -z "${MULLE_EXECUTABLE}" ]
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


   if [ -z "${MULLE_EXECUTABLE_NAME}" ]
   then
      MULLE_EXECUTABLE_NAME="${MULLE_EXECUTABLE##*/}"
   fi

   if [ -z "${MULLE_USER_PWD}" ]
   then
      MULLE_USER_PWD="${PWD}"
      export MULLE_USER_PWD
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME:-${MULLE_EXECUTABLE_NAME}}"

   MULLE_EXECUTABLE_PWD="${PWD}"
   MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE_NAME}"
   MULLE_EXECUTABLE_PID="$$"

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
         read -r MULLE_UNAME < /proc/sys/kernel/osrelease
         case "${MULLE_UNAME}" in
            *-Microsoft)
               MULLE_UNAME="windows"
               MULLE_EXE_EXTENSION=".exe"
            ;;
  
            *)
               MULLE_UNAME="linux"
            ;;
         esac
      fi
   fi


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

   if [ -z "${MULLE_USERNAME}" ]
   then
      MULLE_USERNAME="${MULLE_USERNAME:-${USERNAME}}" # mingw
      MULLE_USERNAME="${MULLE_USERNAME:-${USER}}"
      MULLE_USERNAME="${MULLE_USERNAME:-${LOGNAME}}"
      MULLE_USERNAME="${MULLE_USERNAME:-`id -nu 2> /dev/null`}"
      MULLE_USERNAME="${MULLE_USERNAME:-cptnemo}"
   fi
fi

if [ -z "${MULLE_BASHLOADER_SH}" ]
then
   MULLE_BASHLOADER_SH="included"

   include_mulle_tool_library()
   {
      local tool="$1"
      local name="$2"

      local upper_tool
      local upper_name

      case "${BASH_VERSION}" in
         [0123]*)
            upper_tool="`printf "${tool}" | tr '[:lower:]' '[:upper:]'`"
            upper_name="`printf "${name}" | tr '[:lower:]' '[:upper:]'`"
         ;;

         *)
            if [ ! -z "${ZSH_VERSION}" ]
            then
               upper_tool="${tool:u}"
               upper_name="${name:u}"
            else
               upper_tool="${tool^^}"
               upper_name="${name^^}"
            fi
         ;;
      esac

      local header_define

      header_define="MULLE_${upper_tool}_${upper_name}_SH"
      if [ ! -z "${!header_define}" ]
      then
         return
      fi

      local tool_libexec_define

      tool_libexec_define="MULLE_${upper_tool}_LIBEXEC_DIR"
      if [ -z "${!tool_libexec_define}" ]
      then
         printf -v "${tool_libexec_define}" "%s" "`mulle-${tool} libexec-dir`" || exit 1
         eval export "${tool_libexec_define}"
      fi

      . "${!tool_libexec_define}/mulle-${tool}-${name}.sh" || exit 1
   }


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

      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] \
         && echo "MULLE_BASHFUNCTIONS_LIBEXEC_DIR not set" && exit 1

      if [ -z "${MULLE_COMPATIBILITY_SH}" ]
      then
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-compatibility.sh" || return 1
      fi

      case "$1" in
         'none')
         ;;

         ""|*)
            if [ -z "${MULLE_LOGGING_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-logging.sh"  || return 1
            fi
            if [ -z "${MULLE_EXEKUTOR_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-exekutor.sh" || return 1
            fi
            if [ -z "${MULLE_STRING_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-string.sh"   || return 1
            fi
            if [ -z "${MULLE_INIT_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-init.sh"     || return 1
            fi
            if [ -z "${MULLE_OPTIONS_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-options.sh"  || return 1
            fi
         ;;
      esac
      case "$1" in
         'none'|'minimal')
         ;;

         ""|*)
            if [ -z "${MULLE_PATH_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
            fi
            if [ -z "${MULLE_FILE_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
            fi
         ;;
      esac

      case "$1" in
         'all')
            if [ -z "${MULLE_ARRAY_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh"    || return 1
            fi
            if [ -z "${MULLE_CASE_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"     || return 1
            fi
            if [ -z "${MULLE_ETC_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-etc.sh"      || return 1
            fi
            if [ -z "${MULLE_PARALLEL_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-parallel.sh" || return 1
            fi
            if [ -z "${MULLE_VERSION_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-version.sh"  || return 1
            fi
      esac
   }

   __bashfunctions_loader "$@" || exit 1
fi
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


shell_enable_extglob

[ ! -z "${MULLE_LOGGING_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
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
      log_debug "$@"
   fi
}


log_setting()
{
   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      log_printf "${C_SETTING}%b${C_RESET}\n" "$*"
   fi
}


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




if [ -z "${BASH_VERSION}" ]
then
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

   case "${TERM}" in
      dumb)
         MULLE_NO_COLOR=YES
      ;;
   esac

   if [ -z "${NO_COLOR}" -a "${MULLE_NO_COLOR}" != 'YES' ] && [ ! -f /dev/stderr ]
   then
      C_RESET="\033[0m"

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
[ ! -z "${MULLE_EXEKUTOR_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-exekutor.sh" >&2

[ -z "${MULLE_LOGGING_SH}" ] && \
   echo "mulle-logging.sh must be included before mulle-executor.sh" 2>&1 && exit 1

MULLE_EXEKUTOR_SH="included"


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


logging_tee_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" != 'YES' ]
   then
      exekutor_print "$@" >> "${teeoutput}"
   fi
   exekutor_print "$@" >> "${output}"

   _append_tee_exekutor "${output}" "${teeoutput}" "$@"
}


logging_tee_eval_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" != 'YES' ]
   then
      eval_exekutor_print "$@" >> "${teeoutput}"
   fi
   eval_exekutor_print "$@" >> "${output}"
   _append_tee_eval_exekutor "${output}" "${teeoutput}" "$@"
}


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
[ ! -z "${MULLE_STRING_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-string.sh" >&2

MULLE_STRING_SH="included"

[ -z "${MULLE_BASHGLOBAL_SH}" ]    && echo "mulle-bashglobal.sh must be included before mulle-file.sh" 2>&1 && exit 1
[ -z "${MULLE_COMPATIBILITY_SH}" ] && echo "mulle-compatibility.sh must be included before mulle-string.sh" 2>&1 && exit 1


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


r_trim_whitespace()
{
   RVAL="$*"
   RVAL="${RVAL#"${RVAL%%[![:space:]]*}"}"
   RVAL="${RVAL%"${RVAL##*[![:space:]]}"}"
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


r_colon_concat()
{
   r_concat "$1" "$2" ":"
   r_remove_ugly "${RVAL}" ":"
}

r_comma_concat()
{
   r_concat "$1" "$2" ","
   r_remove_ugly "${RVAL}" ","
}

r_semicolon_concat()
{
   r_concat "$1" "$2" ";"
}


r_slash_concat()
{
   r_concat "$1" "$2" "/"
   r_remove_duplicate "${RVAL}" "/"
}

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


find_line()
{
   if [ ! -z "${ZSH_VERSION}" ]
   then
      find_line_zsh "$@"
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


r_filepath_cleaned()
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
   RVAL="${1//-/_}" # __
   RVAL="${RVAL//[^a-zA-Z0-9]/_}"
   case "${RVAL}" in
      [0-9]*)
         RVAL="_${RVAL}"
      ;;
   esac
}


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


r_escaped_singlequotes()
{
   local quote

   quote="'"
   RVAL="${1//${quote}/${quote}\"${quote}\"${quote}}"
}


r_escaped_doublequotes()
{
   RVAL="${*//\\/\\\\}"
   RVAL="${RVAL//\"/\\\"}"
}


r_unescaped_doublequotes()
{
   RVAL="${*//\\\"/\"}"
   RVAL="${RVAL//\\\\/\\}"
}


r_escaped_shell_string()
{
   printf -v RVAL '%q' "$*"
}


string_has_prefix()
{
  [ "${1#$2}" != "$1" ]
}


string_has_suffix()
{
  [ "${1%$2}" != "$1" ]
}


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
[ ! -z "${MULLE_INIT_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-init.sh" >&2

[ -z "${MULLE_STRING_SH}" ] && echo "mulle-string.sh must be included before mulle-init.sh" 2>&1 && exit 1


MULLE_INIT_SH="included"


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
[ ! -z "${MULLE_OPTIONS_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-options.sh" >&2

[ -z "${MULLE_LOGGING_SH}" ] && echo "mulle-logging.sh must be included before mulle-options.sh" 2>&1 && exit 1

MULLE_OPTIONS_SH="included"



options_dump_env()
{
   log_trace "ARGS:${C_TRACE2} ${MULLE_ARGUMENTS}"
   log_trace "PWD :${C_TRACE2} `pwd -P 2> /dev/null`"
   log_trace "ENV :${C_TRACE2} `env | sort`"
   log_trace "LS  :${C_TRACE2} `ls -a1F`"
}

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


options_technical_flags()
{
   local flag="$1"

   case "${flag}" in
      -n|--dry-run)
         MULLE_FLAG_EXEKUTOR_DRY_RUN='YES'
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


      -t|--trace)
         MULLE_TRACE='1848'
         if [ ! -z "${ZSH_VERSION}" ]
         then
            ps4string='%1x:%I' # TODO: fix for zsh
         else
            ps4string='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
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

   if [ -z "${MULLE_TECHNICAL_FLAGS}" ]
   then
      MULLE_TECHNICAL_FLAGS="${flag}"
   else
      MULLE_TECHNICAL_FLAGS="${MULLE_TECHNICAL_FLAGS} ${flag}"
   fi

   return 0
}




options_unpostpone_trace()
{
   if [ ! -z "${MULLE_TRACE_POSTPONE}" -a "${MULLE_TRACE}" = '1848' ]
   then
      set -x
      PS4="+ ${ps4string} + "
   fi
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

   options_setup_trace "${MULLE_TRACE}"
}


:

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
            MULLE_UNAME="android"
            if [ -r /proc/sys/kernel/osrelease ]
            then
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
            fi
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
      MULLE_HOSTNAME="${HOSTNAME}"
      case "${MULLE_UNAME}" in
         'mingw'|'msys'|'sunos')
            MULLE_HOSTNAME="${MULLE_HOSTNAME:-`hostname 2> /dev/null`}"
         ;;

         *) # on AARCH hostname does not exist anymore (sigh)
            MULLE_HOSTNAME="${MULLE_HOSTNAME:-`hostname -s 2> /dev/null`}"
         ;;
      esac
      MULLE_HOSTNAME="${MULLE_HOSTNAME:-`grep -E -v '^#' "/etc/hostname" 2> /dev/null`}"
      MULLE_HOSTNAME="${MULLE_HOSTNAME:-nautilus}"

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


if ! [ ${MULLE_BASHLOADER_SH+x} ]
then
   MULLE_BASHLOADER_SH='included'

   r_uppercase()
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


   r_include_path()
   {
      local executable="$1"
      local filename="$2"
      local libexec_define="$3"

      local value

      if [ ${ZSH_VERSION+x} ]
      then
         value="${(P)libexec_define}"
      else
         value="${!libexec_define}"
      fi

      if [ -z "${value}" ]
      then
         value="`"${executable}" libexec-dir`" || fail "Could not execute ${executable} libexec-dir successfully ($PATH)"
         printf -v "${libexec_define}" "%s" "${value}" 
         eval export "${libexec_define}"
      fi

      RVAL="${value}/${filename}"
   }



   include_executable_library()
   {
      local includeguard="$4"

      local value

      if [ ${ZSH_VERSION+x} ]
      then
         value="${(P)includeguard}"
      else
         value="${!includeguard}"
      fi

      if [ ! -z "${value}" ]
      then
         return
      fi

      r_include_path "$@"

       . "${RVAL}" || exit 1

      printf -v "${includeguard}" 'YES'
   }

   __parse_include_specifier()
   {
      local s="$1"
      local default_namespace="${2:-mulle}"  # default namespace (mulle)

      local name

      name="${s##*::}"

      local upper_name

      r_identifier "${name}"
      r_uppercase "${RVAL}"
      upper_name="${RVAL}"

      if [ "${name}" = "${s}" ]
      then
         if [ "${default_namespace}" = "mulle" ]
         then
            _executable="mulle-bashfunctions"
            _filename="mulle-${name}.sh"
            _libexecdir="MULLE_BASHFUNCTIONS_LIBEXEC_DIR"
            _includeguard="MULLE_${upper_name}_SH"
            return 0
         fi

         r_identifier "${default_namespace}"
         upper_default_namespace="${RVAL}"

         _executable="${default_namespace}-bashfunctions"
         _filename="${default_namespace}-${name}.sh"
         _libexecdir="${upper_default_namespace}_BASHFUNCTIONS_LIBEXEC_DIR"
         _includeguard="${upper_default_namespace}_${upper_name}_SH"
         return 0
      fi

      local tool

      tool="${s%::*}"

      local namespace

      case "${tool}" in
         *-*)
            namespace="${tool%%-*}"
            tool="${tool#*-}"
         ;;

         *)
            namespace="${default_namespace}"
         ;;
      esac

      r_concat "${namespace}" "${tool}" "-"
      tool="${RVAL}"

      local upper_tool

      r_identifier "${tool}"
      r_uppercase "${RVAL}"
      upper_tool="${RVAL}"

      _executable="${tool}"
      _filename="${tool}-${name}.sh"
      _libexecdir="${upper_tool}_LIBEXEC_DIR"
      _includeguard="${upper_tool}_${upper_name}_SH"
   }


   include()
   {

      local _executable
      local _filename
      local _libexecdir
      local _includeguard

      __parse_include_specifier "$@"

      include_executable_library "${_executable}" \
                                 "${_filename}" \
                                 "${_libexecdir}" \
                                 "${_includeguard}"
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
         && echo "MULLE_BASHFUNCTIONS_LIBEXEC_DIR not set" >&2 \
         && exit 1
      :
   }

   __bashfunctions_loader || exit 1
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


function shell_is_builtin_command()
{
   if [ ${ZSH_VERSION+x} ]
   then
      case "`LC_C=C whence -w "$1" `" in
         *:*builtin)
            return 0
         ;;
      esac
      return 1
   fi

   [ "`type -t "$1"`" = "builtin" ]
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

function shell_is_variable_defined()
{
   local key="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      [[ -n ${(P)key} ]]
      return $?
   fi
   [ "${!key}" ]
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
   if [ "${MULLE_FLAG_LOG_ERROR:-YES}" = 'NO' ]
   then
      return
   fi
   _log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX}${MULLE_LOG_ERROR_PREFIX}${C_ERROR_TEXT}%b${C_RESET}\n" "$*"
}



_log_fail()
{
   if [ "${MULLE_FLAG_LOG_ERROR:-YES}" = 'NO' ]
   then
      return
   fi
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
   if ! [ "${MULLE_FLAG_LOG_TERSE:-}" = 'YES' -o "${MULLE_FLAG_LOG_TERSE:-}" = 'WARN' ]
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
      functionname="${functionname} " # add space for later

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

   case "${MULLE_UNAME}" in
      'linux'|'windows')
         _log_printf "${C_DEBUG}$(date "+%s.%N") %s%s${C_RESET}\n" "${functionname}" "${args}"
      ;;

      *)
         _log_printf "${C_DEBUG}$(date "+%s") %s%s${C_RESET}\n" "${functionname}" "${args}"
      ;;
   esac
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

   if [ "${MULLE_FLAG_LOG_TERSE:-}" = 'YES' -o "${MULLE_FLAG_LOG_TERSE:-}" = 'WARN' ]
   then
      alias log_info=': #'
   fi

   if [ "${MULLE_FLAG_LOG_TERSE:-}" = 'YES' ]
   then
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


logging_trap_uninstall()
{
   trap - TERM INT
}


logging_initialize_color()
{

   case "${TERM:-}" in
      dumb)
         MULLE_NO_COLOR='YES'
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
      C_UNDERLINE="\033[4m"
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


logging_deinitialize_color()
{
   C_RESET=

   C_RED=
   C_GREEN=
   C_BLUE=
   C_MAGENTA=
   C_CYAN=

   C_BR_RED=
   C_BR_GREEN=
   C_BR_BLUE=
   C_BR_CYAN=
   C_BR_MAGENTA=
   C_BOLD=
   C_FAINT=
   C_UNDERLINE=
   C_SPECIAL_BLUE=

   if [ "${MULLE_LOGGING_TRAP:-}" != 'NO' ]
   then
      logging_trap_uninstall
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


_exekutor_trace()
{
   local printer="$1"; shift

   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE:-}" ]
   then
      ${printer} "$@" >&2
   else
      ${printer} "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
   fi
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


_exekutor_trace_output()
{
   local printer="$1"; shift
   local redirect="$1"; shift
   local output="$1"; shift

   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE:-}" ]
   then
      ${printer} "$@" "${redirect}" "${output}" >&2
   else
      ${printer} "$@" "${redirect}" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
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
   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace "exekutor_print" "$@"
   fi

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
   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace "exekutor_print" "$@"
   fi

   "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


function eval_exekutor()
{
   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace "eval_exekutor_print" "$@"
   fi

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
   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace "eval_exekutor_print" "$@"
   fi

   eval "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


function redirect_exekutor()
{
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace_output "exekutor_print" '>' "${output}" "$@"
   fi

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

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace_output "eval_exekutor_print" '>' "${output}" "$@"
   fi

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

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace_output "exekutor_print" '>>' "${output}" "$@"
   fi

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

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"
   fi

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

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"
   fi

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

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" = 'YES' ]
   then
      _exekutor_trace_output "eval_exekutor_print" '>>' "${output}" "$@"
   fi

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


r_remove_duplicate_separators()
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
   r_remove_duplicate_separators "${RVAL}" "/"
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
   if [ ! -z "${1:0:1}" -a ! -z "${2:0:1}" ]
   then
      RVAL="$1"$'\n'"$2"
   else
      RVAL="$1$2"
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


function r_line_at_index()
{
   RVAL="$(sed -n -e "$(( $2 + 1 ))p" <<< "$1")"
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


function r_remove_duplicate_separators_lines()
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

   while IFS=$'\n' read -r line
   do
      RVAL="${line}${delim}${RVAL}"
      delim=$'\n'
   done <<< "${lines}"
}


function r_split()
{
   local s="$1"
   local sep="${2:-${IFS}}"

   if [ ${ZSH_VERSION+x} ]
   then
      unset RVAL
      RVAL=("${(@ps:$sep:)s}")
   else
      shell_disable_glob
      IFS="${sep}" read -r -a RVAL <<< "${s}"
      shell_enable_glob
   fi
}


function r_betwixt()
{
   local sep="$1" ; shift

   local tmp

   printf -v tmp "%s${sep}" "$@"
   RVAL="${tmp%"${sep}"}"
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


   if [ ${ZSH_VERSION+x} ]
   then
      local i
      local c

      RVAL=
      for (( i=0; i < ${#s}; i++ ))
      do
         c="${s:$i:1}"
         case "$c" in
            $'\n'|$'\r'|$'\t'|$'\f'|"\\"|'['|']'|'$'|'*'|'.'|'^'|'|')
               RVAL+="\\"
            ;;
         esac
         RVAL+="$c"
      done
   else
      s="${s//\\/\\\\}"
      s="${s//\[/\\[}"
      s="${s//\]/\\]}"
      s="${s//\$/\\$}"
      s="${s//\*/\\*}"
      s="${s//\./\\.}"
      s="${s//\^/\\^}"
      s="${s//\|/\\|}"

      s="${s//$'\n'/\\$'\n'}"
      s="${s//$'\t'/\\$'\t'}"
      s="${s//$'\r'/\\$'\r'}"
      s="${s//$'\f'/\\$'\f'}"
      RVAL="$s"
   fi
}


function r_escaped_sed_pattern()
{
   local s="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      local i
      local c

      RVAL=
      for (( i=0; i < ${#s}; i++ ))
      do
         c="${s:$i:1}"
         case "$c" in
            $'\n'|$'\r'|$'\t'|$'\f'|"\\"|'['|']'|'/'|'$'|'*'|'.'|'^')
               RVAL+="\\"
            ;;
         esac
         RVAL+="$c"
      done
   else
      s="${s//\\/\\\\}"
      s="${s//\[/\\[}"
      s="${s//\]/\\]}"
      s="${s//\//\\/}"
      s="${s//\$/\\$}"
      s="${s//\*/\\*}"
      s="${s//\./\\.}"
      s="${s//\^/\\^}"
      s="${s//$'\n'/\\$'\n'}"
      s="${s//$'\t'/\\$'\t'}"
      s="${s//$'\r'/\\$'\r'}"
      s="${s//$'\f'/\\$'\f'}"
      RVAL="$s"
   fi
}


function r_escaped_sed_replacement()
{
   local s="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      local i
      local c

      RVAL=
      for (( i=0; i < ${#s}; i++ ))
      do
         c="${s:$i:1}"
         case "$c" in
            $'\n'|$'\r'|$'\t'|$'\f'|"\\"|'/'|'&')
               RVAL+="\\"
            ;;
         esac
         RVAL+="$c"
      done
   else
      s="${s//\\/\\\\}"        # escape backslashes first
      s="${s//\//\\/}"         # escape forward slashes
      s="${s//&/\\&}"          # escape ampersands

      s="${s//$'\n'/\\$'\n'}"
      s="${s//$'\t'/\\$'\t'}"
      s="${s//$'\r'/\\$'\r'}"
      s="${s//$'\f'/\\$'\f'}"
      RVAL="$s"
   fi
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


function r_escaped_json()
{
   RVAL="${*//\\/\\\\}"

   RVAL="${RVAL//\"/\\\"}"

   RVAL="${RVAL//$'\n'/\\n}"

   RVAL="${RVAL//$'\r'/\\r}"

   RVAL="${RVAL//$'\t'/\\t}"

   RVAL="${RVAL//$'\b'/\\b}"

   RVAL="${RVAL//$'\f'/\\f}"

   RVAL="${RVAL//\//\\/}"

   RVAL="${RVAL//$'\x1'/\\u0001}"
   RVAL="${RVAL//$'\x2'/\\u0002}"
   RVAL="${RVAL//$'\x3'/\\u0003}"
   RVAL="${RVAL//$'\x4'/\\u0004}"
   RVAL="${RVAL//$'\x5'/\\u0005}"
   RVAL="${RVAL//$'\x6'/\\u0006}"
   RVAL="${RVAL//$'\x7'/\\u0007}"
   RVAL="${RVAL//$'\xB'/\\u000B}"
   RVAL="${RVAL//$'\xE'/\\u000E}"
   RVAL="${RVAL//$'\xF'/\\u000F}"
   RVAL="${RVAL//$'\x10'/\\u0010}"
   RVAL="${RVAL//$'\x11'/\\u0011}"
   RVAL="${RVAL//$'\x12'/\\u0012}"
   RVAL="${RVAL//$'\x13'/\\u0013}"
   RVAL="${RVAL//$'\x14'/\\u0014}"
   RVAL="${RVAL//$'\x15'/\\u0015}"
   RVAL="${RVAL//$'\x16'/\\u0016}"
   RVAL="${RVAL//$'\x17'/\\u0017}"
   RVAL="${RVAL//$'\x18'/\\u0018}"
   RVAL="${RVAL//$'\x19'/\\u0019}"
   RVAL="${RVAL//$'\x1A'/\\u001A}"
   RVAL="${RVAL//$'\x1B'/\\u001B}"
   RVAL="${RVAL//$'\x1C'/\\u001C}"
   RVAL="${RVAL//$'\x1D'/\\u001D}"
   RVAL="${RVAL//$'\x1E'/\\u001E}"
   RVAL="${RVAL//$'\x1F'/\\u001F}"
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
   local max=${2:-40}

   if [ $max -eq 0 ]
   then
      RVAL=
      return 1
   fi

   if filepath="`readlink "${RVAL}"`"
   then
      r_dirname "${RVAL}"
      r_prepend_path_if_relative "${RVAL}" "${filepath}"
      r_resolve_symlinks "${RVAL}" $(( max - 1 ))
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
            PS4="+ ${MULLE_TRACE_PS4} + "
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

      --silent-but-warn)
         MULLE_FLAG_LOG_TERSE='WARN'
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

      -lx*)
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
            MULLE_TRACE_PS4='%1x:%I' # TODO: fix for zsh
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
      ;;

      -lT)
         MULLE_TRACE='1848'
         if [ ${ZSH_VERSION+x} ]
         then
            MULLE_TRACE_PS4='%1x:%I'
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         return # don't propagate
      ;;

      -tfpwd|--trace-full-pwd)
         before_trace_fail "${flag}"
         if [ ${ZSH_VERSION+x} ]
         then
            MULLE_TRACE_PS4='%1x:%I \"\w\"'
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO} \"\w\"'
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
                     MULLE_TRACE_PS4='$(date "+%s.%N (%1x:%I)")'
                  else
                     MULLE_TRACE_PS4='$(date "+%s.%N (${BASH_SOURCE[0]##*/}:${LINENO})")'
                  fi
               ;;
               *)
                  if [ ${ZSH_VERSION+x} ]
                  then
                     MULLE_TRACE_PS4='$(date "+%s (%1x:%I)")'
                  else
                     MULLE_TRACE_PS4='$(date "+%s (${BASH_SOURCE[0]##*/}:${LINENO})")'
                  fi
               ;;
            esac
         return # don't propagate
      ;;

      -tpwd|--trace-pwd)
         before_trace_fail "${flag}"
         if [ ${ZSH_VERSION+x} ]
         then
            MULLE_TRACE_PS4='%1x:%I \".../\W\"'
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO} \".../\W\"'
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
            MULLE_TRACE_PS4='%1x:%I'
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO}'
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

      --mulle-clear-flags)
         MULLE_TECHNICAL_FLAGS=''
         return 0
      ;;

      --mulle-list-technical-flags)
         echo "\
--dry-run
--mulle-clear-flags
--mulle-no-errors
--mulle-no-colors
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

      --mulle-no-color|--mulle-no-colors)
         MULLE_NO_COLOR='YES'
         logging_deinitialize_color
      ;;

      --mulle-no-error|--mulle-no-errors)
         MULLE_FLAG_LOG_ERROR='NO'
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

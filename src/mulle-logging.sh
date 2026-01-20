# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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
if ! [ ${MULLE_LOGGING_SH+x} ]
then
MULLE_LOGGING_SH='included'


# RESET
# NOCOLOR
#
#    "logging" supplies functions for logging and error handling. It is
#    also responsible for colorization. You can turn off colorization with
#    the environment variable NO_COLOR.
#
#    Some _log_functions, have an alias without the leading underscore.
#    Use the alias in unless your error message is longer than one line and
#    you are using continuations (\). That would break the alias.
#
#    The advantage of the alias is, that it can be eliminated, if output is
#    not needed. This may speed up your script as log_verbose "PWD=`pwd`"
#    would not execute `pwd`. In contrast _log_verbose  "PWD=`pwd`" will
#    execute `pwd`but then forego the output.
#
# TITLE INTRO
# COLOR
#

_log_printf()
{
   local format="$1" ; shift

# convenient place to check something that shouldn't happen
#   [ "$__FAIL__" != 'YES' -a ! -w /tmp/vfl/.mulle/etc/sourcetree/config -a -e /tmp/vfl/.mulle/etc/sourcetree/config ] && __FAIL__='YES' && _internal_fail "fail"

   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE:-}" ]
   then
      printf "${format}" "$@" >&2
   else
      printf "${format}" "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
   fi
}


MULLE_LOG_ERROR_PREFIX=" error: "
MULLE_LOG_FAIL_ERROR_PREFIX=" fatal error: "

#
# _log_error
#
#    _log_error prints out an error message. It can not be squelched
#
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


#
# _log_warning
#
#    _log_warning prints out a warning message.
#    Warnings will not be shown in terse mode (-t).
#
_log_warning()
{
   # don't prefix with warning: just let the colors speak
   # errors are errors though
   if [ "${MULLE_FLAG_LOG_TERSE:-}" != 'YES' ]
   then
      _log_printf "${C_WARNING}%b${C_RESET}\n" "$*"
   fi
}


#
# _log_info
#
#    _log_info prints out an informational message. Infos will not be shown in
#    terse mode (-t).
#
_log_info()
{
   if ! [ "${MULLE_FLAG_LOG_TERSE:-}" = 'YES' -o "${MULLE_FLAG_LOG_TERSE:-}" = 'WARN' ]
   then
      _log_printf "${C_INFO}%b${C_RESET}\n" "$*"
   fi
}


#
# _log_vibe
#
#    _log_vibe prints out an informational message. depending on MULLE_VIBECODING
#    being set to 'YES' this uses _log_info otherwise it will be _log_verbose.
#
_log_vibe()
{
   if [ "${MULLE_VIBECODING:-}" = 'YES' ]
   then
      _log_info "$*"
   else
      if [ ${ZSH_VERSION+x} ]
      then
         local msg="${(j: :)@}"

         # zsh: dreckige nutzlose kack shell
         x="${C_VIBE[3,7]}"
         y="${C_VERBOSE[3,7]}"
         _log_verbose "${msg//$x/$y}"
      else
         _log_verbose "${*//${C_VIBE}/${C_VERBOSE}}"
      fi
   fi
}


#
# _log_verbose
#
#    _log_verbose prints out a message in verbose mode (-v).
#
_log_verbose()
{
   if [ "${MULLE_FLAG_LOG_VERBOSE:-}" = 'YES' ]
   then
      _log_printf "${C_VERBOSE}%b${C_RESET}\n" "$*"
   fi
}


#
# _log_fluff
#
#    _log_fluff prints out a message in increased verbose mode (-vv).
#
_log_fluff()
{
   if [ "${MULLE_FLAG_LOG_FLUFF:-}" = 'YES' ]
   then
      _log_printf "${C_FLUFF}%b${C_RESET}\n" "$*"
   else
      # fluff should be shown when debug is on but not fluff
      _log_debug "$@"
   fi
}


#
# _log_setting
#
#    _log_setting prints out a message in "log settings" (-ls) mode only.
#
_log_setting()
{
   # setting is like fluff but different color scheme
   if [ "${MULLE_FLAG_LOG_SETTINGS:-}" = 'YES' ]
   then
      _log_printf "${C_SETTING}%b${C_RESET}\n" "$*"
   fi
}


#
# _log_debug
#
#    _log_debug prints out a message in "log debug" (-ld) mode only.
#    it preserves colorization in the input strings
_log_debug()
{
   # for debugging, not for user. same as fluff
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



#
# _log_entry
#
#    _log_entry prints out a message in "log debug" (-ld) mode only.
#    Use this at the beggining of a function definition for improved
#    debug-ability.
#
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

   #
   # avoid _log_debug, because we don't want $* to be interpreted for unicode
   # characters .e.g.  c:\Users would be \U unicode
   #
   case "${MULLE_UNAME}" in
      'linux'|'windows')
         _log_printf "${C_DEBUG}$(date "+%s.%N") %s%s${C_RESET}\n" "${functionname}" "${args}"
      ;;

      *)
         _log_printf "${C_DEBUG}$(date "+%s") %s%s${C_RESET}\n" "${functionname}" "${args}"
      ;;
   esac
}


# used by exekutor, so we don't if here ( or ? )
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

# you should NOT be using these log aliases with continuations.
# e.g.
# _log_printf "x \
# y"
# will fail
#
# If you need them use the '_' prefixed variant
# e.g.
# _log_printf "x \
# y"
# is OK

#
# log_debug
#
#    log_debug is an alias for _log_debug. It prints out a message in
#    "log debug" (-ld) mode only.
#
alias log_debug='_log_debug'

#
# log_entry
#
#    log_entry is an alias for _log_entry. It prints out a message in
#    "log debug" (-ld) mode only.
#    Use log_entry at the beginning of a function definition for improved
#    debug-ability.
#
alias log_entry='_log_entry'

#
# log_error
#
#    log_error prints out an error message. It is an alias for _log_error.
#    log_error can not be squelched.
#
alias log_error='_log_error'

#
# log_fluff
#
#    log_fluff prints out a message in increased verbose mode (-vv).
#    log_fluff is an alias for _log_fluff.
#
alias log_fluff='_log_fluff'

#
# log_info
#
#    log_info prints out a message unless in in "terse mode" (-s)
#    log_info is an alias for _log_info.
#
alias log_info='_log_info'

#
# log_info
#
#    log_vibe is an alias for _log_vibe.
#
alias log_vibe='_log_vibe'


#
# log_setting
#
#    Alias for _log_setting. log_setting prints out a message in
#    "log settings" (-ls) mode only.
#
#
alias log_setting='_log_setting'

#
# log_trace
#
#    Alias for _log_trace. log_trace can not be squelched.
#
alias log_trace='_log_trace'

#
# log_verbose
#
#    Alias for _log_verbose. log_verbose prints out a message in verbose
#    mode (-v).
#
alias log_verbose='_log_verbose'

#
# log_warning
#
#    Alias for _log_warning. log_warning will not print in "terse mode" (-t)
#
alias log_warning='_log_warning'


#
# The log level will be in affect in two ways. For functions already parsed
# the `if` in the function selects the print or not. For all functions
# parsed in the future, we can comment out the unneeded log statements. This
# will provide a large speedup.
#
log_set_trace_level()
{
   alias log_debug='_log_debug'
   alias log_entry='_log_entry'
   alias log_error='_log_error'
   alias log_fluff='_log_fluff'
   alias log_info='_log_info'
   alias log_vibe='_log_vibe'
   alias log_setting='_log_setting'
   alias log_trace='_log_trace'
   alias log_verbose='_log_verbose'
   alias log_warning='_log_warning'

   # memo: need ': #' instead of '#' for if then else
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
      # fluff should be shown when debug is on but not fluff
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
      alias log_vibe=': #'
   fi

   if [ "${MULLE_FLAG_LOG_TERSE:-}" = 'YES' ]
   then
      alias log_warning=': #'
   fi
   :
}

#
# some common fail log functions
# caller failed on me in some bizarre fashion once
# 8: #762 /home/src/srcM/MulleEOF/MulleEOUtil/.mulle/var/.env/bin/mulle-sourcetree mulle-sourcetree
# 9: #
# 10: #
# 11: #
# 12: #


if [ ${ZSH_VERSION+x} ]
then
   # inspired by https://unix.stackexchange.com/questions/453144/functions-calling-context-in-zsh-equivalent-of-bash-caller
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
   # don't stack trace when tracing
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


#
# fail
#
#    The mulle-bashfunctions error and exit function.
#
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


#
# _internal_fail
#
#    The mulle-bashfunctions error and exit function with stacktrace.
#    Use this function in assert-like functionality.
#
function _internal_fail()
{
   _log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX}${MULLE_INTERNAL_ERROR_PREFIX}${C_ERROR_TEXT}%b${C_RESET}\n" "$*"
   stacktrace
   exit 1
}


# now that we have _internal_fail defined we can rewrite _fatal
# unset -f _fatal
_fatal()
{
   _internal_fail "$@"
}


# Escape sequence and resets, should use tput here instead of ANSI
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
   # https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
   # https://www.systutorials.com/241795/how-to-judge-whether-its-stderr-is-redirected-to-a-file-in-a-bash-script-on-linux/
   # do not colorize when /dev/stderr is redirected
   # https://no-color.org/

   # fix for Xcode
   case "${TERM:-}" in
      dumb)
         MULLE_NO_COLOR='YES'
      ;;
   esac

   if [ -z "${NO_COLOR:-}" -a "${MULLE_NO_COLOR:-}" != 'YES' ] && [ ! -f /dev/stderr ]
   then
      C_RESET=$'\033'"[0m"

      # Useable Foreground colours, for black/white white/black
      C_RED=$'\033'"[0;31m"     C_GREEN=$'\033'"[0;32m"
      C_BLUE=$'\033'"[0;34m"    C_MAGENTA=$'\033'"[0;35m"
      C_CYAN=$'\033'"[0;36m"

      C_BR_RED=$'\033'"[0;91m"
      C_BR_GREEN=$'\033'"[0;92m"
      C_BR_BLUE=$'\033'"[0;94m"
      C_BR_CYAN=$'\033'"[0;96m"
      C_BR_MAGENTA=$'\033'"[0;95m"
      C_BOLD=$'\033'"[1m"
      C_FAINT=$'\033'"[2m"
      C_UNDERLINE=$'\033'"[4m"
      C_SPECIAL_BLUE=$'\033'"[38;5;39;40m"

      if [ "${MULLE_LOGGING_TRAP:-}" != 'NO' ]
      then
         logging_trap_install
      fi
   fi

   C_RESET_BOLD="${C_RESET}${C_BOLD}"

   C_DEBUG="${C_SPECIAL_BLUE}"
   C_ERROR="${C_BR_RED}${C_BOLD}"
   C_FLUFF="${C_GREEN}${C_BOLD}"
   C_INFO="${C_CYAN}${C_BOLD}"
   C_SETTING="${C_GREEN}${C_FAINT}"
   C_TRACE2="${C_RESET}${C_FAINT}"
   C_TRACE="${C_FLUFF}${C_FAINT}"
   C_VERBOSE="${C_GREEN}${C_BOLD}"
   C_WARNING="${C_RED}${C_BOLD}"

   C_VIBE="${C_INFO}"

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

   C_DEBUG="${C_SPECIAL_BLUE}"
   C_ERROR="${C_BR_RED}${C_BOLD}"
   C_FLUFF="${C_GREEN}${C_BOLD}"
   C_INFO="${C_CYAN}${C_BOLD}"
   C_SETTING="${C_GREEN}${C_FAINT}"
   C_TRACE2="${C_RESET}${C_FAINT}"
   C_TRACE="${C_FLUFF}${C_FAINT}"
   C_VERBOSE="${C_GREEN}${C_BOLD}"
   C_WARNING="${C_RED}${C_BOLD}"

   C_VIBE="${C_INFO}"

   C_ERROR_TEXT="${C_RESET}${C_BR_RED}${C_BOLD}"
}


logging_initialize()
{
   logging_initialize_color
}


logging_initialize "$@"

fi
:

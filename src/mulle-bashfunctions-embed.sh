
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
         read -r DEFAULT_IFS < /proc/sys/kernel/osrelease
         case "${DEFAULT_IFS}" in
            *-Microsoft)
               MULLE_UNAME="windows"
               MULLE_EXE_EXTENSION=".exe"
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
[ ! -z "${MULLE_PATH_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-path.sh" >&2

[ -z "${MULLE_STRING_SH}" ] && echo "mulle-string.sh must be included before mulle-path.sh" 2>&1 && exit 1


MULLE_PATH_SH="included"


r_path_depth()
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

         depth=$(($depth + 1))
      done
   fi
   RVAL="$depth"
}


r_extensionless_basename()
{
   r_basename "$@"

   RVAL="${RVAL%.*}"
}



r_path_extension()
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


r_canonicalize_path()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      _r_canonicalize_dir_path "$1"
   else
      _r_canonicalize_file_path "$1"
   fi
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

   if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
   then
      set +x
   fi


   r_simplified_path "$1"
   a="${RVAL}"
   r_simplified_path "$2"
   b="${RVAL}"


   [ -z "${a}" ] && internal_fail "Empty path (\$1)"
   [ -z "${b}" ] && internal_fail "Empty path (\$2)"

   __r_relative_path_between "${b}" "${a}"   # flip args (historic)

   if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
   then
      set -x
   fi
}

r_relative_path_between()
{
   local a="$1"
   local b="$2"


   case "${a}" in
      "")
         internal_fail "First path is empty"
      ;;

      ../*|*/..|*/../*|..)
         internal_fail "Path \"${a}\" mustn't contain .."
      ;;

      ./*|*/.|*/./*|.)
         internal_fail "Filename \"${a}\" mustn't contain component \".\""
      ;;


      /*)
         case "${b}" in
            "")
               internal_fail "Second path is empty"
            ;;

            ../*|*/..|*/../*|..)
               internal_fail "Filename \"${b}\" mustn't contain \"..\""
            ;;

            ./*|*/.|*/./*|.)
               internal_fail "Filename \"${b}\" mustn't contain \".\""
            ;;


            /*)
            ;;

            *)
               internal_fail "Mixing absolute filename \"${a}\" and relative filename \"${b}\""
            ;;
         esac
      ;;

      *)
         case "${b}" in
            "")
               internal_fail "Second path is empty"
            ;;

            ../*|*/..|*/../*|..)
               internal_fail "Filename \"${b}\" mustn't contain component \"..\"/"
            ;;

            ./*|*/.|*/./*|.)
               internal_fail "Filename \"${b}\" mustn't contain component \".\""
            ;;

            /*)
               internal_fail "Mixing relative filename \"${a}\" and absolute filename \"${b}\""
            ;;

            *)
            ;;
         esac
      ;;
   esac

   _r_relative_path_between "${a}" "${b}"
}


r_compute_relative()
{
   local name="$1"

   local depth
   local relative

   r_path_depth "${name}"
   depth="${RVAL}"

   if [ "${depth}" -gt 1 ]
   then
      relative=".."
      while [ "$depth" -gt 2 ]
      do
         relative="${relative}/.."
         depth=$(($depth - 1))
      done
   fi


   RVAL="${relative}"
}



r_physicalpath()
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


physicalpath()
{
   if ! r_physicalpath "$@"
   then
      return 1
   fi
   printf "%s\n" "${RVAL}"
}


is_absolutepath()
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


is_relativepath()
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


r_absolutepath()
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


r_simplified_absolutepath()
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


r_symlink_relpath()
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


   remove_empty='NO'  # remove trailing slashes

   IFS="/"
   shell_disable_glob
   for i in ${filepath}
   do
      shell_enable_glob
      case "$i" in
         \.)
           remove_empty='YES'
           continue
         ;;

         \.\.)
           remove_empty='YES'

           if [ "${last}" = "|" ]
           then
              continue
           fi

           if [ ! -z "${last}" -a "${last}" != ".." ]
           then
              r_remove_last_line "${result}"
              result="${RVAL}"
              r_get_last_line "${result}"
              last="${RVAL}"
              continue
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
            continue
         ;;
      esac

      remove_empty='YES'

      last="${i}"

      r_add_line "${result}" "${i}"
      result="${RVAL}"
   done

   IFS="${DEFAULT_IFS}"
   shell_enable_glob

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

   RVAL="`tr -d '|' <<< "${result}" | tr '\012' '/'`"
   RVAL="${RVAL%/}"
}


r_simplified_path()
{
   case "${1}" in
      ""|".")
         RVAL="."
      ;;

      */|*\.\.*|*\./*|*/\.)
         if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
         then
            set +x
         fi

         _r_simplified_path "$@"

         if [ "${MULLE_TRACE_PATHS_FLIP_X}" = 'YES' ]
         then
            set -x
         fi
      ;;

      *)
         RVAL="$1"
      ;;
   esac
}


assert_sane_subdir_path()
{
   r_simplified_path "$1"

   case "${RVAL}"  in
      "")
         fail "refuse empty subdirectory \"$1\""
         exit 1
      ;;

      \$*|~|..|.|/*)
         fail "refuse unsafe subdirectory path \"$1\""
      ;;
   esac
}


r_assert_sane_path()
{
   r_simplified_path "$1"

   case "${RVAL}" in
      \$*|~|${HOME}|..|.)
         log_error "refuse unsafe path \"$1\""
         exit 1
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
   esac
}

:
[ ! -z "${MULLE_FILE_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-file.sh" >&2

[ -z "${MULLE_PATH_SH}" ]     && echo "mulle-path.sh must be included before mulle-file.sh" 2>&1 && exit 1
[ -z "${MULLE_EXEKUTOR_SH}" ] && echo "mulle-exekutor.sh must be included before mulle-file.sh" 2>&1 && exit 1


MULLE_FILE_SH="included"


mkdir_if_missing()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      return 0
   fi

   log_fluff "Creating directory \"$1\" (${PWD#${MULLE_USER_PWD}/})"

   local rval

   exekutor mkdir -p "$1"
   rval="$?"

   if [ "${rval}" -eq 0 ]
   then
      return 0
   fi

   if [ -L "$1" ]
   then
      r_resolve_symlinks "$1"
      if [ ! -d "${RVAL}" ]
      then
         fail "failed to create directory \"$1\" as a symlink is there"
      fi
      return 0
   fi

   if [ -f "$1" ]
   then
      fail "failed to create directory \"$1\" because a file is there"
   fi
   fail "failed to create directory \"$1\" from $PWD ($rval)"
}


r_mkdir_parent_if_missing()
{
   local dstdir="$1"

   r_dirname "${dstdir}"
   case "${RVAL}" in
      ""|\.)
      ;;

      *)
         mkdir_if_missing "${RVAL}"
         return $?
      ;;
   esac

   return 1
}


mkdir_parent_if_missing()
{
   r_mkdir_parent_if_missing "$@"
}


dir_is_empty()
{
   [ -z "$1" ] && internal_fail "empty path"

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
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      r_assert_sane_path "$1"
      exekutor chmod -R ugo+wX "${RVAL}" >&2 || fail "Failed to make \"${RVAL}\" writable"
      exekutor rm -rf "${RVAL}"  >&2 || fail "failed to remove \"${RVAL}\""
   fi
}


rmdir_if_empty()
{
   [ -z "$1" ] && internal_fail "empty path"

   if dir_is_empty "$1"
   then
      exekutor rmdir "$1"  >&2 || fail "failed to remove $1"
   fi
}


_create_file_if_missing()
{
   local filepath="$1" ; shift

   [ -z "${filepath}" ] && internal_fail "empty path"

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


merge_line_into_file()
{
  local line="$1"
  local filepath="$2"

  if fgrep -s -q -x "${line}" "${filepath}" 2> /dev/null
  then
     return
  fi
  redirect_append_exekutor "${filepath}" printf "%s\n" "${line}"
}


create_file_if_missing()
{
   _create_file_if_missing "$1" "# intentionally blank file"
}


_remove_file_if_present()
{
   [ -z "$1" ] && internal_fail "empty path"

   if ! exekutor rm -f "$1" 2> /dev/null
   then
      exekutor chmod u+w "$1"  || fail "Failed to make $1 writable"
      exekutor rm -f "$1"      || fail "failed to remove \"$1\""
   fi
   return 0
}


remove_file_if_present()
{
   if [ -e "$1"  -o -L "$1" ] && _remove_file_if_present "$1"
   then
      log_fluff "Removed \"${1#${PWD}/}\" (${PWD#${MULLE_USER_PWD}/})"
      return 0
   fi
   return 1
}


_make_tmp_in_dir_mktemp()
{
   local tmpdir="$1"
   local name="$2"
   local filetype="$3"

   case "${filetype}" in
      *d*)
         TMPDIR="${tmpdir}" exekutor mktemp -d "${name}-XXXXXXXX"
      ;;

      *)
         TMPDIR="${tmpdir}" exekutor mktemp "${name}-XXXXXXXX"
      ;;
   esac
}


_r_make_tmp_in_dir_uuidgen()
{
   local UUIDGEN="$1"; shift

   local tmpdir="$1"
   local name="$2"
   local filetype="$3"

   local uuid
   local fluke

   local MKDIR
   local TOUCH

   MKDIR="$(command -v mkdir)"
   TOUCH="$(command -v touch)"

   [ -z "${MKDIR}" ] && fail "No \"mkdir\" found in PATH ($PATH)"
   [ -z "${TOUCH}" ] && fail "No \"touch\" found in PATH ($PATH)"

   fluke=0
   RVAL=''

   while :
   do
      uuid="`${UUIDGEN}`"
      RVAL="${tmpdir}/${name}-${uuid:0:8}"

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
         if [ "${fluke}" -lt 3 ]
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
   local filetype="$3"

   mkdir_if_missing "${tmpdir}"

   [ ! -w "${tmpdir}" ] && fail "${tmpdir} does not exist or is not writable"

   name="${name:-${MULLE_EXECUTABLE_NAME}}"
   name="${name:-mulle}"

   local UUIDGEN

   UUIDGEN="`command -v "uuidgen"`"
   if [ ! -z "${UUIDGEN}" ]
   then
      _r_make_tmp_in_dir_uuidgen "${UUIDGEN}" "${tmpdir}" "${name}" "${filetype}"
      return $?
   fi

   RVAL="`_make_tmp_in_dir_mktemp "${tmpdir}" "${name}" "${filetype}"`"
   return $?
}


r_make_tmp()
{
   local name="$1"
   local filetype="$2"

   local tmpdir

   tmpdir=
   case "${MULLE_UNAME}" in
      darwin)
      ;;

      *)
         r_filepath_cleaned "${TMPDIR}"
         tmpdir="${RVAL}"
      ;;
   esac
   tmpdir="${tmpdir:-/tmp}"

   _r_make_tmp_in_dir "${tmpdir}" "${name}" "${filetype}"
}


r_make_tmp_file()
{
   r_make_tmp "$1" "f"
}

r_make_tmp_directory()
{
   r_make_tmp "$1" "d"
}



r_resolve_all_path_symlinks()
{
   local filepath="$1"

   local resolved

   r_resolve_symlinks "${filepath}"
   resolved="${RVAL}"

   local filename
   local directory
   local resolved

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


r_realpath()
{
   [ -e "$1" ] || fail "only use r_realpath on existing files ($1)"

   r_resolve_symlinks "$1"
   r_canonicalize_path "${RVAL}"
}

create_symlink()
{
   local url="$1"       # URL of the clone
   local stashdir="$2"  # stashdir of this clone (absolute or relative to $PWD)
   local absolute="$3"

   [ -e "${url}" ]        || fail "${C_RESET}${C_BOLD}${url}${C_ERROR} does not exist (${PWD#${MULLE_USER_PWD}/})"
   [ ! -z "${absolute}" ] || fail "absolute must be YES or NO"

   r_absolutepath "${url}"
   r_realpath "${RVAL}"
   url="${RVAL}"        # resolve symlinks


   local directory
   r_dirname "${stashdir}"
   directory="${RVAL}"

   mkdir_if_missing "${directory}"
   r_realpath "${directory}"
   directory="${RVAL}"  # resolve symlinks

   if [ "${absolute}" = 'NO' ]
   then
      r_symlink_relpath "${url}" "${directory}"
      url="${RVAL}"
   fi

   local oldlink

   if [ -L "${oldlink}" ]
   then
      oldlink="`readlink "${stashdir}"`"
   fi

   if [ -z "${oldlink}" -o "${oldlink}" != "${url}" ]
   then
      exekutor ln -s -f "${url}" "${stashdir}" >&2 || \
         fail "failed to setup symlink \"${stashdir}\" (to \"${url}\")"
   fi
}


modification_timestamp()
{
   case "${MULLE_UNAME}" in
      linux|mingw)
         stat --printf "%Y\n" "$1"
      ;;

      * )
         stat -f "%m" "$1"
      ;;
   esac
}


lso()
{
   ls -aldG "$@" | \
   awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print }' | \
   awk '{print $1}'
}


file_is_binary()
{
   local result

   result="`file -b --mime-encoding "$1"`"
   [ "${result}" = "binary" ]
}



dir_has_files()
{
   local dirpath="$1"; shift

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


dirs_contain_same_files()
{
   log_entry "dirs_contain_same_files" "$@"

   local etcdir="$1"
   local sharedir="$2"

   if [ ! -d "${etcdir}" -o ! -e "${etcdir}" ]
   then
      internal_fail "Both directories \"${etcdir}\" and \"${sharedir}\" need to exist"
   fi

   etcdir="${etcdir%%/}"
   sharedir="${sharedir%%/}"

   local etcfile
   local sharefile
   local filename 

   IFS=$'\n'; shell_disable_glob
   for sharefile in `find ${sharedir}  \! -type d -print`
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      filename="${sharefile#${sharedir}/}"
      etcfile="${etcdir}/${filename}"

      if ! diff -q -b "${etcfile}" "${sharefile}" > /dev/null
      then
         return 2
      fi
   done

   IFS=$'\n'; shell_disable_glob

   for etcfile in `find ${etcdir} \! -type d -print`
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      filename="${etcfile#${etcdir}/}"
      sharefile="${sharedir}/${filename}"

      if [ ! -e "${sharefile}" ]
      then
         return 2
      fi
   done

   IFS="${DEFAULT_IFS}"; shell_enable_glob

   return 0
}





inplace_sed()
{
   local tmpfile
   local args
   local filename

   local rval 

   case "${MULLE_UNAME}" in
      darwin|freebsd)

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


:
[ "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' -a ! -z "${MULLE_ARRAY_SH}" ] && \
   echo "double inclusion of mulle-array.sh" >&2

[ -z "${MULLE_LOGGING_SH}" ] && echo "mulle-logging.sh must be included before mulle-array.sh" 2>&1 && exit 1

MULLE_ARRAY_SH="included"


array_value_check()
{
   local value="$1"

   case "${value}" in
      *$'\n'*)
         internal_fail "\"${value}\" has unescaped linefeeds"
      ;;
   esac
}


r_get_line_at_index()
{
   local array="$1"
   local i="${2:-0}"


   shell_disable_glob; IFS=$'\n'
   for RVAL in ${array}
   do
      if [ $i -eq 0 ]
      then
         IFS="${DEFAULT_IFS}" ; shell_enable_glob
         return 0
      fi
      i=$((i - 1))
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob
   return 1
}


r_insert_line_at_index()
{
   local array="$1"
   local i="$2"
   local value="$3"

   array_value_check "${value}"

   local line
   local added='NO'
   local rval

   RVAL=
   rval=1

   shell_disable_glob; IFS=$'\n'
   for line in ${array}
   do
      if [ $i -eq 0 ]
      then
         r_add_line "${RVAL}" "${value}"
         rval=0
      fi
      r_add_line "${RVAL}" "${line}"
      i=$((i - 1))
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   if [ $i -eq 0 ]
   then
      r_add_line "${RVAL}" "${value}"
      rval=0
   fi

   return $rval
}



r_lines_in_range()
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




assoc_array_key_check()
{
   local key="$1"

   [ -z "${key}" ] && internal_fail "key is empty"

   local identifier

   r_identifier "${key}"
   identifier="${RVAL}"

   [ "${identifier}" != "${key}" -a "${identifier}" != "_${key}" ] && internal_fail "\"${key}\" has non-identifier characters"
}


assoc_array_value_check()
{
   array_value_check "$@"
}


_r_assoc_array_add()
{
   local array="$1"
   local key="$2"
   local value="$3"

   assoc_array_key_check "${key}"
   assoc_array_value_check "${value}"


   r_add_line "${array}" "${key}=${value}"
}


_r_assoc_array_remove()
{
   local array="$1"
   local key="$2"

   local line
   local delim

   RVAL=
   shell_disable_glob; IFS=$'\n'
   for line in ${array}
   do
      case "${line}" in
         "${key}="*)
         ;;

         *)
            RVAL="${line}${delim}${RVAL}"
            delim=$'\n'
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob
}


r_assoc_array_get()
{
   local array="$1"
   local key="$2"


   local line
   local rval

   RVAL=
   rval=1

   shell_disable_glob; IFS=$'\n'
   for line in ${array}
   do
      case "${line}" in
         "${key}="*)
            RVAL="${line#*=}"
            rval=0
            break
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   return $rval
}


assoc_array_all_keys()
{
   local array="$1"

   sed -n 's/^\([^=]*\)=.*$/\1/p' <<< "${array}"
}


assoc_array_all_values()
{
   local array="$1"

   sed -n 's/^[^=]*=\(.*\)$/\1/p' <<< "${array}"
}


r_assoc_array_set()
{
   local array="$1"
   local key="$2"
   local value="$3"

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


assoc_array_merge_with_array()
{
   local array1="$1"
   local array2="$2"

   printf "%s%s\n" "${array2}" "${array1}" | sort -u -t'=' -k1,1
}


assoc_array_augment_with_array()
{
   local array1="$1"
   local array2="$2"

   printf "%s%s\n" "${array1}" "${array2}" | sort -u -t'=' -k1,1
}

:

[ ! -z "${MULLE_CASE_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-case.sh" >&2

MULLE_CASE_SH="included"

_r_tweaked_de_camel_case()
{
   local s="$1"

   local output
   local state
   local collect

   local c
   local d

   s="${s//ObjC/Objc}"

   state='start'
   while [ ! -z "${s}" ]
   do
      d="${c}"
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
                     output="${output}${collect}"
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


r_tweaked_de_camel_case()
{
   LC_ALL=C _r_tweaked_de_camel_case "$@"
}


r_de_camel_case_upcase_identifier()
{
   r_tweaked_de_camel_case "$1"
   r_identifier "${RVAL}"
   r_uppercase "${RVAL}"

   case "${RVAL}" in
      [A-Za-z_]*)
      ;;

      *)
         RVAL="_${RVAL}"
      ;;
   esac
}
MULLE_PARALLEL_SH="included"

[ -z "${MULLE_FILE_SH}" ] && echo "mulle-file.sh must be included before mulle-parallel.sh" 2>&1 && exit 1


very_short_sleep()
{
   case "${MULLE_UNAME}" in 
      darwin)
         sleep 0.001 #s # 1000Hz  
      ;;

      *)
         sleep 0.001s #s # 1000Hz  
      ;;
   esac
}  

r_get_core_count()
{
   if [ -z "${MULLE_CORES}" ]
   then
      MULLE_CORES="`/usr/bin/nproc 2> /dev/null`"
      if [ -z "${MULLE_CORES}" ]
      then
         MULLE_CORES="`/usr/sbin/sysctl -n hw.ncpu 2> /dev/null`"
      fi

      if [ -z "${MULLE_CORES}" ]
      then
         MULLE_CORES=4
         log_verbose "Unknown core count, setting it to 4 as default"
      fi
   fi
   RVAL=${MULLE_CORES}
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

   while :
   do
      running=($(jobs -pr))  #  http://mywiki.wooledge.org/BashFAQ/004
      count=${#running[@]}

      if [ ${count} -le ${maxjobs} ]
      then
         log_debug "Currently only ${count} jobs run, spawn another"
         break
      fi
      log_debug "Waiting on jobs to finish (${#running[@]})"
      very_short_sleep
   done
}


get_current_load_average()
{
   case "${MULLE_UNAME}" in
      freebsd|darwin)
         sysctl -n vm.loadavg | sed -n -e 's/.*{[ ]*\([0-9]*\).*/\1/p'
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

   if [ -z "${maxavg}" ]
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


_parallel_begin()
{
   log_entry "_parallel_begin" "$@"

   _parallel_maxjobs="$1"

   _parallel_jobs=0
   _parallel_fails=0

   r_make_tmp "mulle-parallel" || exit 1
   _parallel_statusfile="${RVAL}"

   if [ -z "${_parallel_maxjobs}" ]
   then
      _parallel_maxjobs="${MULLE_PARALLEL_MAX_JOBS}"
      if [ -z "${_parallel_maxjobs}" ]
      then
         r_get_core_count
         _parallel_maxjobs="${RVAL}"
      fi
   fi
}


_parallel_end()
{
   log_entry "_parallel_end" "$@"

   wait

   _parallel_fails="`rexekutor wc -l "${_parallel_statusfile}" | awk '{ printf $1 }'`"
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "_parallel_jobs : ${_parallel_jobs}"
      log_trace2 "_parallel_fails: ${_parallel_fails}"
      log_trace2 "${_parallel_statusfile} : `cat "${_parallel_statusfile}"`"
   fi

   exekutor rm "${_parallel_statusfile}"

   [ "${_parallel_fails}" -eq 0 ]
}


_parallel_status()
{
   log_entry "_parallel_status" "$@"

   local rval="$1"; shift

   [ -z "${_parallel_statusfile}" ] && internal_fail "_parallel_statusfile must be defined"

   if [ $rval -ne 0 ]
   then
      log_warning "warning: $* failed with $rval"
      redirect_append_exekutor "${_parallel_statusfile}" printf "%s\n" "${rval};$*"
   fi
}


_parallel_execute()
{
   log_entry "_parallel_execute" "$@"

   wait_for_available_job "${_parallel_maxjobs}"
   _parallel_jobs=$(($_parallel_jobs + 1))

   log_debug "Running job #${_parallel_jobs}: $*"

   (
      local rval

      ( exekutor "$@" ) # run in subshell to capture exit code
      _parallel_status $? "$@"
   ) &
}


parallel_execute()
{
   log_entry "parallel_execute" "$@"

   local arguments="$1"; shift

   local _parallel_statusfile
   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails

   [ $# -eq 0 ] && internal_fail "missing commandline"

   _parallel_begin

   local argument

   shell_disable_glob;  IFS=$'\n'
   for argument in ${arguments}
   do
      shell_enable_glob; IFS="${DEFAULT_IFS}"

      _parallel_execute "$@" "${argument}"
   done

   shell_enable_glob; IFS="${DEFAULT_IFS}"

   _parallel_end
}

[ ! -z "${MULLE_VERSION_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-version.sh" >&2

MULLE_VERSION_SH="included"


r_get_version_major()
{
   RVAL="${1%%\.*}"
}


r_get_version_minor()
{
   RVAL="${1#*\.}"
   if [ "${RVAL}" = "$1" ]
   then
      RVAL=0
   else
      RVAL="${RVAL%%\.*}"
   fi
}

r_get_version_patch()
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


check_version()
{
   local version="$1"
   local min_major="$2"
   local min_minor="$3"

   if [ -z "${version}" ]
   then
      return 1
   fi

   local major
   local minor

   r_get_version_major "${version}"
   major="${RVAL}"

   if [ "${major}" -lt "${min_major}" ]
   then
      return 0
   fi

   if [ "${major}" -ne "${min_major}" ]
   then
      return 1
   fi

   r_get_version_minor "${version}"
   minor="${RVAL}"

   [ "${minor}" -le "${min_minor}" ]
}


_r_version_value()
{
   RVAL="$((${1:-0} * 1048576 + ${2:-0} * 256 + ${3:-0}))"
}


r_version_value()
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


r_version_value_distance()
{
   RVAL="$(($2 - $1))"
}


r_version_distance()
{
   local value1
   local value2

   r_version_value "$1"
   value1="${RVAL}"
   r_version_value "$2"
   value2="${RVAL}"

   r_version_value_distance "${value1}" "${value2}"
}


is_compatible_version_value_distance()
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


is_compatible_version()
{
   r_version_distance "$1" "$2"
   is_compatible_version_value_distance "${RVAL}"
}

:
[ ! -z "${MULLE_ETC_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-etc.sh" >&2

MULLE_ETC_SH="included"


etc_prepare_for_write_of_file()
{
   log_entry "etc_prepare_for_write_of_file" "$@"

   local filename="$1"

   if [ -L "${filename}" ]
   then
      exekutor rm "${filename}"
   fi
}


etc_make_file_from_symlinked_file()
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
      flags="-v"
   fi

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
      cd "${directory}" || exit 1

      if [ ! -f "${targetfile}" ]
      then
         log_fluff "Stale link encountered"
         return 0
      fi

      exekutor cp ${flags} "${targetfile}" "${filename}" || exit 1
      exekutor chmod ug+w "${filename}"
   ) || fail "Could not copy \"${targetfile}\" to \"${dstfile}\""
}


etc_symlink_or_copy_file()
{
   log_entry "etc_symlink_or_copy_file" "$@"

   local srcfile="$1"
   local dstdir="$2"
   local filename="$3"
   local symlink="$4"

   [ -f "${srcfile}" ] || internal_fail "\"${srcfile}\" does not exist or is not a file"
   [ -d "${dstdir}" ]  || internal_fail "\"${dstdir}\" does not exist or is not a directory"

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
      fail "\"${dstfile}\" already exists"
   fi

   r_mkdir_parent_if_missing "${dstfile}"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      flags="-v"
   fi

   if [ -z "${symlink}" ]
   then
      case "${MULLE_UNAME}" in
         mingw)
            symlink="NO"
         ;;

         *)
            symlink="YES"
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


etc_setup_from_share_if_needed()
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
      flags="-v"
   fi

   local filename
   local base

   if [ -d "${share}" ] # sometimes it's not there, but find complains
   then
      IFS=$'\n'; shell_disable_glob
      for filename in `find "${share}" ! -type d -print`
      do
         IFS="${DEFAULT_IFS}"; shell_enable_glob
         r_basename "${filename}"
         etc_symlink_or_copy_file "${filename}" \
                                  "${etc}" \
                                  "${RVAL}" \
                                  "${symlink}"
      done
      IFS="${DEFAULT_IFS}"; shell_enable_glob
   fi
}


etc_remove_if_possible()
{
   log_entry "etc_remove_if_possible" "$@"

   local etc="$1"
   local share="$2"

   if [ ! -d "${etc}" ]
   then
      return
   fi

   if dirs_contain_same_files "${etc}" "${share}"
   then
      rmdir_safer "${etc}"
   fi
}


etc_repair_files()
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

   IFS=$'\n'; shell_disable_glob
   for dstfile in `find "${dstdir}" ! -type d -print` # dstdir is etc
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

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
            if diff -q -b "${dstfile}" "${srcfile}" > /dev/null
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
   done

   IFS=$'\n'; shell_disable_glob
   for srcfile in `find "${srcdir}" ! -type d -print` # dstdir is etc
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

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
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   if [ "${can_remove_etc}" = 'YES' ]
   then
      log_info "\"${dstdir#${MULLE_USER_PWD}/}\" contains no user changes so use \"share\" again"
      rmdir_safer "${dstdir}"
      rmdir_if_empty "${srcdir}"
   fi
}

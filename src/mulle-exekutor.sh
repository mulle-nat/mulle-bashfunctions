# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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
if ! [ ${MULLE_EXEKUTOR_SH+x} ]
then
MULLE_EXEKUTOR_SH='included'

[ -z "${MULLE_LOGGING_SH}" ] && \
   echo "mulle-logging.sh must be included before mulle-exekutor.sh" 2>&1 && exit 1



# ####################################################################
#                          Execution
# ####################################################################
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

#
# exekutor ...
#
#   Execute following command line, like the shell would. If tracing is
#   enabled, this will generate thr tracing output. If dry run is enabled,
#   the actual command line is not actually executed.
#
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


#
# rexecutor ...
#
#   Execute following command line, like the shell would. If tracing is
#   enabled, this will generate thr tracing output. The rexekutor promises only
#   to read and is therefore deemed harmless and will execute, if dry run is
#   enabled.
#
function rexekutor()
{
   exekutor_trace "exekutor_print" "$@"

   "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


#
# eval_exekutor ...
#
#   eval version fo the exekutor
#
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


#
# eval_rexekutor ...
#
#   eval version fo the rexekutor
#
function eval_rexekutor()
{
   exekutor_trace "eval_exekutor_print" "$@"

   eval "$@"
   MULLE_EXEKUTOR_RVAL=$?

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-127}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


#
# redirect_exekutor <output> ...
#
#   The redirect_exekutor version fo the exekutor, will store stdout of the
#   executed command line into <output>
#
function redirect_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
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



#
# redirect_eval_exekutor <output> ...
#
#   eval version of the redirect_exekutor
#
function redirect_eval_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
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


#
# redirect_append_exekutor <output> ...
#
#   The redirect_exekutor version fo the exekutor, will append stdout of the
#   executed command line to <output>
#
redirect_append_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
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
   # You have a funny "not found" problem ? the base directory of output is missing!
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
   # You have a funny "not found" problem ? the base directory of output is missing!
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
   # You have a funny "not found" problem ? the base directory of output is missing!
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


#
# logging_tee_exekutor <output> <teeoutput> ...
#
#   This exekutor is like the redirect_exekutor, but can store output in
#   two different files. Useful for creating log files and console output
#   at the same time.
#
#   Output is supposed to be the logfile and teeoutput the console
#
function logging_tee_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   # if we are tracing, we don't want to see this twice
   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" != 'YES' ]
   then
      exekutor_print "$@" >> "${teeoutput}"
   fi
   exekutor_print "$@" >> "${output}"

   _append_tee_exekutor "${output}" "${teeoutput}" "$@"
}


#
# logging_tee_eval_exekutor <output> <teeoutput> ...
#
#    eval version of the logging_tee_exekutor
#
function logging_tee_eval_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   # if we are tracing, we don't want to see this twice
   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" != 'YES' ]
   then
      eval_exekutor_print "$@" >> "${teeoutput}"
   fi
   eval_exekutor_print "$@" >> "${output}"

   _append_tee_eval_exekutor "${output}" "${teeoutput}" "$@"
}


#
# logging_redirekt_exekutor <output>  ...
#
#    Also add trace output to <output> in addition to stdout of the command
#    line.
#
function logging_redirekt_exekutor()
{
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" != 'YES' ]
   then
      exekutor_print "$@" >> "${output}"
   fi
   redirect_append_exekutor "${output}" "$@"
}


#
# logging_redirect_eval_exekutor <output>  ...
#
#    Eval version of logging_redirekt_exekutor
#
function logging_redirect_eval_exekutor()
{
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR:-}" != 'YES' ]
   then
      eval_exekutor_print "$@" >> "${output}"
   fi
   _redirect_append_eval_exekutor "${output}" "$@"
}


#
# rexecute_column_table_or_cat <separator> ...
#
#    If neither the mulle-column command nor the column is installed in the
#    system use cat as th fallback for output-
#
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

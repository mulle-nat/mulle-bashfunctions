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
      printf "%s" " `echo \"$1\"`"
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

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-2}" ] && stacktrace

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

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-2}" ] && stacktrace

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

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-2}" ] && stacktrace

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

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-2}" ] && stacktrace

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

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-2}" ] && stacktrace

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

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-2}" ] && stacktrace

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

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-2}" ] && stacktrace

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

   [ "${MULLE_EXEKUTOR_RVAL}" = "${MULLE_EXEKUTOR_STRACKTRACE_RVAL:-2}" ] && stacktrace

   return ${MULLE_EXEKUTOR_RVAL}
}


logging_tee_eval_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   eval_exekutor_print "$@" | tee -a "${teeoutput}" "${output}"
   _append_tee_eval_exekutor "${output}" "${teeoutput}" "$@"
}


#
# output eval trace also into logfile
#
logging_redirekt_exekutor()
{
   local output="$1"; shift

   exekutor_print "$@" > "${output}"
   redirect_append_exekutor "${output}" "$@"
}


logging_redirect_eval_exekutor()
{
   local output="$1"; shift

   eval_exekutor_print "$@" > "${output}"
   _redirect_append_eval_exekutor "${output}" "$@"
}


:

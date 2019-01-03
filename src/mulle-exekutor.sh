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

exekutor_trace()
{
   if [  "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
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

      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "${arrow}" "$@" >&2
      else
         echo "${arrow}" "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi
}


exekutor_trace_output()
{
   local redirect="$1"; shift
   local output="$1"; shift

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
      local arrow

      [ -z "${MULLE_EXECUTABLE_PID}" ] && internal_fail "MULLE_EXECUTABLE_PID not set"

      # redirect exekutors are run in a subshell, so BASHPID is wrong
      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" \
           -a ! -z "${BASHPID}" \
           -a "${MULLE_EXECUTABLE_PID}" != "${BASHPID}" ]
      then
         arrow="=[${BASHPID}]=>"
      else
         arrow="==>"
      fi

      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "${arrow}" "$@" "${redirect}" "${output}" >&2
      else
         echo "${arrow}" "$@" "${redirect}" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi
}


exekutor()
{
   exekutor_trace "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   "$@"
}


#
# the rexekutor promises only to read and is therefore harmless
#
rexekutor()
{
   exekutor_trace "$@"

   "$@"
}


eval_exekutor()
{
   exekutor_trace "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   eval "$@"
}


#
# declared as harmless (read only)
# old name reval_exekutor didnt make much sense
#
eval_rexekutor()
{
   exekutor_trace "$@"

   eval "$@"
}


_eval_exekutor()
{
   exekutor_trace "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   eval "$@"
}


redirect_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
   local output="$1"; shift

   exekutor_trace_output '>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( "$@" ) > "${output}"
}


redirect_eval_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
   local output="$1"; shift

   exekutor_trace_output '>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( eval "$@" ) > "${output}"
}


redirect_append_exekutor()
{
   # funny not found problem ? the base directory of output is missing!a
   local output="$1"; shift

   exekutor_trace_output '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( "$@" ) >> "${output}"
}


_redirect_append_eval_exekutor()
{
   # You have a funny "not found" problem ? the base directory of output is missing!
   local output="$1"; shift

   exekutor_trace_output '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( eval "$@" ) >> "${output}"
}

#
# output eval trace also into logfile
#
logging_redirekt_exekutor()
{
   local output="$1"; shift

   local arrow

   if [ "${PPID}" -ne "${MULLE_EXECUTABLE_PID}" ]
   then
      arrow="=[${PPID}]=>"
   else
      arrow="==>"
   fi

   echo "${arrow}" "$@" > "${output}"
   redirect_append_exekutor "${output}" "$@"
}


logging_redirect_eval_exekutor()
{
   local output="$1"; shift

   # overwrite
   local arrow

   if [ "${PPID}" -ne "${MULLE_EXECUTABLE_PID}" ]
   then
      arrow="=[${PPID}]=>"
   else
      arrow="==>"
   fi

   echo "${arrow}" "$*" > "${output}"
   _redirect_append_eval_exekutor "${output}" "$@"
}


_redirect_append_tee_eval_exekutor()
{
   # You have a funny "not found" problem ? the base directory of output is missing!
   local output="$1"; shift
   local teeoutput="$1"; shift

   exekutor_trace_output '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return
   fi

   ( eval "$@" ) | tee -a "${teeoutput}" >> "${output}"
}


logging_redirect_tee_eval_exekutor()
{
   local output="$1"; shift
   local teeoutput="$1"; shift

   # overwrite
   local arrow

   if [ "${PPID}" -ne "${MULLE_EXECUTABLE_PID}" ]
   then
      arrow="=[${PPID}]=>"
   else
      arrow="==>"
   fi

   echo "${arrow}" "$*" tee "${teeoutput}" > "${output}"
   _redirect_append_tee_eval_exekutor "${output}" "${teeoutput}" "$@"
}

:

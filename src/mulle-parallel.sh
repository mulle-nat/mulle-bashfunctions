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
MULLE_PARALLEL_SH="included"


r_get_core_count()
{
   if [ -z "${MULLE_CORES}" ]
   then
      MULLE_CORES="`nproc 2> /dev/null`"
      if [ -z "${MULLE_CORES}" ]
      then
         MULLE_CORES="`sysctl -n hw.ncpu 2> /dev/null`"
      fi

      if [ -z "${MULLE_CORES}" ]
      then
         MULLE_CORES=4
         log_verbose "Unknown core count, setting it to 4 as default"
      fi
   fi
   RVAL=${MULLE_CORES}
}


# local _parallel_maxaverage
r_convenient_max_load_average()
{
   r_get_core_count

   _parallel_maxaverage=$((RVAL * 2))
}


wait_for_available_job()
{
   log_entry "wait_for_available_job" "$@"

   local running
   local count

   while :
   do
      running=($(jobs -pr))  #  http://mywiki.wooledge.org/BashFAQ/004
      count=${#running[@]}

      if [ ${count} -le ${_parallel_maxjobs:-8} ]
      then
         log_debug "Currently only ${count} jobs run, spawn another"
         break
      fi
      log_debug "Waiting on jobs to finish (${#running[@]})"
      sleep 0.001s # 1000Hz
   done
}


wait_for_load_average()
{
   log_entry "wait_for_load_average" "$@"

   local loadavg

   while :
   do
      loadavg="`uptime | sed -n -e 's/.*average:[ ]*\([0-9]*\).*/\1/p'`"
      if [ "${loadavg:-0}" -le ${_parallel_maxaverage:-8} ]
      then
         break
      fi
      log_debug "Waiting on load average to come down"
      sleep 0.001s # 1000Hz
   done
}


#
# local _parallel_statusfile
# local _parallel_maxjobs
# local _parallel_jobs
# local _parallel_fails
#
_parallel_begin()
{
   log_entry "_parallel_begin" "$@"

   _parallel_maxjobs="$1"

   local RVAL

   _parallel_jobs=0
   _parallel_fails=0

   r_make_tmp "mulle-parallel"
   _parallel_statusfile="${RVAL}"

   if [ -z "${_parallel_maxjobs}" ]
   then
      r_get_core_count
      _parallel_maxjobs="${RVAL}"
   fi
}


_parallel_end()
{
   log_entry "_parallel_end" "$@"

   wait

   _parallel_fails="`rexekutor egrep -v '^0;' "${_parallel_statusfile}" | wc -l | awk '{ printf $1 }'`"
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "_parallel_jobs : ${_parallel_jobs}"
      log_trace2 "_parallel_fails: ${_parallel_fails}"
      log_trace2 "${_parallel_statusfile} : `cat "${_parallel_statusfile}"`"
   fi
      remove_file_if_present "${_parallel_statusfile}"

   [ -z ${_parallel_fails} ]
}


_parallel_execute()
{
   log_entry "_parallel_execute" "$@"

   wait_for_available_job "${_parallel_maxjobs}"
   _parallel_jobs=$(($_parallel_jobs + 1))

   log_debug "Runing job #${_parallel_jobs}: $*"

   (
      local rval

      exekutor "$@"
      rval=$?
      if [ $rval -ne 0 ]
      then
         log_warning "$* failed with $rval"
      fi
      redirect_append_exekutor "${_parallel_statusfile}" echo "${rval};$*"
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

   set -o noglob;  IFS="
"
   for argument in ${arguments}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"

      _parallel_execute "$@" "${argument}"
   done

   set +o noglob; IFS="${DEFAULT_IFS}"

   _parallel_end
}
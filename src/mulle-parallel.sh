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
      # Linux (absolute path for restricted environments)
      MULLE_CORES="`/usr/bin/nproc 2> /dev/null`"
      if [ -z "${MULLE_CORES}" ]
      then
         # Apple (absolute path for restricted environments)
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


# local _parallel_maxaverage
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


# just the floored load integer (i.e. 0.89 -> 0)
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


#
# figure out how much cores we can use given current system load
#
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

   # only append to status file if error
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


# intention of this is to act like a form of xargs
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


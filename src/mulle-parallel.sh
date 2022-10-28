# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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
if ! [ ${MULLE_PARALLEL_SH+x} ]
then
MULLE_PARALLEL_SH="included"

[ -z "${MULLE_FILE_SH}" ] && _fatal "mulle-file.sh must be included before mulle-parallel.sh"



# RESET
# NOCOLOR
#
#    Use "parallel" functions to run commands in parallel in a more controlled
#    manner, than just forking off commands into the background with &.
#
#    "parallel" will collect the status of the background processes and wait
#    for their completion. It will stop forking background processes, if the
#    load is too high and may limit the number of background processes to the
#    number of cores available on the system.
#
#    In its simplest form `parallel_execute` applies arguments to a command
#    just like xargs does:
#
# PRE
#    arguments="1
#    2
#    3"
#    parallel_execute "${arguments}" echo "number:"
# /PRE
#
#    For more control over parallel execution use `_parallel_begin`,
#    `_parallel_execute` and `_parallel_end`
#
# PRE
#    local _parallel_statusfile
#    local _parallel_maxjobs
#    local _parallel_jobs
#    local _parallel_fails
#
#    _parallel_begin
#    _parallel_execute remove_file_if_present "${filename}"
#    _parallel_execute remove_file_if_present "${filename2}"
#    _parallel_end || fail "failed"
# /PRE
#
#
# TITLE INTRO
# COLOR


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


#
# r_get_core_count
#
#    Try to figure out the number of cores available on this system.
#    Will set MULLE_CORES global variable. If MULLE_CORES is already set,
#    its value will be returned.
#
r_get_core_count()
{
   if ! [ ${MULLE_CORES+x} ]
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


#
# get_current_load_average
#
#    Try to figure out the current load average on this system.
#    Returns value to stdout.
#
get_current_load_average()
{
   case "${MULLE_UNAME}" in
      freebsd|darwin)
         sysctl -n vm.loadavg | sed -n -e 's/.*{[ ]*\([0-9]*\).*/\1/p'
      ;;

      mingw)
         echo "7"  # no way to know
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


#
# _parallel_begin <maxjobs>
#
#     Creates the status file for the parallel jobs and determines the number
#     to be run in parallel. Use <maxjobs> to limit this number.
#     You should define these local variable before calling _parallel_begin:
#
#     local _parallel_statusfile
#     local _parallel_maxjobs
#     local _parallel_jobs
#     local _parallel_fails
#
function _parallel_begin()
{
   log_entry "_parallel_begin" "$@"

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


_parallel_status()
{
   log_entry "_parallel_status" "$@"

   local rval="$1"; shift

   [ -z "${_parallel_statusfile}" ] && _internal_fail "_parallel_statusfile must be defined"

   # only append to status file if error
   if [ $rval -ne 0 ]
   then
      log_warning "warning: Parallel job \"$*\" failed with $rval"
      redirect_append_exekutor "${_parallel_statusfile}" printf "%s\n" "${rval};$*"
   fi
}


#
# _parallel_execute ...
#
#     Execute command line in the background. _parallel_execute blocks until a
#     job becomes available.
#
function _parallel_execute()
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


#
# _parallel_end
#
#     Waits for the parallel processes to finish. Returns 1 if one or more
#     of the jobs indicates failure.
#
function _parallel_end()
{
   log_entry "_parallel_end" "$@"

   wait

   _parallel_fails="`rexekutor wc -l "${_parallel_statusfile}" | awk '{ printf $1 }'`"

   log_setting "_parallel_jobs : ${_parallel_jobs}"
   log_setting "_parallel_fails: ${_parallel_fails}"
   log_setting "${_parallel_statusfile} : `cat "${_parallel_statusfile}"`"

   exekutor rm "${_parallel_statusfile}"

   if [ "${_parallel_fails:-1}" -ne 0 ]
   then
      log_warning "warning: ${_parallel_fails} parallel jobs failed"
      return 1
   fi

   return 0
}



#
# parallel_execute <arguments> ...
#
#    Parallel receives an arguments string, which contains the arguments
#    separated by linefeeds. This arguments are then fed to the remainder
#    of the command line as the last argument and executed in the background.
#    parallel_execute then waits for the completion of all background tasks.
#
#    The return value is zero, of all executed commands succeeded.
#
function parallel_execute()
{
   log_entry "parallel_execute" "$@"

   local arguments="$1"; shift

   local _parallel_statusfile
   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails

   [ $# -eq 0 ] && _internal_fail "missing commandline"

   _parallel_begin

   local argument

   shell_disable_glob

   .foreachline argument in ${arguments}
   .do
      _parallel_execute "$@" "${argument}"
   .done

   shell_enable_glob

   _parallel_end
}

fi
:

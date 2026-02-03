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
MULLE_PARALLEL_SH='included'

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
#    For more control over parallel execution use `__parallel_begin`,
#    `__parallel_execute` and `__parallel_end`
#
# PRE
#    local _parallel_statusfile
#    local _parallel_maxjobs
#    local _parallel_jobs
#    local _parallel_fails
#
#    __parallel_begin
#    __parallel_execute remove_file_if_present "${filename}"
#    __parallel_execute remove_file_if_present "${filename2}"
#    __parallel_end || fail "failed"
# /PRE
#
#
# TITLE INTRO
# COLOR


#
# very_short_sleep <us>
#
#    Does a microsecond sleep
#
very_short_sleep()
{
   local us="$1"

   us="${us:0:6}"

   local zeroes="000000"

   us="0.${zeroes:${#us}}${us}"
   us="${us%%0}"
   case "${MULLE_UNAME}" in 
      darwin|*bsd|dragonfly)
      ;;

      *)
         us="${us}s"
      ;;
   esac
   LC_ALL=C sleep "${us}"
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
      MULLE_CORES="`PATH="$PATH:/usr/sbin:/sbin" nproc 2> /dev/null`"
      if [ -z "${MULLE_CORES}" ]
      then
         # Apple (absolute path for restricted environments)
         MULLE_CORES="`PATH="$PATH:/usr/sbin:/sbin" sysctl -n hw.ncpu 2> /dev/null`"
      fi

      if [ -z "${MULLE_CORES}" ]
      then
         MULLE_CORES=4
         log_verbose "Unknown core count, setting it to 4 as default"
         RVAL=${MULLE_CORES}
         return 2
      fi
   fi

   RVAL=${MULLE_CORES}
   return 0
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
   local us

   us=1000 # start with 1 ms

   while :
   do
      running=($(jobs -pr))  #  http://mywiki.wooledge.org/BashFAQ/004
      count=${#running[@]}

      if [ ${count} -le ${maxjobs} ]
      then
         log_debug "Currently only ${count} jobs run, spawn another"
         break
      fi

      log_debug "Waiting $us us on jobs to finish (${#running[@]})"

      very_short_sleep $us
      us=$((us + us))
      if [ ${us} -gt 500000 ]
      then
         us=500000
      fi
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
      'freebsd'|'darwin')
         sysctl -n vm.loadavg | sed -n -e 's/.*{[ ]*\([0-9]*\).*/\1/p'
      ;;

      'mingw'|'msys')
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
# __parallel_begin <maxjobs>
#
#     Creates the status file for the parallel jobs and determines the number
#     to be run in parallel. Use <maxjobs> to limit this number.
#     You should define these local variable before calling __parallel_begin:
#
#     local _parallel_maxjobs
#     local _parallel_jobs
#     local _parallel_fails
#     local _parallel_statusfile
#
function __parallel_begin()
{
   log_entry "__parallel_begin" "$@"

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


#
#  local _parallel_statusfile
#
__parallel_status()
{
   log_entry "__parallel_status" "$@"

   local rval="$1"; shift

   [ -z "${_parallel_statusfile}" ] && _internal_fail "_parallel_statusfile must be defined"

   # only append to status file if error
   if [ $rval -ne 0 ]
   then
      log_warning "warning: Parallel job \"$*\" failed with $rval in \"$PWD\""
      redirect_append_exekutor "${_parallel_statusfile}" printf "%s\n" "${rval};$*"
   fi
}


#
# __parallel_execute ...
#
#     Execute command line in the background. __parallel_execute blocks until a
#     job becomes available.
#
#  local _parallel_statusfile
#  local _parallel_maxjobs
#  local _parallel_jobs
#
function __parallel_execute()
{
   log_entry "__parallel_execute" "$@"

   wait_for_available_job "${_parallel_maxjobs}"
   _parallel_jobs=$(($_parallel_jobs + 1))

   log_debug "Running job #${_parallel_jobs}: $*"

   (
      local rval

      ( exekutor "$@" ) # run in subshell to capture exit code
      __parallel_status $? "$@"
   ) &
}


#
# __parallel_end
#
#     Waits for the parallel processes to finish. Returns 1 if one or more
#     of the jobs indicates failure.
#
#  local _parallel_statusfile
#  local _parallel_jobs
#  local _parallel_fails
#
function __parallel_end()
{
   log_entry "__parallel_end" "$@"

   wait

   # use exekutor because the file ain't there in dry mode
   _parallel_fails="`exekutor wc -l "${_parallel_statusfile}" | awk '{ printf $1 }'`"

   log_setting "_parallel_jobs : ${_parallel_jobs}"
   log_setting "_parallel_fails: ${_parallel_fails}"
   log_setting "${_parallel_statusfile} : `exekutor cat "${_parallel_statusfile}"`"

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

   __parallel_begin

   local argument

   shell_disable_glob

   .foreachline argument in ${arguments}
   .do
      __parallel_execute "$@" "${argument}"
   .done

   shell_enable_glob

   __parallel_end
}

fi
:

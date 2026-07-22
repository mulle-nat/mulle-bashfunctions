# shellcheck shell=bash
#
#   Copyright (c) 2025 Nat! - Mulle kybernetiK
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
if ! [ ${MULLE_LOCK_SH+x} ]
then
MULLE_LOCK_SH='included'


function lock::__pidfile_path()
{
   [ $# -eq 1 ] || _internal_fail "API error"

   RVAL="${1}/pid"
}


function lock::__current_pid()
{
   RVAL="${MULLE_EXECUTABLE_PID:-${BASHPID:-$$}}"
}


function lock::__write_pidfile()
{
   [ $# -eq 1 ] || _internal_fail "API error"

   local lockdir="$1"
   local pidfile
   local pid

   lock::__pidfile_path "${lockdir}"
   pidfile="${RVAL}"
   lock::__current_pid
   pid="${RVAL}"

   if ! printf "%s\n" "${pid}" > "${pidfile}"
   then
      rmdir "${lockdir}" 2>/dev/null || :
      _internal_fail "Failed to write lock owner pid to \"${pidfile}\""
   fi
}


function lock::__read_pidfile()
{
   [ $# -eq 1 ] || _internal_fail "API error"

   local lockdir="$1"
   local pidfile

   RVAL=""

   lock::__pidfile_path "${lockdir}"
   pidfile="${RVAL}"

   if ! [ -f "${pidfile}" ]
   then
      return 1
   fi

   IFS= read -r RVAL < "${pidfile}" || RVAL=""
   [ ! -z "${RVAL}" ]
}


function lock::__pid_is_alive()
{
   [ $# -eq 1 ] || _internal_fail "API error"

   case "${1}" in
      ''|*[!0-9]*)
         return 1
      ;;
   esac

   [ "${1}" -eq 0 ] 2>/dev/null && return 1

   kill -0 "${1}" 2>/dev/null
}


function lock::__cleanup_lockdir()
{
   [ $# -eq 1 ] || _internal_fail "API error"

   local lockdir="$1"
   local pidfile

   lock::__pidfile_path "${lockdir}"
   pidfile="${RVAL}"

   rm -f "${pidfile}" 2>/dev/null || :
   rmdir "${lockdir}" 2>/dev/null || :
}


# lock::acquire <lockdir> [stale_seconds]
#
#    Acquire a directory-based lock. mkdir is atomic, so this is race-free.
#    Waits if another process holds the lock. A lock is considered stale if the
#    timeout is reached or if the recorded owner pid is no longer alive.
#
#    Returns:
#       0 : locked immediately
#       1 : locked after waiting
#       3 : locked by breaking a stale lock
#
function lock::acquire()
{
   log_entry "lock::acquire" "$@"

   local lockdir="$1"
   local stale_seconds="${2:-30}"

   local current_time
   local creation_time
   local elapsed
   local stale_lockdir
   local age
   local owner_pid
   local owner_state
   local current_pid

   lock::__current_pid
   current_pid="${RVAL}"

   if mkdir "${lockdir}" 2>/dev/null
   then
     lock::__write_pidfile "${lockdir}"
     log_debug "${current_pid} acquired lock \"${lockdir}\""
     return 0
   fi

   log_fluff "${current_pid} waiting for lock \"${lockdir}\""

   while :
   do
     if mkdir "${lockdir}" 2>/dev/null
     then
        lock::__write_pidfile "${lockdir}"
        log_verbose "${current_pid} acquired lock \"${lockdir}\" after waiting"
        return 1
     fi

      creation_time="$(modification_timestamp "${lockdir}")"
      [ -z "${creation_time}" ] && creation_time="$(date +%s)"

      current_time="$(date +%s)"
      elapsed=$((current_time - creation_time))

      owner_pid=""
      owner_state='missing'
      if lock::__read_pidfile "${lockdir}"
      then
         owner_pid="${RVAL}"
         if [ "${owner_pid}" = "${current_pid}" ]
         then
            fail "Recursive lock attempt on \"${lockdir}\" by pid ${current_pid}"
         fi

         if lock::__pid_is_alive "${owner_pid}"
         then
            owner_state='alive'
         else
            owner_state='dead'
         fi
      fi

      if [ "${owner_state}" = 'dead' ]
      then
         stale_lockdir="${lockdir}.stale.${current_pid}.${current_time}"

         if mv "${lockdir}" "${stale_lockdir}" 2>/dev/null
         then
            if mkdir "${lockdir}" 2>/dev/null
            then
               lock::__write_pidfile "${lockdir}"
               lock::__cleanup_lockdir "${stale_lockdir}"
               log_warning "${current_pid} broke dead-owner lock \"${lockdir}\" (pid ${owner_pid})"
               return 3
            fi

            lock::__cleanup_lockdir "${stale_lockdir}"
            sleep 1
            continue
         fi
      fi

      if [ "${elapsed}" -ge "${stale_seconds}" ]
      then
         stale_lockdir="${lockdir}.stale.${current_pid}.${current_time}"

         if ! mv "${lockdir}" "${stale_lockdir}" 2>/dev/null
         then
            sleep 1
            continue
         fi

         if ! mkdir "${lockdir}" 2>/dev/null
         then
            lock::__cleanup_lockdir "${stale_lockdir}"
            sleep 1
            continue
         fi

         lock::__write_pidfile "${lockdir}"

         creation_time="$(modification_timestamp "${stale_lockdir}")"
         [ -z "${creation_time}" ] && creation_time="${current_time}"
         current_time="$(date +%s)"
         age=$((current_time - creation_time))
         lock::__cleanup_lockdir "${stale_lockdir}"

         if [ "${age}" -ge "${stale_seconds}" ]
         then
            case "${owner_state}" in
               alive)
                  log_warning "${current_pid} broke stale lock \"${lockdir}\" (${age}s old, pid ${owner_pid} still alive)"
               ;;
               dead)
                  log_warning "${current_pid} broke stale lock \"${lockdir}\" (${age}s old, pid ${owner_pid} not alive)"
               ;;
               *)
                  log_warning "${current_pid} broke stale lock \"${lockdir}\" (${age}s old)"
               ;;
            esac
            return 3
         fi

         log_fluff "${current_pid} lock wasn't stale (${age}s), retrying"
         lock::__cleanup_lockdir "${lockdir}"
      fi

      if [ "${owner_state}" = 'alive' ]
      then
         log_fluff "${current_pid} waiting for lock \"${lockdir}\" owned by pid ${owner_pid} (${elapsed}s elapsed)"
      else
         log_fluff "${current_pid} waiting for lock \"${lockdir}\" (${elapsed}s elapsed)"
      fi
      sleep 1
   done
}


# lock::release <lockdir>
#
#    Release a previously acquired directory lock.
#
function lock::release()
{
   log_entry "lock::release" "$@"

   local lockdir="$1"

   lock::__pidfile_path "${lockdir}"
   rm -f "${RVAL}" 2>/dev/null || :
   rmdir "${lockdir}" 2>/dev/null || log_debug "Lock \"${lockdir}\" already released"
}


# lock::exekutor <lockdir> [stale_seconds] -- <command> [args...]
#
#    Acquire a lock, run a command via exekutor, capture its return code, then
#    release the lock again and return the captured code.
#
function lock::exekutor()
{
   log_entry "lock::exekutor" "$@"

   [ $# -ge 2 ] || _internal_fail "API error"

   local lockdir="$1"
   local stale_seconds='30'
   local rc

   shift

   case "${1}" in
      ''|*[!0-9]*)
      ;;
      *)
         stale_seconds="$1"
         shift
      ;;
   esac

   [ $# -ne 0 ] || fail "Usage: lock::exekutor <lockdir> [stale_seconds] -- <command> [args...]"
   [ "$1" = '--' ] || fail "Usage: lock::exekutor <lockdir> [stale_seconds] -- <command> [args...]"

   shift

   [ $# -ne 0 ] || fail "Usage: lock::exekutor <lockdir> [stale_seconds] -- <command> [args...]"

   lock::acquire "${lockdir}" "${stale_seconds}" || return $?

   exekutor "$@"
   rc=$?

   lock::release "${lockdir}"
   return ${rc}
}


fi

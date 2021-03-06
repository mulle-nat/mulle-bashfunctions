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
[ ! -z "${MULLE_OPTIONS_SH}" -a "${MULLE_WARN_DOUBLE_INCLUSION}" = 'YES' ] && \
   echo "double inclusion of mulle-options.sh" >&2

[ -z "${MULLE_LOGGING_SH}" ] && echo "mulle-logging.sh must be included before mulle-options.sh" 2>&1 && exit 1

MULLE_OPTIONS_SH="included"


## core option parsing
# not used by mulle-bootstrap itself at the moment

#
# variables called flag. because they are indirectly set by flags
#
options_dump_env()
{
   log_trace "ARGS:${C_TRACE2} ${MULLE_ARGUMENTS}"
   log_trace "PWD :${C_TRACE2} `pwd -P 2> /dev/null`"
   log_trace "ENV :${C_TRACE2} `env | sort`"
   log_trace "LS  :${C_TRACE2} `ls -a1F`"
}


options_setup_trace()
{
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
         MULLE_FLAG_VERBOSE_BUILD='YES'


         if [ "${MULLE_TRACE_POSTPONE}" != 'YES' ]
         then
            log_trace "1848 trace (set -x) started"
            set -x
            PS4="+ ${ps4string} + "
         fi
      ;;
   esac

   if [ "${MULLE_FLAG_LOG_ENVIRONMENT}" = YES ]
   then
      options_dump_env
   fi
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
      log_warning "${MULLE_EXECUTABLE_FAIL_PREFIX}: $1 after -t invalidates -t"
}


#
# local MULLE_FLAG_EXEKUTOR_DRY_RUN
# local MULLE_FLAG_LOG_DEBUG
# local MULLE_FLAG_LOG_EXEKUTOR
# local MULLE_FLAG_LOG_TERSE
# local MULLE_FLAG_LOG_ENVIRONMENT
# local MULLE_TRACE
#
options_technical_flags()
{
   case "$1" in
      -n|--dry-run)
         MULLE_FLAG_EXEKUTOR_DRY_RUN='YES'
      ;;

      -ld|--log-debug)
         MULLE_FLAG_LOG_DEBUG='YES'
      ;;

      -le|--log-environment)
         MULLE_FLAG_LOG_ENVIRONMENT='YES'
      ;;

      -ls|--log-settings)
         MULLE_FLAG_LOG_SETTINGS='YES'
      ;;

      -lx|--log-exekutor|--log-execution)
         MULLE_FLAG_LOG_EXEKUTOR='YES'
      ;;

      -l-)
         MULLE_FLAG_LOG_DEBUG=
         MULLE_FLAG_LOG_ENVIRONMENT=
         MULLE_FLAG_LOG_EXEKUTOR=
         MULLE_FLAG_LOG_SETTINGS=
      ;;

      -t|--trace)
         MULLE_TRACE='1848'
         ps4string='${BASH_SOURCE[0]##*/}:${LINENO}'
      ;;

      -tfpwd|--trace-full-pwd)
         before_trace_fail "$1"
         ps4string='${BASH_SOURCE[0]##*/}:${LINENO} \"\w\"'
      ;;

      -tp|--trace-profile)
         before_trace_fail "$1"

         case "${MULLE_UNAME}" in
            '')
               internal_fail 'MULLE_UNAME must be set by now'
            ;;
            linux)
               ps4string='$(date "+%s.%N (${BASH_SOURCE[0]##*/}:${LINENO})")'
            ;;
            *)
               ps4string='$(date "+%s (${BASH_SOURCE[0]##*/}:${LINENO})")'
            ;;
         esac
      ;;

      -tpo|--trace-postpone)
         before_trace_fail "$1"
         MULLE_TRACE_POSTPONE='YES'
      ;;

      -tpwd|--trace-pwd)
         before_trace_fail "$1"
         ps4string='${BASH_SOURCE[0]##*/}:${LINENO} \".../\W\"'
      ;;

      -tx|--trace-immediately)
         set -x
      ;;


      -t-)
         MULLE_TRACE=
         set +x
      ;;

      -s|--silent)
         MULLE_FLAG_LOG_TERSE='YES'
      ;;

      -v-|--no-verbose)
         MULLE_FLAG_LOG_TERSE=
      ;;

      -v|--verbose)
         after_trace_warning "$1"

         MULLE_TRACE='VERBOSE'
      ;;

      -vv|--very-verbose)
         after_trace_warning "$1"

         MULLE_TRACE='FLUFF'
      ;;

      -vvv|--very-very-verbose)
         after_trace_warning "$1"

         MULLE_TRACE='TRACE'
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

   #
   # collect technical options so interested parties can forward them to
   # other mulle tools. In tools they are called flags, and this will be
   # renamed too, eventually. If you don't want to forward the technical
   # flags to other mulle-bashfunction programs - sometimes- use
   # --clear-flags after all the other flags.
   #
   if [ -z "${MULLE_TECHNICAL_FLAGS}" ]
   then
      MULLE_TECHNICAL_FLAGS="$1"
   else
      MULLE_TECHNICAL_FLAGS="${MULLE_TECHNICAL_FLAGS} $1"
   fi

   return 0
}


## option parsing common


options_unpostpone_trace()
{
   if [ ! -z "${MULLE_TRACE_POSTPONE}" -a "${MULLE_TRACE}" = '1848' ]
   then
      set -x
      PS4="+ ${ps4string} + "
   fi
}


#
# this has very limited use, i only use it in some tests
#
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

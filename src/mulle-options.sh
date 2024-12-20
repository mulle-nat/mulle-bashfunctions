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
if ! [ ${MULLE_OPTIONS_SH+x} ]
then
MULLE_OPTIONS_SH='included'

[ -z "${MULLE_LOGGING_SH}" ] && _fatal "mulle-logging.sh must be included before mulle-options.sh"


# RESET
# NOCOLOR
#
#    Use "options" function `options_technical_flags` to parse and set common
#    mulle-bashfunctions flags like -v or -ld. Then use `options_setup_trace`
#    to start tracing, if desired by the user. So your mulle-bashfunctions
#    script should contain some code like this:
#
# PRE
#    while [ $# -ne 0 ]
#    do
#       if options_technical_flags "$1"
#       then
#          shift
#          continue
#       fi
#
#       <other argument handling>
#
#       break
#   done
#
#   options_setup_trace "${MULLE_TRACE:-}" && set -x
# /PRE
#
#    Use the global variable MULLE_TECHNICAL_FLAGS to forward these flags to other
#    mulle-bashfunctions scripts. That way you seamlessly use verbose mode over
#    multiple scripts.
#
# TITLE INTRO
# COLOR


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

#
# options_setup_trace <mode>
#
#   Call this function after all the command-line flags have been parsed.
#   The return status indicates if shell tracing should be turned on.
#   Failure to do so, will lose you the tracing support.
#
function options_setup_trace()
{
   local mode="$1"

   local rc

   if [ "${MULLE_FLAG_LOG_ENVIRONMENT:-}" = YES ]
   then
      options_dump_env
   fi

   rc=2
   case "${mode}" in
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

         if [ "${MULLE_TRACE_POSTPONE:-}" != 'YES' ]
         then
            # log_trace "1848 trace (set -x) started"
            # set -x # lol fcking zsh turns this off at function end
            #        # unsetopt localoptions does not help
            PS4="+ ${MULLE_TRACE_PS4} + "
         fi
         rc=0
      ;;
   esac

   log_set_trace_level

   return $rc
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

   if [ ! -z "${MULLE_TRACE:-}" ]
   then
      cat <<EOF
   -ld${S}${S}${DELIMITER}additional debug output
   -le${S}${S}${DELIMITER}additional environment debug output
   -lt${S}${S}${DELIMITER}trace through bash code
   -lx${S}${S}${DELIMITER}external command execution log output
EOF
   fi
}


#
# options_technical_flags_usage <delimiter> <align>
#
#    Print out help text for the flags understood by mulle-bashfunctions.
#    Use <delimiter> to separate text the flag string from the description
#    text. Set <align> to NO to remove alignment spaces.
#
function options_technical_flags_usage()
{
   _options_technical_flags_usage "$@" | sort
}


before_trace_fail()
{
   [ "${MULLE_TRACE:-}" = '1848' ] || \
      fail "option \"$1\" must be specified after -lt"
}


after_trace_warning()
{
   [ "${MULLE_TRACE:-}" = '1848' ] && \
      log_warning "warning: ${MULLE_EXECUTABLE_FAIL_PREFIX}: $1 after -lt invalidates -lt"
}


#
# options_technical_flags <flag>
#
#    Parses common flags like --dry-run (-n), --verbose (-v) and so on.
#    The following global variables will be set:
#       MULLE_FLAG_EXEKUTOR_DRY_RUN
#       MULLE_FLAG_LOG_DEBUG
#       MULLE_FLAG_LOG_ERROR
#       MULLE_FLAG_LOG_EXEKUTOR
#       MULLE_FLAG_LOG_TERSE
#       MULLE_FLAG_LOG_ENVIRONMENT
#       MULLE_TRACE
#       MULLE_TECHNICAL_FLAGS
#
function options_technical_flags()
{
   local flag="$1"

   case "${flag}" in
# single char
      -n|--dry-run)
         MULLE_FLAG_EXEKUTOR_DRY_RUN='YES'
      ;;

      -s|--silent)
         MULLE_FLAG_LOG_TERSE='YES'
      ;;

      --silent-but-warn)
         MULLE_FLAG_LOG_TERSE='WARN'
      ;;

      -v|--verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='VERBOSE'
      ;;

      -V)
         after_trace_warning "${flag}"

         MULLE_TRACE='VERBOSE'
         return # don't propagate
      ;;

# multichar
      -ld|--log-debug)
         MULLE_FLAG_LOG_DEBUG='YES'
         # propagate
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
         # propagate
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
         # propagate
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
         # propagate
      ;;

      -lx*)
         # doesnt mean anything to mulle-bashfunctions but propagate
         # used by mulle-sourcetree
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

      # renamed to -lt, because obscuring -t is kinda harsh
      # and i don't need it so often
      -lt|--trace)
         MULLE_TRACE='1848'
         if [ ${ZSH_VERSION+x} ]
         then
            MULLE_TRACE_PS4='%1x:%I' # TODO: fix for zsh
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         # propagate
      ;;

      -lT)
         MULLE_TRACE='1848'
         if [ ${ZSH_VERSION+x} ]
         then
            MULLE_TRACE_PS4='%1x:%I'
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         return # don't propagate
      ;;

      -tfpwd|--trace-full-pwd)
         before_trace_fail "${flag}"
         if [ ${ZSH_VERSION+x} ]
         then
            MULLE_TRACE_PS4='%1x:%I \"\w\"'
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO} \"\w\"'
         fi
      ;;

      -tp|--trace-profile)
#         if [ ${ZSH_VERSION+x} ]
#         then
#            zmodload "zsh/zprof"
#            # can't trap global exit from within function :(
#            MULLE_RUN_ZPROF_ON_EXIT='YES'
#         else
#            before_trace_fail "${flag}"
   
            case "${MULLE_UNAME}" in
               '')
                  _internal_fail 'MULLE_UNAME must be set by now'
               ;;
               linux)
                  if [ ${ZSH_VERSION+x} ]
                  then
                     MULLE_TRACE_PS4='$(date "+%s.%N (%1x:%I)")'
                  else
                     MULLE_TRACE_PS4='$(date "+%s.%N (${BASH_SOURCE[0]##*/}:${LINENO})")'
                  fi
               ;;
               *)
                  if [ ${ZSH_VERSION+x} ]
                  then
                     MULLE_TRACE_PS4='$(date "+%s (%1x:%I)")'
                  else
                     MULLE_TRACE_PS4='$(date "+%s (${BASH_SOURCE[0]##*/}:${LINENO})")'
                  fi
               ;;
            esac
#         fi
         return # don't propagate
      ;;

      -tpwd|--trace-pwd)
         before_trace_fail "${flag}"
         if [ ${ZSH_VERSION+x} ]
         then
            MULLE_TRACE_PS4='%1x:%I \".../\W\"'
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO} \".../\W\"'
         fi
      ;;

      -tx|--trace-immediately)
         set -x
      ;;

      -t-)
         MULLE_TRACE=
         set +x
      ;;


      -T*T)
         MULLE_TRACE='1848'
         if [ ${ZSH_VERSION+x} ]
         then
            MULLE_TRACE_PS4='%1x:%I'
         else
            MULLE_TRACE_PS4='${BASH_SOURCE[0]##*/}:${LINENO}'
         fi
         flag="${flag%T}"
      ;;

      -v-|--no-verbose)
         MULLE_FLAG_LOG_TERSE=
      ;;

      -vv|--very-verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='FLUFF'
      ;;

      -vvv|--very-very-verbose)
         after_trace_warning "${flag}"

         MULLE_TRACE='TRACE'
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

      --mulle-clear-flags)
         MULLE_TECHNICAL_FLAGS=''
         return 0
      ;;

      --mulle-list-technical-flags)
         echo "\
--dry-run
--mulle-clear-flags
--mulle-no-errors
--mulle-no-colors
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

      --mulle-no-color|--mulle-no-colors)
         MULLE_NO_COLOR='YES'
         logging_deinitialize_color
      ;;

      --mulle-no-error|--mulle-no-errors)
         MULLE_FLAG_LOG_ERROR='NO'
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
   if [ ${MULLE_TECHNICAL_FLAGS+x} ]
   then
      MULLE_TECHNICAL_FLAGS="${MULLE_TECHNICAL_FLAGS} ${flag}"
   else
      MULLE_TECHNICAL_FLAGS="${flag}"
   fi

   return 0
}


#
# this has very limited use, i only use it in some tests
# caller should do set +x if 0
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

   options_setup_trace "${MULLE_TRACE:-}" && set -x
}

fi
:

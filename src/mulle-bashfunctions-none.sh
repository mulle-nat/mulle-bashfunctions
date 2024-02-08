#
#   Copyright (c) 2015-2021 Nat! - Mulle kybernetiK
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
#

if ! [ ${MULLE_BASHGLOBAL_SH+x} ]
then
   MULLE_BASHGLOBAL_SH='included'

   DEFAULT_IFS="${IFS}" # as early as possible

   if [ ${ZSH_VERSION+x} ]
   then
     setopt sh_word_split
     setopt POSIX_ARGZERO
     set -o GLOB_SUBST        # neede for [[ $i == $pattern ]]
   fi

   if [ -z "${MULLE_EXECUTABLE:-}" ]
   then
      MULLE_EXECUTABLE="${BASH_SOURCE[0]:-${(%):-%x}}"
      case "${MULLE_EXECUTABLE##*/}" in 
         mulle-bash*.sh)
            MULLE_EXECUTABLE="$0"
         ;;
      esac
   fi

   case "${MULLE_EXECUTABLE##*/}" in 
      mulle-bash*.sh)
         echo "MULLE_EXECUTABLE fail" >&2
         exit 1
      ;;
   esac


   if [ -z "${MULLE_EXECUTABLE_NAME:-}" ]
   then
      MULLE_EXECUTABLE_NAME="${MULLE_EXECUTABLE##*/}"
   fi

   if [ -z "${MULLE_USER_PWD:-}" ]
   then
      MULLE_USER_PWD="${PWD}"
      export MULLE_USER_PWD
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME:-${MULLE_EXECUTABLE_NAME}}"

   MULLE_EXECUTABLE_PWD="${PWD}"
   MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE_NAME}"
   MULLE_EXECUTABLE_PID="$$"

   if [ -z "${MULLE_UNAME:-}" ]
   then
      case "${BASH_VERSION:-}" in
         [0123]*)
            MULLE_UNAME="`uname | tr '[:upper:]' '[:lower:]'`"
         ;;

         *)
            MULLE_UNAME="${_MULLE_UNAME:-`uname`}"
            if [ ${ZSH_VERSION+x} ]
            then
               MULLE_UNAME="${MULLE_UNAME:l}"
            else
               MULLE_UNAME="${MULLE_UNAME,,}"
            fi
         ;;
      esac
      
      MULLE_UNAME="${MULLE_UNAME%%_*}"
      MULLE_UNAME="${MULLE_UNAME%[36][24]}" # remove 32 64 (hax)

      case "${MULLE_UNAME}" in 
         linux)
            MULLE_UNAME="android"
            if [ -r /proc/sys/kernel/osrelease ]
            then
               read -r MULLE_UNAME < /proc/sys/kernel/osrelease
               case "${MULLE_UNAME}" in
                  *-[Mm]icrosoft-*)
                     MULLE_UNAME="windows" # wsl2, this is super slow on NTFS
                  ;;

                  *-[Mm]icrosoft)
                     MULLE_UNAME="windows" # wsl1
                  ;;

                  *-android-*|*-android)
                     MULLE_UNAME="android"
                  ;;

                  *)
                     MULLE_UNAME="linux"
                  ;;
               esac
            fi
         ;;

         msys|cygwin)
            MULLE_UNAME='msys'
         ;;
      esac
   fi

   if [ "${MULLE_UNAME}" = "windows" ]
   then
      MULLE_EXE_EXTENSION=".exe"
   fi

   if [ -z "${MULLE_HOSTNAME:-}" ]
   then
      case "${MULLE_UNAME}" in
         'mingw'|'msys'|'sunos')
            MULLE_HOSTNAME="`hostname`"
         ;;

         *)
            MULLE_HOSTNAME="`hostname -s`"
         ;;
      esac

      case "${MULLE_HOSTNAME}" in
         \.*)
            MULLE_HOSTNAME="_${MULLE_HOSTNAME}"
         ;;
      esac
   fi

   if [ -z "${MULLE_USERNAME:-}" ]
   then
      MULLE_USERNAME="${MULLE_USERNAME:-${USERNAME}}" # mingw
      MULLE_USERNAME="${MULLE_USERNAME:-${USER}}"
      MULLE_USERNAME="${MULLE_USERNAME:-${LOGNAME}}"
      MULLE_USERNAME="${MULLE_USERNAME:-`id -nu 2> /dev/null`}"
      MULLE_USERNAME="${MULLE_USERNAME:-cptnemo}"
   fi
fi


if ! [ ${MULLE_BASHLOADER_SH+x} ]
then
   MULLE_BASHLOADER_SH='included'

   r_uppercase()
   {
      case "${BASH_VERSION:-}" in
         [0123]*)
            RVAL="`printf "%s" "$1" | tr '[:lower:]' '[:upper:]'`"
         ;;

         *)
            if [ ${ZSH_VERSION+x} ]
            then
               RVAL="${1:u}"
            else
               RVAL="${1^^}"
            fi
         ;;
      esac
   }


   r_include_path()
   {
      local executable="$1"
      local filename="$2"
      local libexec_define="$3"

      local value

      if [ ${ZSH_VERSION+x} ]
      then
         value="${(P)libexec_define}"
      else
         value="${!libexec_define}"
      fi

      if [ -z "${value}" ]
      then
         value="`"${executable}" libexec-dir`" || fail "Could not execute ${executable} libexec-dir successfully ($PATH)"
         printf -v "${libexec_define}" "%s" "${value}" 
         eval export "${libexec_define}"
      fi

      RVAL="${value}/${filename}"
   }



   include_executable_library()
   {
      local includeguard="$4"

      local value

      if [ ${ZSH_VERSION+x} ]
      then
         value="${(P)includeguard}"
      else
         value="${!includeguard}"
      fi

      if [ ! -z "${value}" ]
      then
         return
      fi

      r_include_path "$@"

       . "${RVAL}" || exit 1

      printf -v "${includeguard}" 'YES'
   }

   __parse_include_specifier()
   {
      local s="$1"
      local default_namespace="${2:-mulle}"  # default namespace (mulle)

      local name

      name="${s##*::}"

      local upper_name

      r_identifier "${name}"
      r_uppercase "${RVAL}"
      upper_name="${RVAL}"

      if [ "${name}" = "${s}" ]
      then
         if [ "${default_namespace}" = "mulle" ]
         then
            _executable="mulle-bashfunctions"
            _filename="mulle-${name}.sh"
            _libexecdir="MULLE_BASHFUNCTIONS_LIBEXEC_DIR"
            _includeguard="MULLE_${upper_name}_SH"
            return 0
         fi

         r_identifier "${default_namespace}"
         upper_default_namespace="${RVAL}"

         _executable="${default_namespace}-bashfunctions"
         _filename="${default_namespace}-${name}.sh"
         _libexecdir="${upper_default_namespace}_BASHFUNCTIONS_LIBEXEC_DIR"
         _includeguard="${upper_default_namespace}_${upper_name}_SH"
         return 0
      fi

      local tool

      tool="${s%::*}"

      local namespace

      case "${tool}" in
         *-*)
            namespace="${tool%%-*}"
            tool="${tool#*-}"
         ;;

         *)
            namespace="${default_namespace}"
         ;;
      esac

      r_concat "${namespace}" "${tool}" "-"
      tool="${RVAL}"

      local upper_tool

      r_identifier "${tool}"
      r_uppercase "${RVAL}"
      upper_tool="${RVAL}"

      _executable="${tool}"
      _filename="${tool}-${name}.sh"
      _libexecdir="${upper_tool}_LIBEXEC_DIR"
      _includeguard="${upper_tool}_${upper_name}_SH"
   }


   include()
   {

      local _executable
      local _filename
      local _libexecdir
      local _includeguard

      __parse_include_specifier "$@"

      include_executable_library "${_executable}" \
                                 "${_filename}" \
                                 "${_libexecdir}" \
                                 "${_includeguard}"
   }


   __bashfunctions_loader()
   {
      if [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" -a ! -z "$0" ]
      then
         local tmp

         tmp="${0%/*}"
         if [  -f "${tmp}/mulle-bashfunctions.sh" ]
         then
            MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${tmp}"
         fi
      fi

      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] \
         && echo "MULLE_BASHFUNCTIONS_LIBEXEC_DIR not set" >&2 \
         && exit 1
      :
   }

   __bashfunctions_loader || exit 1
fi
if ! [ ${MULLE_COMPATIBILITY_SH+x} ]
then
MULLE_COMPATIBILITY_SH='included'


function shell_enable_pipefail()
{
   set -o pipefail
}


function shell_disable_pipefail()
{
   set +o pipefail
}


function shell_is_pipefail_enabled()
{
   case "$-" in
      *f*)
         return 1
      ;;
   esac
   return 0
}


function shell_enable_extglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt kshglob
      setopt bareglobqual
   else
      shopt -s extglob
   fi
}


function shell_disable_extglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt bareglobqual
      unsetopt kshglob
   else
      shopt -u extglob
   fi
}


function shell_is_extglob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
   then
      [[ -o kshglob ]]
      return $?
   fi

   shopt -q extglob
}


function shell_enable_nullglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt nullglob
   else
      shopt -s nullglob
   fi
}


function shell_disable_nullglob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt nullglob
   else
      shopt -u nullglob
   fi
}


function shell_is_nullglob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
   then
      [[ -o nullglob ]]
      return $?
   fi
   shopt -q nullglob
}


function shell_enable_glob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      unsetopt noglob
   else
      set +f
   fi
}


function shell_disable_glob()
{
   if [ ${ZSH_VERSION+x} ]
   then
      setopt noglob
   else
      set -f
   fi
}


function shell_is_glob_enabled()
{
   if [ ${ZSH_VERSION+x} ]
   then
      if [[ -o noglob ]]
      then
         return 1
      fi
      return 0
   fi

   case "$-" in
      *f*)
         return 1
      ;;
   esac
   return 0
}


function shell_is_function()
{
   if [ ${ZSH_VERSION+x} ]
   then
      case "`type "$1" `" in
         *function*)
            return 0
         ;;
      esac
      return 1
   fi

   [ "`type -t "$1"`" = "function" ]
   return $?
}


function shell_is_builtin_command()
{
   if [ ${ZSH_VERSION+x} ]
   then
      case "`LC_C=C whence -w "$1" `" in
         *:*builtin)
            return 0
         ;;
      esac
      return 1
   fi

   [ "`type -t "$1"`" = "builtin" ]
   return $?
}


function r_shell_indirect_expand()
{
   local key="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      RVAL="${(P)key}"
   else
      RVAL="${!key}"
   fi
}

function shell_is_variable_defined()
{
   local key="$1"

   if [ ${ZSH_VERSION+x} ]
   then
      [[ -n ${(P)key} ]]
      return $?
   fi
   [ "${!key}" ]
}


unalias -a

if [ ${ZSH_VERSION+x} ]
then
   setopt aliases

   alias .for="setopt noglob; for"
   alias .foreachline="setopt noglob; IFS=$'\n'; for"
   alias .foreachword="setopt noglob; IFS=' '$'\t'$'\n'; for"
   alias .foreachitem="setopt noglob; IFS=','; for"
   alias .foreachpath="setopt noglob; IFS=':'; for"
   alias .foreachpathcomponent="set -f; IFS='/'; for"
   alias .foreachcolumn="setopt noglob; IFS=';'; for"
   alias .foreachfile="unsetopt noglob; setopt nullglob; IFS=' '$'\t'$'\n'; for"
   alias .do="do
   unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'"
   alias .done="done;unsetopt noglob; unsetopt nullglob; IFS=' '$'\t'$'\n'"

else
   shopt -s expand_aliases

   alias .for="set -f; for"
   alias .foreachline="set -f; IFS=$'\n'; for"
   alias .foreachword="set -f; IFS=' '$'\t'$'\n'; for"
   alias .foreachitem="set -f; IFS=','; for"
   alias .foreachpath="set -f; IFS=':'; for"
   alias .foreachpathcomponent="set -f; IFS='/'; for"
   alias .foreachcolumn="set -f; IFS=';'; for"
   alias .foreachfile="set +f; shopt -s nullglob; IFS=' '$'\t'$'\n'; for"
   alias .do="do
set +f; shopt -u nullglob; IFS=' '$'\t'$'\n'"
   alias .done="done;set +f; shopt -u nullglob; IFS=' '$'\t'$'\n'"
fi


alias .break="break"
alias .continue="continue"


shell_enable_extglob
shell_enable_pipefail

fi
:
